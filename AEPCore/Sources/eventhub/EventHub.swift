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
        eventQueue.setHandler { (event) -> Bool in

            let processedEvent = self.preprocessors.shallowCopy.reduce(event) { event, preprocessor in
                preprocessor(event)
            }

            // Handle response event listeners first
            if let responseID = processedEvent.responseID {
                _ = self.responseEventListeners.filterRemove { (eventListenerContainer: EventListenerContainer) -> Bool in
                    guard eventListenerContainer.triggerEventId == responseID else { return false }
                    eventListenerContainer.timeoutTask?.cancel()
                    eventListenerContainer.listener(processedEvent)
                    return true
                }
            }

            // Send event to each ExtensionContainer
            self.registeredExtensions.shallowCopy.values.forEach {
                $0.eventOrderer.add(processedEvent)
            }

            return true
        }
    }

    /// When this API is invoked the `EventHub` will begin processing `Event`s
    func start() {
        eventHubQueue.async {
            self.eventQueue.start()
            self.shareEventHubSharedState() // share state of all registered extensions
            Log.debug(label: self.LOG_TAG, "Event Hub successfully started")
        }
    }

    /// Dispatches a new `Event` to the `EventHub`. This `Event` is sent to all listeners who have registered for the `EventType`and `EventSource`
    /// - Parameter event: An `Event` to be dispatched to listeners
    func dispatch(event: Event) {
        eventHubQueue.async {
            // Set an event number for the event
            self.eventNumberMap[event.id] = self.eventNumberCounter.incrementAndGet()
            self.eventQueue.add(event)
            Log.trace(label: self.LOG_TAG, "Dispatching Event #\(String(describing: self.eventNumberMap[event.id] ?? 0)) - \(event)")
        }
    }

    /// Registers a new `Extension` to the `EventHub`. This `Extension` must implement `Extension`
    /// - Parameters:
    ///   - type: The type of extension to register
    ///   - completion: Invoked when the extension has been registered or failed to register
    func registerExtension(_ type: Extension.Type, completion: @escaping (_ error: EventHubError?) -> Void) {
        eventHubQueue.async {
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
            let extensionQueue = DispatchQueue(label: "com.adobe.eventhub.extension.\(type.typeName)")
            let extensionContainer = ExtensionContainer(type, extensionQueue, completion: completion)
            self.registeredExtensions[type.typeName] = extensionContainer
            Log.debug(label: self.LOG_TAG, "\(type.typeName) successfully registered.")
        }
    }

    /// Unregisters the extension from the `EventHub` if registered
    /// - Parameters:
    ///   - type: The extension to be unregistered
    ///   - completion: A closure invoked when the extension has been unregistered
    func unregisterExtension(_ type: Extension.Type, completion: @escaping (_ error: EventHubError?) -> Void) {
        eventHubQueue.async {
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
        var responseListenerContainer: EventListenerContainer? // initialized here so we can use in timeout block
        responseListenerContainer = EventListenerContainer(listener: listener, triggerEventId: triggerEvent.id, timeout: DispatchWorkItem {
            listener(nil)
            _ = self.responseEventListeners.filterRemove { $0 == responseListenerContainer }
        })
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeout, execute: responseListenerContainer!.timeoutTask!)
        responseEventListeners.append(responseListenerContainer!)
    }

    /// Registers an `EventListener` which will be invoked whenever a event with matched type and source is dispatched
    /// - Parameters:
    ///   - type: A `String` indicating the event type the current listener is listening for
    ///   - source: A `String` indicating the event source the current listener is listening for
    ///   - listener: An `EventResponseListener` which will be invoked whenever the `EventHub` receives a event with matched type and source
    func registerEventListener(type: String, source: String, listener: @escaping EventListener) {
        eventHubQueue.async {
            // use the event hub placeholder extension to hold all the listeners registered from the public API
            guard let eventHubExtension = self.registeredExtensions.first(where: { $1.sharedStateName.caseInsensitiveCompare(EventHubConstants.NAME) == .orderedSame })?.value else {
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
        eventHubQueue.async {
            guard let (sharedState, version) = self.versionSharedState(extensionName: extensionName, event: event, sharedStateType: sharedStateType) else {
                Log.warning(label: self.LOG_TAG, "Error creating \(sharedStateType.rawValue) shared state for \(extensionName)")
                return
            }

            sharedState.set(version: version, data: data)
            self.dispatch(event: self.createSharedStateEvent(extensionName: extensionName))
            Log.debug(label: self.LOG_TAG, "\(sharedStateType.rawValue.capitalized) shared state created for \(extensionName) with version \(version) and data: \n\(PrettyDictionary.prettify(data))")
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
        return eventHubQueue.sync {
            var pendingVersion: Int?

            if let (sharedState, version) = versionSharedState(extensionName: extensionName, event: event, sharedStateType: sharedStateType) {
                pendingVersion = version
                sharedState.addPending(version: version)
                Log.debug(label: LOG_TAG, "Pending \(sharedStateType.rawValue) shared state created for \(extensionName) with version \(version)")
            }

            return { [weak self] data in
                self?.resolvePendingSharedState(extensionName: extensionName, version: pendingVersion, data: data, sharedStateType: sharedStateType)
                Log.debug(label: self?.LOG_TAG ?? "EventHub", "Pending \(sharedStateType.rawValue) shared state resolved for \(extensionName) with version \(String(describing: pendingVersion)) and data: \n\(PrettyDictionary.prettify(data))")
            }
        }
    }

    /// Retrieves the `SharedState` for a specific extension
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with this event's version. If nil will return the earliest `SharedState`
    ///   - barrier: If true, the `EventHub` will only return `.set` if `extensionName` has moved past `event`
    ///   - sharedStateType: The type of shared state to be read from, if not provided defaults to `.standard`
    /// - Returns: The `SharedState` data and status for the extension with `extensionName`
    func getSharedState(extensionName: String, event: Event?, barrier: Bool = true, sharedStateType: SharedStateType = .standard) -> SharedStateResult? {
        return eventHubQueue.sync {
            guard let container = registeredExtensions.first(where: { $1.sharedStateName.caseInsensitiveCompare(extensionName) == .orderedSame })?.value, let sharedState = container.sharedState(for: sharedStateType) else {
                Log.warning(label: LOG_TAG, "Unable to retrieve \(sharedStateType.rawValue) shared state for \(extensionName). No such extension is registered.")
                return nil
            }

            var version = 0 // default to version 0 if event nil
            if let event = event {
                version = eventNumberMap[event.id] ?? 0
            }

            let result = sharedState.resolve(version: version)

            let stateProviderLastVersion = eventNumberFor(event: container.lastProcessedEvent)
            // shared state is still considered pending if barrier is used and the state provider has not processed past the previous event
            if barrier && stateProviderLastVersion < version - 1 && result.status == .set {
                return SharedStateResult(status: .pending, value: result.value)
            }

            return SharedStateResult(status: result.status, value: result.value)
        }
    }

    /// Retrieves the `ExtensionContainer` wrapper for the given extension type
    /// - Parameter type: The `Extension` class to find the `ExtensionContainer` for
    /// - Returns: The `ExtensionContainer` instance if the `Extension` type was found, nil otherwise
    func getExtensionContainer(_ type: Extension.Type) -> ExtensionContainer? {
        return registeredExtensions[type.typeName]
    }

    /// Register a event preprocessor
    /// - Parameter preprocessor: The `EventPreprocessor`
    func registerPreprocessor(_ preprocessor: @escaping EventPreprocessor) {
        preprocessors.append(preprocessor)
    }

    /// Shares a shared state for the `EventHub` with data containing all the registered extensions
    func shareEventHubSharedState() {
        var extensionsInfo = [String: [String: Any]]()
        for (_, val) in registeredExtensions.shallowCopy
            where val.sharedStateName != EventHubConstants.NAME {
            if let exten = val.exten {
                let version = type(of: exten).extensionVersion
                extensionsInfo[exten.friendlyName] = [EventHubConstants.EventDataKeys.VERSION: version]
                if let metadata = exten.metadata, !metadata.isEmpty {
                    extensionsInfo[exten.friendlyName] = [EventHubConstants.EventDataKeys.VERSION: version,
                                                          EventHubConstants.EventDataKeys.METADATA: metadata]
                }
            }
        }

        let data: [String: Any] = [EventHubConstants.EventDataKeys.VERSION: EventHubConstants.VERSION_NUMBER,
                                   EventHubConstants.EventDataKeys.EXTENSIONS: extensionsInfo]

        guard let sharedState = registeredExtensions.first(where: { $1.sharedStateName.caseInsensitiveCompare(EventHubConstants.NAME) == .orderedSame })?.value.sharedState else {
            Log.warning(label: LOG_TAG, "Extension not registered with EventHub")
            return
        }

        let version = sharedState.resolve(version: 0).value == nil ? 0 : eventNumberCounter.incrementAndGet()
        sharedState.set(version: version, data: data)
        dispatch(event: createSharedStateEvent(extensionName: EventHubConstants.NAME))
        Log.debug(label: LOG_TAG, "Shared state created for \(EventHubConstants.NAME) with version \(version) and data: \n\(PrettyDictionary.prettify(data))")
    }

    // MARK: - Private

    /// Gets the appropriate `SharedState` for the provided `extensionName` and `event`
    /// If the provided `event` is `nil`, this method will retrieve `SharedState` for version 0.
    /// - Parameters:
    ///   - extensionName: A `String` containing the name of the extension
    ///   - event: An `Event?` which may contain a specific event from which the correct `SharedState` can be retrieved
    ///   - sharedStateType: The type of shared state to be read from, if not provided defaults to `.standard`
    /// - Returns: A `(SharedState, Int)?` containing the state for the provided extension and its version number
    private func versionSharedState(extensionName: String, event: Event?, sharedStateType: SharedStateType = .standard) -> (SharedState, Int)? {
        guard let extensionContainer = registeredExtensions.first(where: { $1.sharedStateName.caseInsensitiveCompare(extensionName) == .orderedSame })?.value else {
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
        guard let pendingVersion = version, let container = registeredExtensions.first(where: { $1.sharedStateName.caseInsensitiveCompare(extensionName) == .orderedSame })?.value else { return }
        guard let sharedState = container.sharedState(for: sharedStateType) else { return }
        sharedState.updatePending(version: pendingVersion, data: data)
        dispatch(event: createSharedStateEvent(extensionName: container.sharedStateName))
    }

    /// Creates a template `Event` for `SharedState` of the provided `extensionName`
    /// - Parameter extensionName: A `String` containing the name of the extension
    /// - Returns: An empty `SharedState` `Event` for the provided `extensionName`
    private func createSharedStateEvent(extensionName: String) -> Event {
        return Event(name: EventHubConstants.STATE_CHANGE, type: EventType.hub, source: EventSource.sharedState,
                     data: [EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER: extensionName])
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
