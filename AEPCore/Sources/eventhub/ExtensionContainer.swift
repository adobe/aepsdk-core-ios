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

// MARK: - ExtensionContainer

/// Contains an `Extension` and additional information related to the extension
class ExtensionContainer {
    private static let LOG_TAG = "ExtensionContainer"

    /// A weak reference to the EventHub instance responsible for processing events sent to/from this ExtensionContainer.
    private weak var eventHub: EventHub?

    /// The extension service provider instance
    private let serviceProvider: ExtensionServiceProvider

    /// The extension held in this container
    private var _exten: Extension?
    var exten: Extension? {
        get { containerQueue.sync { self._exten } }
        set { containerQueue.async { self._exten = newValue } }
    }

    /// The `SharedState` associated with the extension
    private var sharedState: SharedState?

    /// The XDM `SharedState` associated with the extension
    private var xdmSharedState: SharedState?

    /// The shared state name associated with the extension
    private var _sharedStateName = "invalidSharedStateName"    
    var sharedStateName: String {
        get { containerQueue.sync { self._sharedStateName } }
        set { containerQueue.async { self._sharedStateName = newValue } }
    }

    /// The extension's dispatch queue
    private let extensionQueue: DispatchQueue

    /// The extension container's queue to allow multi threaded access to its members.
    private let containerQueue: DispatchQueue

    /// Operation Orderer queue of `Event` objects for this extension
    let eventOrderer: OperationOrderer<Event>

    /// Listeners array of `EventListeners` for this extension
    private let eventListeners: ThreadSafeArray<EventListenerContainer>

    /// The last `Event` that was processed by this extension, nil if no events have been processed
    private var _lastProcessedEvent: Event?        
    var lastProcessedEvent: Event? { 
        get { containerQueue.sync { self._lastProcessedEvent } }
        set { containerQueue.async { self._lastProcessedEvent = newValue } }
    }

    /// Initializes a new instance of an `ExtensionContainer`.
    ///
    /// - Parameters:
    ///   - eventHub: The `EventHub` that the extension will interact with using `ExtensionRuntime`.
    ///   - serviceProvider: The `ExtensionServiceProvider` used to provide core services required by the extension.
    ///   - type: The specific `Extension` type being initialized.
    ///   - label: A string label that helps identify the extension, typically for debugging purposes.
    ///   - extensionQueue: The `DispatchQueue` on which the extension is initialized.
    ///   - completion: A closure that is called when the initialization is complete, passing an optional `EventHubError` if an error occurs.
    ///
    /// - Note: The `completion` closure will pass `nil` if the initialization succeeds, or an `EventHubError` if an error occurs during initialization.
    init(eventHub: EventHub, serviceProvider: ExtensionServiceProvider, type: Extension.Type, label: String, extensionQueue: DispatchQueue, completion: @escaping (EventHubError?) -> Void) {
        self.eventHub = eventHub
        self.serviceProvider = serviceProvider
        self.extensionQueue = extensionQueue
        containerQueue = DispatchQueue(label: "\(label).containerQueue")
        eventOrderer = OperationOrderer<Event>("\(label).operationOrderer")
        eventListeners = ThreadSafeArray<EventListenerContainer>()
        eventOrderer.setHandler(eventProcessor)

        // initialize the backing extension on the extension queue
        extensionQueue.async {
            self.exten = type.init(runtime: self)
            guard let unwrappedExtension = self.exten else {
                completion(.extensionInitializationFailure)
                return
            }

            self.sharedState = SharedState(unwrappedExtension.name)
            self.xdmSharedState = SharedState("xdm.\(unwrappedExtension.name)")
            self.sharedStateName = unwrappedExtension.name
            unwrappedExtension.onRegistered()
            self.eventOrderer.start()
            completion(nil)
        }
    }

    /// Returns the corresponding `SharedState` for the given `SharedStateType`
    /// - Parameter type: type of shared state to be retrieved
    /// - Returns: The `SharedState` instance mapped to `type`
    func sharedState(for type: SharedStateType) -> SharedState? {
        switch type {
        case .standard:
            return sharedState
        case .xdm:
            return xdmSharedState
        }
    }
}

// MARK: - ExtensionContainer public extension

extension ExtensionContainer: ExtensionRuntime {

    func getServiceProvider() -> ExtensionServiceProvider {
        return serviceProvider
    }

    func unregisterExtension() {
        guard let exten = exten, let eventHub = eventHub else { return }
        eventHub.unregisterExtension(type(of: exten), completion: {_ in })
    }

    public func registerListener(type: String, source: String, listener: @escaping EventListener) {
        let listenerContainer = EventListenerContainer(listener: listener, type: type, source: source, triggerEventId: nil, timeoutTask: nil)
        eventListeners.append(listenerContainer)
    }

    func registerResponseListener(triggerEvent: Event, timeout: TimeInterval, listener: @escaping EventResponseListener) {
        guard let eventHub = eventHub else { return }
        eventHub.registerResponseListener(triggerEvent: triggerEvent, timeout: timeout, listener: listener)
    }

    func dispatch(event: Event) {
        guard let eventHub = eventHub else { return }
        eventHub.dispatch(event: event)
    }

    func createSharedState(data: [String: Any], event: Event?) {
        guard let eventHub = eventHub else { return }
        eventHub.createSharedState(extensionName: sharedStateName, data: data, event: event)
    }

    func createPendingSharedState(event: Event?) -> SharedStateResolver {
        guard let eventHub = eventHub else { return { _ in } }
        return eventHub.createPendingSharedState(extensionName: sharedStateName, event: event)
    }

    func getSharedState(extensionName: String, event: Event?, barrier: Bool = true) -> SharedStateResult? {
        guard let eventHub = eventHub else { return nil }
        return eventHub.getSharedState(extensionName: extensionName, event: event, barrier: barrier)
    }

    func getSharedState(extensionName: String, event: Event?, barrier: Bool = true, resolution: SharedStateResolution = .any) -> SharedStateResult? {
        guard let eventHub = eventHub else { return nil }
        return eventHub.getSharedState(extensionName: extensionName, event: event, barrier: barrier, resolution: resolution)
    }

    func createXDMSharedState(data: [String: Any], event: Event?) {
        guard let eventHub = eventHub else { return }
        return eventHub.createSharedState(extensionName: sharedStateName, data: data, event: event, sharedStateType: .xdm)
    }

    func createPendingXDMSharedState(event: Event?) -> SharedStateResolver {
        guard let eventHub = eventHub else { return { _ in } }
        return eventHub.createPendingSharedState(extensionName: sharedStateName, event: event, sharedStateType: .xdm)
    }

    func getXDMSharedState(extensionName: String, event: Event?, barrier: Bool = false) -> SharedStateResult? {
        guard let eventHub = eventHub else { return nil }
        return eventHub.getSharedState(extensionName: extensionName, event: event, barrier: barrier, sharedStateType: .xdm)
    }

    func getXDMSharedState(extensionName: String, event: Event?, barrier: Bool = true, resolution: SharedStateResolution = .any) -> SharedStateResult? {
        guard let eventHub = eventHub else { return nil }
        return eventHub.getSharedState(extensionName: extensionName, event: event, barrier: barrier, resolution: resolution, sharedStateType: .xdm)
    }

    func getHistoricalEvents(_ requests: [EventHistoryRequest], enforceOrder: Bool, handler: @escaping ([EventHistoryResult]) -> Void) {
        guard let eventHub = eventHub else { return }
        eventHub.getHistoricalEvents(requests, enforceOrder: enforceOrder, handler: handler)
    }

    func startEvents() {
        eventOrderer.start()
    }

    func stopEvents() {
        eventOrderer.stop()
    }

    func shutdown() {
        eventOrderer.waitToStop()
    }
}

extension ExtensionContainer {
    /// Registers an event preprocessor with the  `EventHub`.
    /// This method currently exists to allow `Configuration` extension to register an `EventPreprocessor` with the correct `EventHub` instance
    /// 
    /// - Parameter preprocessor: A closure of type `EventPreprocessor` that defines the preprocessing logic.
    internal func registerPreprocessor(preprocessor: @escaping EventPreprocessor) {
        guard let eventHub = eventHub else { return }
        eventHub.registerPreprocessor(preprocessor)
    }
}

// MARK: - ExtensionContainer private extension

private extension ExtensionContainer {
    /// Handles event processing, called by the `OperationOrderer` owned by this `ExtensionContainer`
    /// - Parameter event: Event currently being processed
    /// - Returns: *true* if event processing should continue, *false* otherwise
    private func eventProcessor(_ event: Event) -> Bool {
        guard let _ = exten, exten!.readyForEvent(event) else { return false }

        // process events into "standard" listeners
        for listenerContainer in eventListeners.shallowCopy {
            if listenerContainer.shouldNotify(event) {
                listenerContainer.listener(event)
            }
        }

        lastProcessedEvent = event
        return true
    }
}
