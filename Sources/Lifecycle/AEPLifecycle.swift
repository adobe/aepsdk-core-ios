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

class AEPLifecycle: Extension {
    let name = LifecycleConstants.EXTENSION_NAME
    let version = LifecycleConstants.EXTENSION_VERSION
    
    private let eventQueue = OperationOrderer<EventHandlerMapping>(LifecycleConstants.EXTENSION_NAME)
    private var lifecycleState: LifecycleState
    
    // MARK: Extension
    
    /// Invoked when the `EventHub` creates it's instance of the Lifecycle extension
    required init() {
        lifecycleState = LifecycleState(dataStore: NamedKeyValueStore(name: name))
        eventQueue.setHandler({ return $0.handler($0.event) })
    }
    
    /// Invoked when the `EventHub` has successfully registered the Lifecycle extension.
    func onRegistered() {
        registerListener(type: .genericLifecycle, source: .requestContent, listener: receiveLifecycleRequest(event:))
        registerListener(type: .hub, source: .sharedState, listener: receiveSharedState(event:))
        
        let sharedStateData = [LifecycleConstants.Keys.LIFECYCLE_CONTEXT_DATA: lifecycleState.computeBootData().toEventData()]
        createSharedState(data: sharedStateData as [String : Any], event: nil)
        eventQueue.start()
    }
    
    func onUnregistered() {}
    
    // MARK: Event Listeners
    
    /// Invoked when an event of type generic lifecycle and source request content is dispatched by the `EventHub`
    /// - Parameter event: the generic lifecycle event
    private func receiveLifecycleRequest(event: Event) {
        eventQueue.add((event, handleLifecycleRequest(event:)))
    }
    
    /// Invoked when the `EventHub` dispatches a shared state event. If the shared state owner is Configuration we trigger the internal `eventQueue`.
    /// - Parameter event: The shared state event
    private func receiveSharedState(event: Event) {
        guard let stateOwner = event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String else { return }

        if stateOwner == ConfigurationConstants.EXTENSION_NAME {
            eventQueue.start()
        }
    }
    
    // MARK: Event Handlers
    
    /// Handles the Lifecycle request event by either invoking the start or pause business logic
    /// - Parameter event: a Lifecycle request event
    /// - Returns: True if the Lifecycle event was processed, false if the configuration shared state is not yet ready
    private func handleLifecycleRequest(event: Event) -> Bool {
        guard let configurationSharedState = getSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: event) else {
            return false
        }
        
        guard configurationSharedState.status == .set else { return false }
        
        if event.isLifecycleStartEvent {
            start(event: event, configurationSharedState: configurationSharedState)
        } else if event.isLifecyclePauseEvent {
            lifecycleState.pause(pauseDate: event.timestamp)
        }
        
        return true
    }
    
    // MARK: Helpers
    
    /// Invokes the start business logic and dispatches any shared state and lifecycle response events required
    /// - Parameters:
    ///   - event: the lifecycle start event
    ///   - configurationSharedState: the current configuration shared state
    private func start(event: Event, configurationSharedState: (value: [String : Any]?, status: SharedStateStatus)) {
        let prevSessionInfo = lifecycleState.start(date: event.timestamp,
                                                   additionalContextData: event.additionalData,
                                                   adId: getAdvertisingIdentifier(event: event),
                                                   sessionTimeout: getSessionTimeoutLength(configurationSharedState: configurationSharedState.value))
        updateSharedState(event: event, data: lifecycleState.getContextData()?.toEventData() ?? [:])
        
        
        if let prevSessionInfo = prevSessionInfo {
            dispatchSessionStart(date: event.timestamp, contextData: lifecycleState.getContextData(), previousStartDate: prevSessionInfo.startDate, previousPauseDate: prevSessionInfo.pauseDate)
        }
    }
    
    /// Attempts to read the advertising identifier from Identity shared state
    /// - Parameter event: event to version the shared state
    /// - Returns: the advertising identifier, nil if not found or if Identity shared state is not available
    private func getAdvertisingIdentifier(event: Event) -> String? {
        // TODO: Replace with Identity name via constant when Identity extension is merged
        guard let identitySharedState = getSharedState(extensionName: "com.adobe.module.identity", event: event) else {
            return nil
        }
        
        if identitySharedState.status == .pending { return nil }
        
        // TODO: Replace with data key via constant when Identity extension is merged
        return identitySharedState.value?["advertisingidentifier"] as? String
    }
    
    /// Updates the Lifecycle shared state versioned at `event` with `data`
    /// - Parameters:
    ///   - event: the event to version the shared state at
    ///   - data: data for the shared state
    private func updateSharedState(event: Event, data: [String: Any]) {
        let sharedStateData = [LifecycleConstants.Keys.LIFECYCLE_CONTEXT_DATA: data]
        createSharedState(data: sharedStateData as [String : Any], event: event)
    }
    
    /// Dispatches a Lifecycle response content event with appropriate event data
    /// - Parameters:
    ///   - date: date of the session start event
    ///   - contextData: current Lifecycle context data
    ///   - previousStartDate: start date of the previous session
    ///   - previousPauseDate: end date of the previous session
    private func dispatchSessionStart(date: Date, contextData: LifecycleContextData?, previousStartDate: Date?, previousPauseDate: Date?) {
        let eventData: [String: Any] = [
            LifecycleConstants.Keys.LIFECYCLE_CONTEXT_DATA: contextData?.toEventData() ?? [:],
            LifecycleConstants.Keys.SESSION_EVENT: LifecycleConstants.START,
            LifecycleConstants.Keys.SESSION_START_TIMESTAMP: date.timeIntervalSince1970,
            LifecycleConstants.Keys.MAX_SESSION_LENGTH: LifecycleConstants.MAX_SESSION_LENGTH_SECONDS,
            LifecycleConstants.Keys.PREVIOUS_SESSION_START_TIMESTAMP: previousStartDate?.timeIntervalSince1970 ?? 0,
            LifecycleConstants.Keys.PREVIOUS_SESSION_PAUSE_TIMESTAMP: previousPauseDate?.timeIntervalSince1970 ?? 0
        ]
        
        dispatch(event: Event(name: "LifecycleStart", type: .lifecycle, source: .responseContent, data: eventData))
    }
    
    /// Reads the session timeout from the configuration shared state, if not found returns the default session timeout
    /// - Parameter configurationSharedState: the data associated with the configuration shared state
    private func getSessionTimeoutLength(configurationSharedState: [String: Any]?) -> TimeInterval {
        guard let sessionTimeoutInt = configurationSharedState?[LifecycleConstants.Keys.CONFIG_SESSION_TIMEOUT] as? Int else {
            return TimeInterval(LifecycleConstants.DEFAULT_LIFECYCLE_TIMEOUT)
        }
        
        return TimeInterval(sessionTimeoutInt)
    }
}
