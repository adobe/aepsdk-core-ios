/*
 Copyright 2021 Adobe. All rights reserved.
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

/// The responsibility of `LifecycleV2` is to compute the application launch/close XDM metrics,
/// usually consumed by the Edge Network and related extensions
class LifecycleV2 {
    private let dataStore: NamedCollectionDataStore
    private let dataStoreCache: LifecycleV2DataStoreCache
    private let stateManager: LifecycleV2StateManager
    private let dispatch: ((_ event: Event) -> Void)
    private var systemInfoService: SystemInfoService {
        ServiceProvider.shared.systemInfoService
    }
    private let xdmMetricsBuilder: LifecycleV2MetricsBuilder

    /// Creates a new `LifecycleV2` with the given `NamedCollectionDataStore`
    ///
    /// - Parameters:
    ///   - dataStore: The `NamedCollectionDataStore` used for reading and writing data to persistence
    ///   - dispatch: The dispatch closure which is used to dispatch application launch/close events to `EventHub`
    init(dataStore: NamedCollectionDataStore, dispatch: @escaping (_ event: Event) -> Void) {
        self.dataStore = dataStore
        self.stateManager = LifecycleV2StateManager()
        self.dataStoreCache = LifecycleV2DataStoreCache(dataStore: self.dataStore)
        self.xdmMetricsBuilder = LifecycleV2MetricsBuilder()
        self.dispatch = dispatch
    }

    /// Updates the last known event date in cache and if needed in persistence
    /// - Parameter event: any event to be processed.
    func updateLastKnownTime(event: Event) {
        dataStoreCache.setLastKnownDate(event.timestamp)
    }

    /// Handles the start use-case as application launch XDM event. If a previous abnormal close was detected,
    /// an application close event is dispatched first.
    ///
    /// - Parameters:
    ///   - parentEvent: The triggering lifecycle event
    ///   - isInstall: indicates whether this is an application install scenario
    func start(parentEvent: Event,
               isInstall: Bool) {
        stateManager.update(state: .START) { [weak self] (updated: Bool) in
            guard let self = self else { return }
            guard updated else { return }
            let date = parentEvent.timestamp
            // detect a possible crash/incorrect start/pause implementation
            if !isInstall && self.isCloseUnknown(prevAppStart: self.dataStoreCache.getAppStartDate(), prevAppPause: self.dataStoreCache.getAppPauseDate()) {
                // in case of an unknown close situation, use the last known app close event timestamp
                let previousAppStartDate = self.dataStoreCache.getAppStartDate()
                let previousAppCloseDate = self.dataStoreCache.getCloseDate()
                // if no close timestamp was persisted, backdate this event to start timestamp - 1 second
                let computedAppCloseDate = Date(timeIntervalSince1970: (date.timeIntervalSince1970 - 1))

                if let crashXDM = self.xdmMetricsBuilder.buildAppCloseXDMData(launchDate: previousAppStartDate, closeDate: previousAppCloseDate, fallbackCloseDate: computedAppCloseDate, isCloseUnknown: true) {
                    // dispatch application close event with xdm data
                    self.dispatchApplicationClose(xdm: crashXDM, parentEvent: parentEvent)
                }
            }

            self.dataStoreCache.setAppStartDate(date)

            if let launchXDM = self.xdmMetricsBuilder.buildAppLaunchXDMData(launchDate: date, isInstall: isInstall, isUpgrade: self.isUpgrade()) {
                // dispatch application launch event with xdm data
                self.dispatchApplicationLaunch(xdm: launchXDM, parentEvent: parentEvent)
            }

            self.persistAppVersion()
        }
    }

    /// Handles the pause use-case as application close XDM event.
    ///
    /// - Parameter parentEvent: The triggering lifecycle pause event
    func pause(parentEvent: Event) {
        stateManager.update(state: .PAUSE) { [weak self] (updated: Bool) in
            guard let self = self else { return }
            guard updated else { return }
            let pauseDate = parentEvent.timestamp
            // store pause date to persistence
            self.dataStoreCache.setAppPauseDate(pauseDate)
            // get start date from cache/presistence
            let startDate = self.dataStoreCache.getAppStartDate()

            if let closeXDM = self.xdmMetricsBuilder.buildAppCloseXDMData(launchDate: startDate, closeDate: pauseDate, fallbackCloseDate: pauseDate, isCloseUnknown: false) {
                // dispatch application close event with xdm data
                self.dispatchApplicationClose(xdm: closeXDM, parentEvent: parentEvent)
            }
        }

    }
    /// Identifies if the previous session ended due to an incorrect implementation or possible app crash.
    ///
    /// - Parameters:
    ///   - prevAppStart: start date from previous session
    ///   - prevAppPause: pause date from previous session
    /// - Returns:Bool indicating the status of the previous app close, true if this is considered an unknown close event
    private func isCloseUnknown(prevAppStart: Date?, prevAppPause: Date?) -> Bool {
        let prevAppStartTS = prevAppStart?.timeIntervalSince1970 ?? 0
        let prevAppPauseTS = prevAppPause?.timeIntervalSince1970 ?? 0

        return prevAppStartTS <= 0 || prevAppStartTS > prevAppPauseTS
    }

    /// Dispatches a Lifecycle application launch event with appropriate event data
    /// - Parameters:
    ///   - xdm: xdm data for the application launch event
    ///   - parentEvent: the triggering lifecycle event
    private func dispatchApplicationLaunch(xdm: [String: Any], parentEvent: Event) {
        var eventData: [String: Any] = [:]
        eventData[LifecycleV2Constants.EventDataKeys.XDM] = xdm

        if let freeFormData = parentEvent.additionalData, !freeFormData.isEmpty {
            eventData[LifecycleV2Constants.EventDataKeys.DATA] = freeFormData
        }

        let applicationLaunchEvent = parentEvent.createChainedEvent(name: LifecycleV2Constants.EventNames.APPLICATION_LAUNCH, type: EventType.lifecycle, source: EventSource.applicationLaunch, data: eventData)
        dispatch(applicationLaunchEvent)
    }

    /// Dispatches a Lifecycle application close event with appropriate event data
    /// - Parameters:
    ///   - xdm: xdm data for the application close event
    ///   - parentEvent: the triggering lifecycle event
    private func dispatchApplicationClose(xdm: [String: Any], parentEvent: Event) {
        let eventData: [String: Any] = [
            LifecycleV2Constants.EventDataKeys.XDM: xdm
        ]

        let applicationCloseEvent = parentEvent.createChainedEvent(name: LifecycleV2Constants.EventNames.APPLICATION_CLOSE, type: EventType.lifecycle, source: EventSource.applicationClose, data: eventData)
        dispatch(applicationCloseEvent)
    }

    /// - Returns: Bool indicating whether the app has been upgraded
    private func isUpgrade() -> Bool {
        if let previousAppVersion = dataStore.getString(key: LifecycleV2Constants.DataStoreKeys.LAST_APP_VERSION) {
            let currentAppVersion = LifecycleV2.getAppVersion(systemInfoService: systemInfoService)
            return previousAppVersion != currentAppVersion
        }

        return false
    }

    /// Persist the application version into dataStore
    private func persistAppVersion() {
        let currentAppVersion = LifecycleV2.getAppVersion(systemInfoService: systemInfoService)
        dataStore.set(key: LifecycleV2Constants.DataStoreKeys.LAST_APP_VERSION, value: currentAppVersion)
    }
    
    /// Returns the application version in the format appVersion (versionCode). Example: 2.3 (10)
    /// - Returns: the app version as a `String` formatted in the specified format.
    static func getAppVersion(systemInfoService: SystemInfoService) -> String {
        let appBuildNumber = systemInfoService.getApplicationBuildNumber() ?? ""
        let appVersionNumber = systemInfoService.getApplicationVersionNumber() ?? ""
        return "\(appVersionNumber) (\(appBuildNumber))".replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: "()", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
