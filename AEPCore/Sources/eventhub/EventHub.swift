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

import Foundation
import AEPServices

public typealias EventListener = (Event) -> Void
public typealias EventResponseListener = (Event?) -> Void
public typealias SharedStateResolver = ([String: Any]?) -> Void
public typealias EventHandlerMapping = (event: Event, handler: (Event) -> (Bool))
public typealias EventPreprocessor = (Event) -> Event

/// Responsible for delivering events to listeners and maintaining registered extension's lifecycle.
final class EventHub {
    private let eventHubQueue = DispatchQueue(label: "com.adobe.eventhub.queue")
    private var registeredExtensions = ThreadSafeDictionary<String, ExtensionContainer>(identifier: "com.adobe.eventhub.registeredExtensions.queue")
    private let eventNumberMap = ThreadSafeDictionary<UUID, Int>(identifier: "com.adobe.eventhub.eventNumber.queue")
    private let responseEventListeners = ThreadSafeArray<EventListenerContainer>(identifier: "com.adobe.eventhub.response.queue")
    private var eventNumberCounter = AtomicCounter()
    private let eventQueue = OperationOrderer<Event>("EventHub")
    private var preprocessors = ThreadSafeArray<EventPreprocessor>(identifier: "com.adobe.eventhub.preprocessors.queue")

    #if DEBUG
    public internal(set) static var shared = EventHub()
    #else
    internal static let shared = EventHub()
    #endif


    // MARK: Internal API

    init() {
        // setup a fake extension container for `EventHub` so we can shared and retrieve state
        registerExtension(EventHubPlaceholderExtension.self, completion: {_ in })

        // Setup eventQueue handler for the main OperationOrderer
        eventQueue.setHandler { (event) -> Bool in
            
            let processedEvent = self.preprocessors.shallowCopy.reduce(event) { event,  preprocessor in
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
        }
    }

    /// Dispatches a new `Event` to the `EventHub`. This `Event` is sent to all listeners who have registered for the `EventType`and `EventSource`
    /// - Parameter event: An `Event` to be dispatched to listeners
    func dispatch(event: Event) {
        // Set an event number for the event
        self.eventNumberMap[event.id] = self.eventNumberCounter.incrementAndGet()
        self.eventQueue.add(event)
    }

    /// Registers a new `Extension` to the `EventHub`. This `Extension` must implement `Extension`
    /// - Parameters:
    ///   - type: The type of extension to register
    ///   - completion: Invoked when the extension has been registered or failed to register
    func registerExtension(_ type: Extension.Type, completion: @escaping (_ error: EventHubError?) -> Void) {
        eventHubQueue.async {
            guard !type.typeName.isEmpty else {
                // TODO: print error, extension name must not be empty
                completion(.invalidExtensionName)
                return
            }
            guard self.registeredExtensions[type.typeName] == nil else {
                // TODO: print error, cannot register an extension multiple times
                completion(.duplicateExtensionName)
                return
            }

            // Init the extension on a dedicated queue
            let extensionQueue = DispatchQueue(label: "com.adobe.eventhub.extension.\(type.typeName)")
            let extensionContainer = ExtensionContainer(type, extensionQueue, completion: completion)
            self.registeredExtensions[type.typeName] = extensionContainer
        }
    }

    /// Registers an `EventListener` which will be invoked when the response `Event` to `triggerEvent` is dispatched
    /// - Parameters:
    ///   - triggerEvent: An `Event` which will trigger a response `Event`
    ///   - timeout A timeout in seconds, if the response listener is not invoked within the timeout, then the `EventHub` invokes the response listener with a nil `Event`
    ///   - listener: Function or closure which will be invoked whenever the `EventHub` receives the response `Event` for `triggerEvent`
    func registerResponseListener(triggerEvent: Event, timeout: TimeInterval, listener: @escaping EventResponseListener) {
        var responseListenerContainer: EventListenerContainer? = nil // initialized here so we can use in timeout block
        responseListenerContainer = EventListenerContainer(listener: listener, triggerEventId: triggerEvent.id, timeout: DispatchWorkItem {
            listener(nil)
            _ = self.responseEventListeners.filterRemove { $0 == responseListenerContainer }
        })
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeout, execute: responseListenerContainer!.timeoutTask!)
        responseEventListeners.append(responseListenerContainer!)
    }


    /// Creates a new `SharedState` for the extension with provided data, versioned at `event` if not nil otherwise versioned at latest
    /// - Parameters:
    ///   - extensionName: Extension whose `SharedState` is to be updated
    ///   - data: Data for the `SharedState`
    ///   - event: If not nil, the `SharedState` will be versioned at `event`, if nil, it will be versioned at the latest
    func createSharedState(extensionName: String, data: [String: Any]?, event: Event?) {
        guard let (sharedState, version) = self.versionSharedState(extensionName: extensionName, event: event) else {
            return
        }

        sharedState.set(version: version, data: data)
        self.dispatch(event: self.createSharedStateEvent(extensionName: extensionName))
    }

    /// Sets the `SharedState` for the extension to pending at `event`'s version and returns a `SharedStateResolver` which is to be invoked with data for the `SharedState` once available.
    /// - Parameters:
    ///   - extensionName: Extension whose `SharedState` is to be updated
    ///   - event: Event which has the `SharedState` should be versioned for
    /// - Returns: A `SharedStateResolver` which is invoked to set pending the `SharedState` versioned at `event`
    func createPendingSharedState(extensionName: String, event: Event?) -> SharedStateResolver {
        var pendingVersion: Int? = nil

        if let (sharedState, version) = self.versionSharedState(extensionName: extensionName, event: event) {
            pendingVersion = version
            sharedState.addPending(version: version)
        }

        return { [weak self] data in
            self?.resolvePendingSharedState(extensionName: extensionName, version: pendingVersion, data: data)
        }
    }

    /// Retrieves the `SharedState` for a specific extension
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with this event's version, if nil will return the latest `SharedState`
    /// - Returns: The `SharedState` data and status for the extension with `extensionName`
    func getSharedState(extensionName: String, event: Event?) -> (value: [String: Any]?, status: SharedStateStatus)? {
        guard let sharedState = registeredExtensions.first(where: {$1.sharedStateName == extensionName})?.value.sharedState else {
            // print error - extension not registered
            return nil
        }

        var version = Int.max
        if let unwrappedEvent = event {
            version = self.eventNumberMap[unwrappedEvent.id] ?? Int.max
        }

        return sharedState.resolve(version: version)
    }

    /// Retrieves the `ExtensionContainer` wrapper for the given extension type
    /// - Parameter type: The `Extension` class to find the `ExtensionContainer` for
    /// - Returns: The `ExtensionContainer` instance if the `Extension` type was found, nil otherwise
    func getExtensionContainer(_ type: Extension.Type) -> ExtensionContainer? {
        return registeredExtensions[type.typeName]
    }
    
    /// Register a event preprocessor
    /// - Parameter preprocessor: The `EventPreprocessor`
    func registerPreprocessor(_ preprocessor: @escaping EventPreprocessor){
        preprocessors.append(preprocessor)
    }

    // MARK: Private

    private func versionSharedState(extensionName: String, event: Event?) -> (SharedState, Int)? {
        guard let extensionContainer = registeredExtensions.first(where: {$1.sharedStateName == extensionName})?.value else {
            // print error - extension not registered with event hub
            return nil
        }

        var version = -1
        // attempt to version at the event
        if let unwrappedEvent = event, let eventNumber = self.eventNumberMap[unwrappedEvent.id] {
            version = eventNumber
        } else {
            // default to next event number
            version = eventNumberCounter.incrementAndGet()
        }

        return (extensionContainer.sharedState!, version)
    }

    private func resolvePendingSharedState(extensionName: String, version: Int?, data: [String : Any]?) {
        guard let pendingVersion = version, let sharedState = registeredExtensions.first(where: {$1.sharedStateName == extensionName})?.value.sharedState else { return }

        sharedState.updatePending(version: pendingVersion, data: data)
        self.dispatch(event: self.createSharedStateEvent(extensionName: extensionName))
    }

    private func createSharedStateEvent(extensionName: String) -> Event {
        return Event(name: EventHubConstants.STATE_CHANGE, type: .hub, source: .sharedState,
                     data: [EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER: extensionName])
    }
    
    /// Shares a shared state for the `EventHub` with data containing all the registered extensions
    private func shareEventHubSharedState() {
        var extensionsInfo = [String: [String: Any]]()
        for (_, val) in registeredExtensions.shallowCopy
            where val.sharedStateName != EventHubConstants.NAME {

            if let exten = val.exten {
                extensionsInfo[exten.friendlyName] = [EventHubConstants.EventDataKeys.VERSION: exten.version]
                if let metadata = exten.metadata, !metadata.isEmpty {
                    extensionsInfo[exten.friendlyName] = [EventHubConstants.EventDataKeys.VERSION: exten.version,
                                                          EventHubConstants.EventDataKeys.METADATA: metadata]
                }
            }
        }

        // TODO: Determine which version of Core to use in the top level version field
        let data: [String: Any] = [EventHubConstants.EventDataKeys.VERSION: ConfigurationConstants.EXTENSION_VERSION,
                                   EventHubConstants.EventDataKeys.EXTENSIONS: extensionsInfo]
        createSharedState(extensionName: EventHubConstants.NAME, data: data, event: nil)
    }

}

private extension Extension {
    /// Returns the name of the class for the Extension
    static var typeName: String {
        return String(describing: self)
    }
}
