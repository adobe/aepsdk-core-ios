/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPServices
import Foundation

public typealias EventListener = (Event) -> Void
public typealias EventResponseListener = (Event?) -> Void
public typealias SharedStateResolver = ([String: Any]?) -> Void
public typealias EventHandlerMapping = (event: Event, handler: (Event) -> (Bool))
public typealias EventPreprocessor = (Event) -> Event

/// Responsible for delivering events to listeners and maintaining registered extension's lifecycle.
final class EventHub {
    private let LOG_TAG = "EventHub"
    private let eventHubQueue = DispatchQueue(label: "com.adobe.eventHub.queue")
    private var registeredExtensions = ThreadSafeDictionary<String, ExtensionContainer>(identifier: "com.adobe.eventHub.registeredExtensions.queue")
    private let eventNumberMap = ThreadSafeDictionary<UUID, Int>(identifier: "com.adobe.eventHub.eventNumber.queue")
    private let responseEventListeners = ThreadSafeArray<EventListenerContainer>(identifier: "com.adobe.eventHub.response.queue")
    private var eventNumberCounter = AtomicCounter()
    private let eventQueue = OperationOrderer<Event>("EventHub")
    private var preprocessors = ThreadSafeArray<EventPreprocessor>(identifier: "com.adobe.eventHub.preprocessors.queue")
    private var started = false // true if the `EventHub` is started, false otherwise. Should only be accessed from within the `eventHubQueue`
    private var eventHistory = EventHistory()
    private var wrapperType: WrapperType = .none
    #if DEBUG
        public internal(set) static var shared = EventHub()
    #else
        internal static let shared = EventHub()
    #endif

    // MARK: - Internal API

    /// Creates a new instance of `EventHub`
    init() {
        // setup a place-holder extension container for `EventHub` so we can shared and retrieve state
        registerExtension(EventHubPlaceholderExtension.self, completion: { _ in })

        // Setup eventQueue handler for the main OperationOrderer
        eventQueue.setHandler { [weak self] (event) -> Bool in
            guard let self = self else { return true }
            let processedEvent = self.preprocessors.shallowCopy.reduce(event, {$1($0)})
            // Hot path, avoid unnecessary string converstion of event
            if Log.logFilter >= .trace {
                Log.trace(label: self.LOG_TAG, "Processed Event #\(String(describing: self.eventNumberMap[event.id])) - \(processedEvent)")
            }
            // Handle response event listeners first
            if let responseID = processedEvent.responseID {
                // Make sure we remove the listeners before we call them to avoid race conditions
                let matchingResponseListeners = self.responseEventListeners.filterRemove { (eventListenerContainer: EventListenerContainer) -> Bool in
                    guard eventListenerContainer.triggerEventId == responseID else { return false }
                    eventListenerContainer.timeoutTask?.cancel()
                    return true
                }
                // Now that they are removed, we can call
                matchingResponseListeners.forEach({ eventListenerContainer in
                    eventListenerContainer.listener(processedEvent)
                })
            }

            // Send event to each ExtensionContainer
            self.registeredExtensions.shallowCopy.values.forEach {
                $0.eventOrderer.add(processedEvent)
            }

            // record the event in history if it has a mask
            if event.mask != nil {
                if let history = self.eventHistory {
                    history.recordEvent(processedEvent) { result in
                        if !result {
                            Log.debug(
                                label: self.LOG_TAG,
                                "Failed to insert Event(\(processedEvent.id)) into EventHistory database"
                            )
                        }
                    }
                } else {
                    Log.warning(label: self.LOG_TAG, "Unable to access EventHistory database to record an Event.")
                }
            }

            return true
        }
    }

    /// When this API is invoked the `EventHub` will begin processing `Event`s
    func start() {
        eventHubQueue.async { [weak self] in
            guard let self = self else { return }
            self.started = true
            self.eventQueue.start()
            self.shareEventHubSharedState() // share state of all registered extensions
            Log.debug(label: self.LOG_TAG, "Event Hub successfully started")
        }
    }

    /// Dispatches a new `Event` to the `EventHub`. This `Event` is sent to all listeners who have registered for the `EventType`and `EventSource`
    ///
    /// If the `event` has a `mask`, `EventHub` will attempt to record the `event` in `eventHistory` when processing.
    ///
    /// - Parameter event: An `Event` to be dispatched to listeners
    func dispatch(event: Event) {
        eventHubQueue.async { [weak self] in
            guard let self = self else { return }
            self.dispatchInternal(event: event)
        }
    }

    /// Registers a new `Extension` to the `EventHub`. This `Extension` must implement `Extension`
    /// - Parameters:
    ///   - type: The type of extension to register
    ///   - completion: Invoked when the extension has been registered or failed to register
    func registerExtension(_ type: Extension.Type, completion: @escaping (_ error: EventHubError?) -> Void) {
        eventHubQueue.async { [weak self] in
            guard let self = self else { return }
            guard !type.typeName.isEmpty else {
                Log.warning(label: self.LOG_TAG, "Extension name must not be empty.")
                completion(.invalidExtensionName)
                return
            }
            guard self.registeredExtensions[type.typeName] == nil else {
                Log.warning(label: "\(self.LOG_TAG):\(#function)", "Cannot register an extension multiple times.")
                completion(.duplicateExtensionName)
                return
            }

            // Init the extension on a dedicated queue
            let extensionTypeName = "com.adobe.eventhub.extension.\(type.typeName)"
            let extensionQueue = DispatchQueue(label: extensionTypeName)
            let extensionContainer = ExtensionContainer(self, extensionTypeName, type, extensionQueue, completion: completion)
            self.registeredExtensions[type.typeName] = extensionContainer
            Log.debug(label: self.LOG_TAG, "\(type.typeName) successfully registered.")
        }
    }

    /// Unregisters the extension from the `EventHub` if registered
    /// - Parameters:
    ///   - type: The extension to be unregistered
    ///   - completion: A closure invoked when the extension has been unregistered
    func unregisterExtension(_ type: Extension.Type, completion: @escaping (_ error: EventHubError?) -> Void) {
        eventHubQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.registeredExtensions[type.typeName] != nil else {
                Log.error(label: self.LOG_TAG, "Cannot unregister an extension that is not registered.")
                completion(.extensionNotRegistered)
                return
            }

            let extensionContainer = self.registeredExtensions.removeValue(forKey: type.typeName) // remove the corresponding extension container
            extensionContainer?.exten?.onUnregistered() // invoke the onUnregistered delegate function
            self.shareEventHubSharedState()
            completion(nil)
        }
    }

    /// Registers an `EventListener` which will be invoked when the response `Event` to `triggerEvent` is dispatched
    /// - Parameters:
    ///   - triggerEvent: An `Event` which will trigger a response `Event`
    ///   - timeout A timeout in seconds, if the response listener is not invoked within the timeout, then the `EventHub` invokes the response listener with a nil `Event`
    ///   - listener: An `EventResponseListener` which will be invoked whenever the `EventHub` receives the response `Event` for `triggerEvent`
    func registerResponseListener(triggerEvent: Event, timeout: TimeInterval, listener: @escaping EventResponseListener) {
        let triggerEventId = triggerEvent.id
        let timeoutTask = DispatchWorkItem { [weak self, triggerEventId] in
            guard let self = self else { return }
            // Make sure we remove the listeners before we call them to avoid race conditions
            _ = self.responseEventListeners.filterRemove { $0.triggerEventId == triggerEventId }
            listener(nil)
        }
        let responseListenerContainer = EventListenerContainer(listener: listener, triggerEventId: triggerEventId, timeout: timeoutTask)
        responseEventListeners.append(responseListenerContainer)
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeout, execute: timeoutTask)
    }

    /// Registers an `EventListener` which will be invoked whenever a event with matched type and source is dispatched
    /// - Parameters:
    ///   - type: A `String` indicating the event type the current listener is listening for
    ///   - source: A `String` indicating the event source the current listener is listening for
    ///   - listener: An `EventResponseListener` which will be invoked whenever the `EventHub` receives a event with matched type and source
    func registerEventListener(type: String, source: String, listener: @escaping EventListener) {
        eventHubQueue.async { [weak self] in
            guard let self = self else { return }
            // use the event hub placeholder extension to hold all the listeners registered from the public API
            guard let eventHubExtension = self.extensionContainerFor(type: EventHubPlaceholderExtension.self) else {
                Log.warning(label: self.LOG_TAG, "Error registering event listener")
                return
            }

            eventHubExtension.registerListener(type: type, source: source, listener: listener)
        }
    }

    /// Creates a new `SharedState` for the extension with provided data, versioned at `event`
    /// If `event` is nil, one of two behaviors will be observed:
    /// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
    /// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
    /// - Parameters:
    ///   - extensionName: Extension whose `SharedState` is to be updated
    ///   - data: Data for the `SharedState`
    ///   - event: `Event` for which the `SharedState` should be versioned
    func createSharedState(extensionName: String, data: [String: Any]?, event: Event?, sharedStateType: SharedStateType = .standard) {
        eventHubQueue.async { [weak self] in
            guard let self = self else { return }
            self.createSharedStateInternal(extensionName: extensionName, data: data, event: event, sharedStateType: sharedStateType)
        }
    }

    /// Sets the `SharedState` for the extension to pending at `event`'s version and returns a `SharedStateResolver` which is to be invoked with data for the `SharedState` once available.
    /// If `event` is nil, one of two behaviors will be observed:
    /// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
    /// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
    /// - Parameters:
    ///   - extensionName: Extension whose `SharedState` is to be updated
    ///   - event: `Event` for which the `SharedState` should be versioned
    ///   - sharedStateType: The type of shared state to be read from, if not provided defaults to `.standard`
    /// - Returns: A `SharedStateResolver` which is invoked to set pending the `SharedState` versioned at `event`
    func createPendingSharedState(extensionName: String, event: Event?, sharedStateType: SharedStateType = .standard) -> SharedStateResolver {
        return eventHubQueue.sync { [weak self] in
            guard let self = self else { return { _ in } }
            var pendingVersion: Int?

            if let (sharedState, version) = self.versionSharedState(extensionName: extensionName, event: event, sharedStateType: sharedStateType) {
                pendingVersion = version
                sharedState.addPending(version: version)
                Log.debug(label: self.LOG_TAG, "Pending \(sharedStateType.rawValue) shared state created for \(extensionName) with version \(version)")
            }

            return { [weak self] data in
                guard let self = self else { return }
                self.eventHubQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.resolvePendingSharedState(extensionName: extensionName, version: pendingVersion, data: data, sharedStateType: sharedStateType)
                }
            }
        }
    }

    /// Retrieves the `SharedState` for a specific extension
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with this event's version or latest if not yet versioned. If event is nil will return the latest `SharedState`
    ///   - barrier: If true, the `EventHub` will only return `.set` if `extensionName` has moved past `event`
    ///   - resolution: The `SharedStateResolution` to determine how to resolve the shared state
    ///   - sharedStateType: The type of shared state to be read from, if not provided defaults to `.standard`
    /// - Returns: The `SharedState` data and status for the extension with `extensionName`
    func getSharedState(extensionName: String, event: Event?, barrier: Bool = true, resolution: SharedStateResolution = .any, sharedStateType: SharedStateType = .standard) -> SharedStateResult? {
        return eventHubQueue.sync { [weak self] in
            guard let self = self else { return nil }
            guard let container = self.extensionContainerFor(extensionName: extensionName), let sharedState = container.sharedState(for: sharedStateType) else {
                Log.warning(label: self.LOG_TAG, "Unable to retrieve \(sharedStateType.rawValue) shared state for \(extensionName). No such extension is registered.")
                return nil
            }

            var version = Int.max // default to version max if event nil
            if let event = event {
                // default to latest version if event is non-nil but not yet versioned
                version = self.eventNumberMap[event.id] ?? Int.max
            }

            let result: (value: [String: Any]?, status: SharedStateStatus)
            switch resolution {
            case .lastSet:
                result = sharedState.resolveLastSet(version: version)
            case .any:
                result = sharedState.resolve(version: version)
            }

            let stateProviderLastVersion = self.eventNumberFor(event: container.lastProcessedEvent)
            // shared state is still considered pending if barrier is used and the state provider has not processed past the previous event
            let hasProcessedEvent = event == nil ? true : stateProviderLastVersion > version - 1
            if barrier && !hasProcessedEvent && result.status == .set {
                return SharedStateResult(status: .pending, value: result.value)
            }

            return SharedStateResult(status: result.status, value: result.value)
        }
    }

    /// Retrieves the `ExtensionContainer` wrapper for the given extension type. This is exposed primarily for testing purposes.
    /// - Parameter type: The `Extension` class to find the `ExtensionContainer` for
    /// - Returns: The `ExtensionContainer` instance if the `Extension` type was found, nil otherwise
    func getExtensionContainer(_ type: Extension.Type) -> ExtensionContainer? {
        return eventHubQueue.sync { [weak self] in
            guard let self = self else { return nil }
            return self.extensionContainerFor(type: type)
        }
    }

    /// Register a event preprocessor
    /// - Parameter preprocessor: The `EventPreprocessor`
    func registerPreprocessor(_ preprocessor: @escaping EventPreprocessor) {
        preprocessors.append(preprocessor)
    }

    /// Shares a shared state for the `EventHub` with data containing all the registered extensions
    func shareEventHubSharedState() {
        eventHubQueue.async {
            guard self.started else { return } // only publish shared state if `EventHub` is started
            var extensionsInfo = [String: [String: Any]]()
            for (_, val) in self.registeredExtensions.shallowCopy
                where val.sharedStateName != EventHubConstants.NAME {
                if let exten = val.exten {
                    let version = type(of: exten).extensionVersion
                    extensionsInfo[exten.name] = [EventHubConstants.EventDataKeys.VERSION: version,
                                                  EventHubConstants.EventDataKeys.FRIENDLY_NAME: exten.friendlyName]
                    if let metadata = exten.metadata, !metadata.isEmpty {
                        extensionsInfo[exten.name] = [EventHubConstants.EventDataKeys.VERSION: version,
                                                      EventHubConstants.EventDataKeys.METADATA: metadata,
                                                      EventHubConstants.EventDataKeys.FRIENDLY_NAME: exten.friendlyName]
                    }
                }
            }

            let wrapperInfo: [String: String] = [
                EventHubConstants.EventDataKeys.TYPE: self.wrapperType.rawValue,
                EventHubConstants.EventDataKeys.FRIENDLY_NAME: self.wrapperType.friendlyName
            ]
            let data: [String: Any] = [
                EventHubConstants.EventDataKeys.VERSION: EventHubConstants.VERSION_NUMBER,
                EventHubConstants.EventDataKeys.WRAPPER: wrapperInfo,
                EventHubConstants.EventDataKeys.EXTENSIONS: extensionsInfo]

            // Update latest shared state with all registered extensions
            self.createSharedStateInternal(extensionName: EventHubConstants.NAME, data: data, event: nil, sharedStateType: .standard)
        }
    }

    /// Retrieves a count of historical events matching the provided requests.
    ///
    /// - Parameters:
    ///   - requests: an array of `EventHistoryRequest`s used to generate the hash and timeframe for the event lookup
    ///   - enforceOrder: if `true`, consecutive lookups will use the oldest timestamp from the previous event as their
    ///                   from date
    ///   - handler: contains an `EventHistoryResult` for each provided request
    func getHistoricalEvents(_ requests: [EventHistoryRequest], enforceOrder: Bool, handler: @escaping ([EventHistoryResult]) -> Void) {
        eventHistory?.getEvents(requests, enforceOrder: enforceOrder, handler: handler)
    }

    /// Sets wrapper type if `Eventhub` has not started
    /// - Parameter type: A `WrapperType` denoting the type of wrapper
    func setWrapperType(_ type: WrapperType) {
        eventHubQueue.sync { [weak self] in
            guard let self = self else { return }
            guard !self.started else {
                Log.warning(label: self.LOG_TAG, "Wrapper type can not be set after EventHub starts processing events")
                return
            }
            self.wrapperType = type
        }
    }

    /// Returns wrapper type, if not previously set returns `WrapperType.none`    
    /// - Returns: A `WrapperType` denoting the type of wrapper
    func getWrapperType() -> WrapperType {
        return eventHubQueue.sync { [weak self] in
            guard let self = self else { return .none }
            return self.wrapperType
        }
    }

    /// shut down the event hub, wait for the event queue to stop and unregister all the extensions
    func shutdown() {
        eventQueue.waitToStop()
        eventHubQueue.sync { [weak self] in
            guard let self = self else { return }
            let extensions = self.registeredExtensions.shallowCopy.values
            for ext in extensions {
                ext.unregisterExtension()
                ext.shutdown()
            }
        }
        eventHubQueue.sync { [weak self] in
            guard let self = self else { return }
            // just wait
            self.registeredExtensions = ThreadSafeDictionary<String, ExtensionContainer>(identifier: "com.adobe.eventHub.registeredExtensions.queue")
        }
    }

    // MARK: - Private

    /// Internal method to dispatch a new `Event` to the `EventHub`.
    /// - Parameter event: An `Event` to be dispatched to listeners
    private func dispatchInternal(event: Event) {
        // Set an event number for the event
        self.eventNumberMap[event.id] = self.eventNumberCounter.incrementAndGet()
        self.eventQueue.add(event)
        // Hot path, avoid unnecessary string converstion of event
        if Log.logFilter >= .trace {
            Log.trace(label: self.LOG_TAG,
                      "Dispatching Event #\(String(describing: self.eventNumberMap[event.id])) - \(event)")
        }
    }

    /// Internal method to create a new `SharedState` for the extension with provided data, versioned at `event`
    /// If `event` is nil, one of two behaviors will be observed:
    /// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
    /// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
    /// - Parameters:
    ///   - extensionName: Extension whose `SharedState` is to be updated
    ///   - data: Data for the `SharedState`
    ///   - event: `Event` for which the `SharedState` should be versioned
    private func createSharedStateInternal(extensionName: String, data: [String: Any]?, event: Event?, sharedStateType: SharedStateType = .standard) {
        guard let (sharedState, version) = versionSharedState(extensionName: extensionName, event: event, sharedStateType: sharedStateType) else {
            Log.warning(label: LOG_TAG, "Error creating \(sharedStateType.rawValue) shared state for \(extensionName)")
            return
        }

        sharedState.set(version: version, data: data)
        Log.debug(label: LOG_TAG, "\(sharedStateType.rawValue.capitalized) shared state created for \(extensionName) with version \(version) and data: \n\(PrettyDictionary.prettify(data))")
        dispatchInternal(event: createSharedStateEvent(extensionName: extensionName, sharedStatetype: sharedStateType))
    }

    /// Gets the appropriate `SharedState` for the provided `extensionName` and `event`
    /// If the provided `event` is `nil`, this method will retrieve `SharedState` for version 0.
    /// - Parameters:
    ///   - extensionName: A `String` containing the name of the extension
    ///   - event: An `Event?` which may contain a specific event from which the correct `SharedState` can be retrieved
    ///   - sharedStateType: The type of shared state to be read from, if not provided defaults to `.standard`
    /// - Returns: A `(SharedState, Int)?` containing the state for the provided extension and its version number
    private func versionSharedState(extensionName: String, event: Event?, sharedStateType: SharedStateType = .standard) -> (SharedState, Int)? {
        guard let extensionContainer = extensionContainerFor(extensionName: extensionName) else {
            Log.error(label: LOG_TAG, "Extension \(extensionName) not registered with EventHub")
            return nil
        }

        guard let sharedState = extensionContainer.sharedState(for: sharedStateType) else { return nil }

        var version = 0 // default to version 0
        // attempt to version at the event
        if let event = event, let eventNumber = eventNumberMap[event.id] {
            version = eventNumber
        } else if !sharedState.isEmpty {
            // if event is nil and shared state is not empty version at the latest
            version = eventNumberCounter.incrementAndGet()
        }

        return (sharedState, version)
    }

    /// Updates a pending `SharedState` and dispatches it to the `EventHub`
    /// Not providing a `version` or providing a `version` for which there is no pending state will result in a no-op.
    /// - Parameters:
    ///   - extensionName: A `String` containing the name of the extension
    ///   - version: An `Int?` containing the version of the state being updated
    ///   - data: A `[String: Any]?` containing data to add to the pending state prior to it being dispatched
    ///   - sharedStateType: The type of shared state to be read from, if not provided defaults to `.standard`
    private func resolvePendingSharedState(extensionName: String, version: Int?, data: [String: Any]?, sharedStateType: SharedStateType = .standard) {
        guard let pendingVersion = version, let container = extensionContainerFor(extensionName: extensionName) else { return }
        guard let sharedState = container.sharedState(for: sharedStateType) else { return }
        sharedState.updatePending(version: pendingVersion, data: data)
        Log.debug(label: self.LOG_TAG, "Pending \(sharedStateType.rawValue) shared state resolved for \(extensionName) with version \(String(describing: pendingVersion)) and data: \n\(PrettyDictionary.prettify(data))")
        dispatchInternal(event: createSharedStateEvent(extensionName: container.sharedStateName, sharedStatetype: sharedStateType))
    }

    /// Creates a template `Event` for `SharedState` of the provided `extensionName`
    /// - Parameter extensionName: A `String` containing the name of the extension
    /// - Returns: An empty `SharedState` `Event` for the provided `extensionName`
    private func createSharedStateEvent(extensionName: String, sharedStatetype: SharedStateType) -> Event {
        let eventName = sharedStatetype == .standard ? EventHubConstants.STATE_CHANGE : EventHubConstants.XDM_STATE_CHANGE
        return Event(name: eventName, type: EventType.hub, source: EventSource.sharedState,
                     data: [EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER: extensionName])
    }

    /// Internal method to retrieve the `ExtensionContainer` wrapper for the given extension type.
    /// - Parameter type: The `Extension` class to find the `ExtensionContainer` for
    /// - Returns: The `ExtensionContainer` instance if the `Extension` type was found, nil otherwise
    private func extensionContainerFor(type: Extension.Type) -> ExtensionContainer? {
        return registeredExtensions[type.typeName]
    }

    /// Internal method to retrieve the `ExtensionContainer` wrapper for the given extension name.
    /// - Parameter extensionName: The `Extension` name
    /// - Returns: The `ExtensionContainer` instance whose backing extension has been initialized and its name matches the given `extensionName`, nil otherwise
    private func extensionContainerFor(extensionName: String) -> ExtensionContainer? {
        return registeredExtensions.first(where: { $1.sharedStateName.caseInsensitiveCompare(extensionName) == .orderedSame })?.value
    }

    /// Returns the event number for the event
    /// - Parameter event: The `Event` to be looked up
    /// - Returns: The `Event` number if found, otherwise 0
    private func eventNumberFor(event: Event?) -> Int {
        if let event = event {
            return eventNumberMap[event.id] ?? 0
        }

        return 0
    }
}

private extension Extension {
    /// Returns the name of the class for the Extension
    static var typeName: String {
        return String(reflecting: self)
    }
}
