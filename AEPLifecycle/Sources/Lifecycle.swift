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

import AEPCore
import AEPServices
import Foundation

@objc(AEPMobileLifecycle)
public class Lifecycle: NSObject, Extension {
    private var lifecycleState: LifecycleState
    private var lifecycleV2: LifecycleV2

    // MARK: Extension

    public let name = LifecycleConstants.EXTENSION_NAME
    public let friendlyName = LifecycleConstants.FRIENDLY_NAME
    public static let extensionVersion = LifecycleConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil

    public let runtime: ExtensionRuntime

    /// Invoked when the `EventHub` creates it's instance of the Lifecycle extension
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        // Handle the classic lifecycle workflow
        lifecycleState = LifecycleState(dataStore: NamedCollectionDataStore(name: name))
        // Handle the XDM workflow to compute the application launch/close XDM metrics
        lifecycleV2 = LifecycleV2(dataStore: NamedCollectionDataStore(name: name), dispatch: runtime.dispatch(event:))
        super.init()
    }

    /// Invoked when the `EventHub` has successfully registered the Lifecycle extension.
    public func onRegistered() {
        registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent, listener: receiveLifecycleRequest(event:))
        registerListener(type: EventType.wildcard, source: EventSource.wildcard, listener: updateLastKnownTime(event:))

        let sharedStateData = [LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA: lifecycleState.computeBootData().toEventData()]
        createSharedState(data: sharedStateData as [String: Any], event: nil)
    }

    public func onUnregistered() {}

    public func readyForEvent(_ event: Event) -> Bool {
        if event.type == EventType.genericLifecycle, event.source == EventSource.requestContent {
            let configurationSharedState = getSharedState(extensionName: LifecycleConstants.SharedStateKeys.CONFIGURATION, event: event)
            return configurationSharedState?.status == .set
        }

        return true
    }

    // MARK: Event Listeners

    /// Invoked when any event is dispatched by the `EventHub`
    /// Updates the last known event date in cache and if needed in persistence
    /// - Parameter event: any event to be processed.
    private func updateLastKnownTime(event: Event) {
        lifecycleV2.updateLastKnownTime(event: event)
    }

    /// Invoked when an event of type generic lifecycle and source request content is dispatched by the `EventHub`
    /// - Parameter event: the generic lifecycle event
    private func receiveLifecycleRequest(event: Event) {
        guard let configurationSharedState = getSharedState(extensionName: LifecycleConstants.SharedStateKeys.CONFIGURATION, event: event) else {
            Log.trace(label: LifecycleConstants.LOG_TAG, "Waiting for valid configuration to process lifecycle.")
            return
        }

        if event.isLifecycleStartEvent {
            Log.debug(label: LifecycleConstants.LOG_TAG, "Starting lifecycle.")
            startApplicationLifecycle(event: event, configurationSharedState: configurationSharedState)
        } else if event.isLifecyclePauseEvent {
            Log.debug(label: LifecycleConstants.LOG_TAG, "Pausing lifecycle.")
            pauseApplicationLifecycle(event: event)
        }
    }

    // MARK: Helpers

    /// Start the lifecycle session for standard and XDM workflows
    /// Invokes the start business logic and dispatches any shared state and lifecycle response events required
    /// - Parameters:
    ///   - event: the lifecycle start event
    ///   - configurationSharedState: the current configuration shared state
    private func startApplicationLifecycle(event: Event, configurationSharedState: SharedStateResult) {
        let install = isInstall()
        let prevSessionInfo = lifecycleState.start(date: event.timestamp,
                                                   additionalContextData: event.additionalData,
                                                   adId: getAdvertisingIdentifier(event: event),
                                                   sessionTimeout: getSessionTimeoutLength(configurationSharedState: configurationSharedState.value),
                                                   isInstall: install)

        // Republish shared state after handling lifecycle start event as LifecycleState will
        // 1) Update lifecycle metrics in context data if it detects a new session
        // 2) Adjust session start timestamp to offset pause duration
        updateSharedState(event: event,
                          data: lifecycleState.getContextData()?.toEventData() ?? [:],
                          startDate: lifecycleState.getSessionStartDate() ?? Date(timeIntervalSince1970: 0)
        )

        if let prevSessionInfo = prevSessionInfo {
            dispatchSessionStart(parentEvent: event, contextData: lifecycleState.getContextData(), previousStartDate: prevSessionInfo.startDate, previousPauseDate: prevSessionInfo.pauseDate)
        }

        lifecycleV2.start(parentEvent: event, isInstall: install)

        if install {
            persistInstallDate(event.timestamp)
        }
    }

    /// Pause the lifecycle session for standard and XDM workflows
    /// - Parameters:
    ///   - event: the lifecycle pause event
    private func pauseApplicationLifecycle(event: Event) {
        lifecycleState.pause(pauseDate: event.timestamp)
        lifecycleV2.pause(parentEvent: event)
    }

    /// Attempts to read the advertising identifier from Identity shared state
    /// - Parameter event: event to version the shared state
    /// - Returns: the advertising identifier, nil if not found or if Identity shared state is not available
    private func getAdvertisingIdentifier(event: Event) -> String? {
        guard let identitySharedState = getSharedState(extensionName: LifecycleConstants.Identity.NAME, event: event) else {
            return nil
        }

        if identitySharedState.status == .pending { return nil }

        return identitySharedState.value?[LifecycleConstants.Identity.EventDataKeys.ADVERTISING_IDENTIFIER] as? String
    }

    /// Updates the Lifecycle shared state versioned at `event` with `data`
    /// - Parameters:
    ///   - event: the event to version the shared state at
    ///   - data: data for the shared state
    ///   - startDate: start timestamp of the lifecycle session
    private func updateSharedState(event: Event, data: [String: Any], startDate: Date) {
        let sharedStateData: [String: Any] = [
            LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA: data,
            LifecycleConstants.EventDataKeys.SESSION_START_TIMESTAMP: startDate.timeIntervalSince1970,
            LifecycleConstants.EventDataKeys.MAX_SESSION_LENGTH: LifecycleConstants.MAX_SESSION_LENGTH_SECONDS,
        ]
        createSharedState(data: sharedStateData, event: event)
    }

    /// Dispatches a Lifecycle response content event with appropriate event data
    /// - Parameters:
    ///   - parentEvent: the triggering lifecycle event
    ///   - contextData: current Lifecycle context data
    ///   - previousStartDate: start date of the previous session
    ///   - previousPauseDate: end date of the previous session
    private func dispatchSessionStart(parentEvent: Event, contextData: LifecycleContextData?, previousStartDate: Date?, previousPauseDate: Date?) {
        let eventData: [String: Any] = [
            LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA: contextData?.toEventData() ?? [:],
            LifecycleConstants.EventDataKeys.SESSION_EVENT: LifecycleConstants.START,
            LifecycleConstants.EventDataKeys.SESSION_START_TIMESTAMP: parentEvent.timestamp.timeIntervalSince1970,
            LifecycleConstants.EventDataKeys.MAX_SESSION_LENGTH: LifecycleConstants.MAX_SESSION_LENGTH_SECONDS,
            LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_START_TIMESTAMP: previousStartDate?.timeIntervalSince1970 ?? 0.0,
            LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_PAUSE_TIMESTAMP: previousPauseDate?.timeIntervalSince1970 ?? 0.0,
        ]
        let startEvent = parentEvent.createChainedEvent(name: LifecycleConstants.EventNames.LIFECYCLE_START,
                                                        type: EventType.lifecycle,
                                                        source: EventSource.responseContent,
                                                        data: eventData)
        Log.trace(label: LifecycleConstants.LOG_TAG, "Dispatching lifecycle start event with data: \n\(PrettyDictionary.prettify(eventData))")
        dispatch(event: startEvent)
    }

    /// Reads the session timeout from the configuration shared state, if not found returns the default session timeout
    /// - Parameter configurationSharedState: the data associated with the configuration shared state
    private func getSessionTimeoutLength(configurationSharedState: [String: Any]?) -> TimeInterval {
        guard let sessionTimeoutInt = configurationSharedState?[LifecycleConstants.EventDataKeys.CONFIG_SESSION_TIMEOUT] as? Int else {
            return TimeInterval(LifecycleConstants.DEFAULT_LIFECYCLE_TIMEOUT)
        }

        return TimeInterval(sessionTimeoutInt)
    }

    /// - Returns: true if there is no install date stored in the data store
    private func isInstall() -> Bool {
        let dataStore = NamedCollectionDataStore(name: name)
        return !dataStore.contains(key: LifecycleConstants.DataStoreKeys.INSTALL_DATE)
    }

    /// Persists the application install date
    /// - Parameter date: install date
    private func persistInstallDate(_ date: Date) {
        let dataStore = NamedCollectionDataStore(name: name)
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.INSTALL_DATE, value: date)
    }
}
