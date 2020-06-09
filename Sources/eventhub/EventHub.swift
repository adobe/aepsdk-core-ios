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

public typealias EventListener = (Event) -> Void
public typealias EventResponseListener = (Event?) -> Void
public typealias SharedStateResolver = ([String: Any]?) -> Void
public typealias EventHandlerMapping = (event: Event, handler: (Event) -> (Bool))

/// Responsible for delivering events to listeners and maintaining registered extension's lifecycle.
final public class EventHub {
    private let eventHubQueue = DispatchQueue(label: "com.adobe.eventhub.queue", attributes: .concurrent) // Allows multi-threaded access to event hub.  Reads are concurrent, Add/Updates act as barriers.
    private var listenerContainers = [EventListenerContainer]()
    private var responseListenerContainers = [EventListenerContainer]()
    private var registeredExtensions = ThreadSafeDictionary<String, ExtensionContainer>(identifier: "com.adobe.eventhub.registeredExtensions.queue")
    private let eventNumberMap = ThreadSafeDictionary<UUID, Int>(identifier: "com.adobe.eventhub.eventNumber.queue")
    private var eventNumberCounter = AtomicCounter()
    private let eventQueue = OperationOrderer<Event>("EventHub")

    #if DEBUG
    public internal(set) static var shared = EventHub()
    #else
    internal static let shared = EventHub()
    #endif


    // MARK: Public API

    init() {
        eventQueue.setHandler(notifyListeners)
    }

    /// When this API is invoked the `EventHub` will begin processing `Event`s
    public func start() {
        eventQueue.start()
    }

    /// Registers an `EventListener` for the specified `EventType` and `EventSource`
    /// - Parameters:
    ///   - parentExtension: The extension who is managing this `EventListener`
    ///   - type: `EventType` to listen for
    ///   - source: `EventSource` to listen for
    ///   - listener: Function or closure which will be invoked whenever the `EventHub` receives an `Event` matching `type` and `source`
    public func registerListener<T: Extension>(parentExtension: T.Type, type: EventType, source: EventSource, listener: @escaping EventListener) {
        eventHubQueue.async(flags: .barrier) {
            guard self.registeredExtensions[parentExtension.typeName] != nil else { return } // extension must be registered to register a listener
            let listenerContainer = EventListenerContainer(listener: listener, parentExtensionName: parentExtension.typeName,
                                                           type: type, source: source, triggerEventId: nil, timeoutTask: nil)
            self.listenerContainers.append(listenerContainer)
        }
    }

    /// Registers an `EventListener` which will be invoked when the response `Event` to `triggerEvent` is dispatched
    /// - Parameters:
    ///   - parentExtension: The extension who is managing this `EventListener`
    ///   - triggerEvent: An `Event` which will trigger a response `Event`
    ///   - listener: Function or closure which will be invoked whenever the `EventHub` receives the response `Event` for `triggerEvent`
    public func registerResponseListener<T: Extension>(parentExtension: T.Type, triggerEvent: Event, listener: @escaping EventResponseListener) {
        eventHubQueue.async(flags: .barrier) {
            guard self.registeredExtensions[parentExtension.typeName] != nil else { return } // extension must be registered to register a listener
            
            let timeoutTask = DispatchWorkItem {
                listener(nil)
                self.responseListenerContainers.removeAll(where: {$0.triggerEventId == triggerEvent.id})
            }
            
            self.eventHubQueue.asyncAfter(deadline: DispatchTime.now() + EventHubConstants.RESPONSE_LISTENER_TIMEOUT, execute: timeoutTask)
            let listenerContainer = EventListenerContainer(listener: listener, parentExtensionName: parentExtension.typeName,
                                                           type: nil, source: nil, triggerEventId: triggerEvent.id, timeoutTask: timeoutTask)
            
            self.responseListenerContainers.append(listenerContainer)
        }
    }

    /// Dispatches a new `Event` to the `EventHub`. This `Event` is sent to all listeners who have registered for the `EventType`and `EventSource`
    /// - Parameter event: An `Event` to be dispatched to listeners
    public func dispatch(event: Event) {
        eventHubQueue.async(flags: .barrier) {
            // Set an event number for the event
            self.eventNumberMap[event.id] = self.eventNumberCounter.incrementAndGet()
            self.eventQueue.add(event)
        }
    }

    /// Registers a new `Extension` to the `EventHub`. This `Extension` must implement `Extension`
    /// - Parameters:
    ///   - type: The type of extension to register
    ///   - completion: Invoked when the extension has been registered or failed to register
    public func registerExtension(_ type: Extension.Type, completion: @escaping (_ error: EventHubError?) -> Void) {
        initializeExtension(type) { (extensionContainer) in
            self.finishRegistration(extensionContainer, completion: completion)
        }
    }

    /// Creates a new `SharedState` for the extension with provided data, versioned at `event` if not nil otherwise versioned at latest
    /// - Parameters:
    ///   - extensionName: Extension whose `SharedState` is to be updated
    ///   - data: Data for the `SharedState`
    ///   - event: If not nil, the `SharedState` will be versioned at `event`, if nil, it will be versioned at the latest
    public func createSharedState(extensionName: String, data: [String: Any]?, event: Event?) {
        eventHubQueue.async(flags: .barrier) {
            guard let (sharedState, version) = self.versionSharedState(extensionName: extensionName, event: event) else {
                return
            }

            sharedState.set(version: version, data: data)
            self.dispatch(event: self.createSharedStateEvent(extensionName: extensionName))
        }
    }

    /// Sets the `SharedState` for the extension to pending at `event`'s version and returns a `SharedStateResolver` which is to be invoked with data for the `SharedState` once available.
    /// - Parameters:
    ///   - extensionName: Extension whose `SharedState` is to be updated
    ///   - event: Event which has the `SharedState` should be versioned for
    /// - Returns: A `SharedStateResolver` which is invoked to set pending the `SharedState` versioned at `event`
    public func createPendingSharedState(extensionName: String, event: Event?) -> SharedStateResolver {
        var pendingVersion: Int? = nil
        eventHubQueue.async(flags: .barrier) {
            guard let (sharedState, version) = self.versionSharedState(extensionName: extensionName, event: event) else {
                return
            }
            
            pendingVersion = version
            sharedState.addPending(version: version)
        }

        return { [weak self] data in
            self?.eventHubQueue.async(flags: .barrier) {
                self?.resolvePendingSharedState(extensionName: extensionName, version: pendingVersion, data: data)
            }
        }
    }

    /// Retrieves the `SharedState` for a specific extension
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with this event's version, if nil will return the latest `SharedState`
    /// - Returns: The `SharedState` data and status for the extension with `extensionName`
    public func getSharedState(extensionName: String, event: Event?) -> (value: [String: Any]?, status: SharedStateStatus)? {
        eventHubQueue.sync {
            guard let sharedState = registeredExtensions.first(where: {$1.exten.name == extensionName})?.value.sharedState else {
                // print error - extension not registered
                return nil
            }

            var version = Int.max
            if let unwrappedEvent = event {
                version = self.eventNumberMap[unwrappedEvent.id] ?? Int.max
            }

            return sharedState.resolve(version: version)
        }
    }

    // MARK: Private

    private func initializeExtension(_ type: Extension.Type, completion: @escaping (_ extension: ExtensionContainer) -> Void) {
        // Init the extension on a dedicated queue
        let extensionQueue = DispatchQueue(label: "com.adobe.eventhub.extension.\(type.self)")

        extensionQueue.async {
            let newExtension = type.init()
            let extensionContainer = ExtensionContainer(exten: newExtension,
                                                        sharedState: SharedState(newExtension.name),
                                                        extensionQueue: extensionQueue)
            completion(extensionContainer)
        }
    }

    private func finishRegistration(_ extensionContainer: ExtensionContainer, completion: @escaping (_ error: EventHubError?) -> Void) {
        let typeName = type(of: extensionContainer.exten).typeName
        guard !typeName.isEmpty else {
            // TODO: print error, extension name must not be empty
            completion(.invalidExtensionName)
            return
        }

        guard self.registeredExtensions[typeName] == nil else {
            // TODO: print error, can't register multiple extensions with the same name
            completion(.duplicateExtensionName)
            return
        }

        self.registeredExtensions[typeName] = extensionContainer
        extensionContainer.exten.onRegistered()
        completion(nil)
    }

    private func notifyListeners(event: Event) -> Bool {
        eventHubQueue.async(flags: .barrier) {
            // Notify non-response listeners
            for listenerContainer in self.listenerContainers
                where listenerContainer.shouldNotify(event: event) {
                    self.notifyListener(event: event, listenerContainer: listenerContainer)
            }

            // if we have a responseID, process the response listeners.
            if event.responseID != nil {
                // Notify response listeners
                for (i, listenerContainer) in self.responseListenerContainers.enumerated().reversed()
                    where listenerContainer.shouldNotify(event: event) {
                        listenerContainer.timeoutTask?.cancel()
                        self.notifyListener(event: event, listenerContainer: listenerContainer)
                        self.responseListenerContainers.remove(at: i)
                }
            }
        }

        return true
    }

    private func notifyListener(event: Event, listenerContainer: EventListenerContainer) {
        guard let extensionQueue = self.registeredExtensions[listenerContainer.parentExtensionName]?.extensionQueue else { return }
        extensionQueue.async {
            listenerContainer.listener(event)
        }
    }

    private func versionSharedState(extensionName: String, event: Event?) -> (SharedState, Int)? {
        guard let extensionContainer = registeredExtensions.first(where: {$1.exten.name == extensionName})?.value else {
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

        return (extensionContainer.sharedState, version)
    }

    private func resolvePendingSharedState(extensionName: String, version: Int?, data: [String : Any]?) {
        guard let pendingVersion = version, let sharedState = registeredExtensions.first(where: {$1.exten.name == extensionName})?.value.sharedState else { return }

        sharedState.updatePending(version: pendingVersion, data: data)
        self.dispatch(event: self.createSharedStateEvent(extensionName: extensionName))
    }

    private func createSharedStateEvent(extensionName: String) -> Event {
        return Event(name: EventHubConstants.STATE_CHANGE, type: .hub, source: .sharedState,
                     data: [EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER: extensionName])
    }

}

private extension Extension {
    /// Returns the name of the class for the Extension
    static var typeName: String {
        return String(describing: self)
    }
}
