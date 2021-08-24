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
    private let dispatch: ((Event) -> Void)
    private let xdmMetricsBuilder: LifecycleV2MetricsBuilder

    private var systemInfoService: SystemInfoService {
        ServiceProvider.shared.systemInfoService
    }

    /// Creates a new `LifecycleV2` with the given `NamedCollectionDataStore`
    ///
    /// - Parameter dataStore: The `NamedCollectionDataStore` used for reading and writing data to persistence
    init(dataStore: NamedCollectionDataStore, metricsBuilder: LifecycleV2MetricsBuilder? = nil, dispatch: @escaping (Event) -> Void) {
        self.dataStore = dataStore
        self.stateManager = LifecycleV2StateManager()
        self.dataStoreCache = LifecycleV2DataStoreCache(dataStore: self.dataStore)
        self.xdmMetricsBuilder = metricsBuilder ?? LifecycleV2MetricsBuilder()
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
    ///   - date: date at which the start event occurred
    ///   - additionalData: additional data received with the start event
    ///   - isInstall: indicates whether this is an application install scenario
    func start(date: Date,
               additionalData: [String: Any]?,
               isInstall: Bool) {
        stateManager.update(state: .START) { [weak self] (updated: Bool) in
            guard let self = self else { return }
            guard updated else { return }

            // detect a possible crash/incorrect start/pause implementation
            if !isInstall && self.isCloseUnknown(prevAppStart: self.dataStoreCache.getAppStartDate(), prevAppPause: self.dataStoreCache.getAppPauseDate()) {
                // in case of an unknown close situation, use the last known app close event timestamp
                guard let xdm = self.xdmMetricsBuilder.buildAppCloseXDMData(launchDate: self.dataStoreCache.getAppStartDate() ?? Date(), closeDate: self.dataStoreCache.getCloseDate() ?? Date(), isCloseUnknown: false) else { return }

                // dispatch application close event with xdm data
                self.dispatchApplicationClose(xdm: xdm)
            }

            guard let xdm = self.xdmMetricsBuilder.buildAppLaunchXDMData(launchDate: date, isInstall: isInstall, isUpgrade: self.isUpgrade()) else { return }

            // dispatch application launch event with xdm data
            self.dispatchApplicationLaunch(xdm: xdm, data: additionalData)
            self.persistAppVersion()
        }
    }

    /// Handles the pause use-case as application close XDM event.
    ///
    /// - Parameter pauseDate: Date at which the pause event occurred
    func pause(pauseDate: Date) {
        stateManager.update(state: .PAUSE) { [weak self] (updated: Bool) in
            guard let self = self else { return }
            guard updated else { return }
            guard let xdm = self.xdmMetricsBuilder.buildAppCloseXDMData(launchDate: self.dataStoreCache.getAppStartDate() ?? Date(), closeDate: pauseDate, isCloseUnknown: false) else { return }

            // dispatch application close event with xdm data
            self.dispatchApplicationClose(xdm: xdm)
        }

    }
    /// Identifies if the previous session ended due to an incorrect implementation or possible app crash.
    ///
    /// - Parameters:
    ///   - prevAppStart: start timestamp from previous session
    ///   - prevAppPause: pause timestamp from previous session
    /// - Returns:Bool indicating the status of the previous app close, true if this is considered an unknown close event
    private func isCloseUnknown(prevAppStart: Date?, prevAppPause: Date?) -> Bool {
        let prevAppStartTS = prevAppStart?.timeIntervalSince1970 ?? 0
        let prevAppPauseTS = prevAppPause?.timeIntervalSince1970 ?? 0

        return prevAppStartTS <= 0 || prevAppStartTS > prevAppPauseTS
    }

    /// Dispatches a Lifecycle application launch event with appropriate event data
    /// - Parameters:
    ///   - xdm: xdm data for the application launch event
    ///   - data: additional free-form context data
    private func dispatchApplicationLaunch(xdm: [String: Any], data: [String: Any]?) {
        var eventData: [String: Any] = [:]
        eventData[LifecycleConstants.EventDataKeys.XDM] = xdm

        if let freeFormData = data, !freeFormData.isEmpty {
            eventData[LifecycleConstants.EventDataKeys.DATA] = freeFormData
        }

        let applicationLaunchEvent = Event(name: LifecycleConstants.EventNames.APPLICATION_LAUNCH, type: EventType.lifecycle, source: EventSource.applicationLaunch, data: eventData)
        dispatch(applicationLaunchEvent)
    }

    /// Dispatches a Lifecycle application close event with appropriate event data
    /// - Parameters:
    ///   - xdm: xdm data for the application close event
    private func dispatchApplicationClose(xdm: [String: Any]) {
        let eventData: [String: Any] = [
            LifecycleConstants.EventDataKeys.XDM: xdm
        ]

        let applicationCloseEvent = Event(name: LifecycleConstants.EventNames.APPLICATION_CLOSE, type: EventType.lifecycle, source: EventSource.applicationClose, data: eventData)
        dispatch(applicationCloseEvent)
    }

    /// - Returns: Bool indicating whether the app has been upgraded
    private func isUpgrade() -> Bool {
        if let currentAppVersion = systemInfoService.getApplicationVersion(),
           let previousAppVersion = dataStore.getString(key: LifecycleV2Constants.DataStoreKeys.LAST_APP_VERSION) {
            return previousAppVersion != currentAppVersion
        }

        return false
    }

    /// Persist the application version into dataStore
    private func persistAppVersion() {
        guard let currentAppVersion = systemInfoService.getApplicationVersion() else { return }
        dataStore.set(key: LifecycleV2Constants.DataStoreKeys.LAST_APP_VERSION, value: currentAppVersion)
    }
}
