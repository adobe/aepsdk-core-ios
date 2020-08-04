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
import AEPCore

@objc(AEPLifecycle) public class Lifecycle: NSObject, Extension {
    public let name = LifecycleConstants.EXTENSION_NAME
    public let friendlyName = LifecycleConstants.FRIENDLY_NAME
    public static let extensionVersion = LifecycleConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    
    public let runtime: ExtensionRuntime

    private var lifecycleState: LifecycleState
    
    // MARK: Extension
    
    /// Invoked when the `EventHub` creates it's instance of the Lifecycle extension
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        lifecycleState = LifecycleState(dataStore: NamedCollectionDataStore(name: name))
        super.init()
    }
    
    /// Invoked when the `EventHub` has successfully registered the Lifecycle extension.
    public func onRegistered() {
        registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent, listener: receiveLifecycleRequest(event:))
        
        let sharedStateData = [LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA: lifecycleState.computeBootData().toEventData()]
        createSharedState(data: sharedStateData as [String : Any], event: nil)
    }
    
    public func onUnregistered() {}
    
    public func readyForEvent(_ event: Event) -> Bool {
        if event.type == EventType.genericLifecycle && event.source == EventSource.requestContent {
            let configurationSharedState = getSharedState(extensionName: LifecycleConstants.SharedStateKeys.CONFIGURATION, event: event)
            return configurationSharedState?.status == .set
        }
        
        return true
    }
    
    // MARK: Event Listeners
    
    /// Invoked when an event of type generic lifecycle and source request content is dispatched by the `EventHub`
    /// - Parameter event: the generic lifecycle event
    private func receiveLifecycleRequest(event: Event) {
        guard let configurationSharedState = getSharedState(extensionName: LifecycleConstants.SharedStateKeys.CONFIGURATION, event: event) else { return }
        
        if event.isLifecycleStartEvent {
            start(event: event, configurationSharedState: configurationSharedState)
        } else if event.isLifecyclePauseEvent {
            lifecycleState.pause(pauseDate: event.timestamp)
        }
    }
    
    // MARK: Helpers
    
    /// Invokes the start business logic and dispatches any shared state and lifecycle response events required
    /// - Parameters:
    ///   - event: the lifecycle start event
    ///   - configurationSharedState: the current configuration shared state
    private func start(event: Event, configurationSharedState: SharedStateResult) {
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
        let sharedStateData = [LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA: data]
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
            LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA: contextData?.toEventData() ?? [:],
            LifecycleConstants.EventDataKeys.SESSION_EVENT: LifecycleConstants.START,
            LifecycleConstants.EventDataKeys.SESSION_START_TIMESTAMP: date.timeIntervalSince1970,
            LifecycleConstants.EventDataKeys.MAX_SESSION_LENGTH: LifecycleConstants.MAX_SESSION_LENGTH_SECONDS,
            LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_START_TIMESTAMP: previousStartDate?.timeIntervalSince1970 ?? 0.0,
            LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_PAUSE_TIMESTAMP: previousPauseDate?.timeIntervalSince1970 ?? 0.0
        ]
        
        dispatch(event: Event(name: "LifecycleStart", type: EventType.lifecycle, source: EventSource.responseContent, data: eventData))
    }
    
    /// Reads the session timeout from the configuration shared state, if not found returns the default session timeout
    /// - Parameter configurationSharedState: the data associated with the configuration shared state
    private func getSessionTimeoutLength(configurationSharedState: [String: Any]?) -> TimeInterval {
        guard let sessionTimeoutInt = configurationSharedState?[LifecycleConstants.EventDataKeys.CONFIG_SESSION_TIMEOUT] as? Int else {
            return TimeInterval(LifecycleConstants.DEFAULT_LIFECYCLE_TIMEOUT)
        }
        
        return TimeInterval(sessionTimeoutInt)
    }
}
