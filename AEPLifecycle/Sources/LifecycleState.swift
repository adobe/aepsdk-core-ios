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

/// Manages the business logic of the Lifecycle extension
struct LifecycleState {
    let dataStore: NamedCollectionDataStore

    // Access level modified for tests
    #if DEBUG
        var lifecycleContextData: LifecycleContextData?
        lazy var previousSessionLifecycleContextData: LifecycleContextData? = {
            dataStore.getObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA)
        }()
    #else
        private(set) var lifecycleContextData: LifecycleContextData?
        private(set) lazy var previousSessionLifecycleContextData: LifecycleContextData? = {
            dataStore.getObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA)
        }()
    #endif

    private var lifecycleSession: LifecycleSession

    /// Creates a new `LifecycleState` with the given `NamedCollectionDataStore`
    /// - Parameter dataStore: The Lifecycle extension's data store
    init(dataStore: NamedCollectionDataStore) {
        self.dataStore = dataStore
        lifecycleSession = LifecycleSession(dataStore: dataStore)
    }

    /// Loads the initial Lifecycle metrics which includes device data and launch event
    /// - Returns: `LifecycleContextData` with device data, launch event data and any persisted context data
    mutating func computeBootData() -> LifecycleContextData {
        let contextData = LifecycleContextData().merging(with: getContextData())
        let defaultMetrics = LifecycleMetricsBuilder(dataStore: dataStore, date: Date()).addDeviceData().addLaunchEventData().build()

        var bootContextData = LifecycleContextData()
        bootContextData.lifecycleMetrics = defaultMetrics
        return contextData.merging(with: bootContextData)
    }

    /// Starts a new lifecycle session at the given date with the provided data
    /// - Parameters:
    ///   - date: date at which the start event occurred
    ///   - additionalContextData: additional context data for this start event
    ///   - adId: The advertising identifier provided by the identity extension
    ///   - sessionTimeout: The session timeout for this start event, defaults to 300 seconds
    ///   - isInstall: Indicates whether this is an application install scenario
    /// - Returns: The previous session info if exists, otherwise nil
    mutating func start(date: Date,
                        additionalContextData: [String: Any]?,
                        adId: String?,
                        sessionTimeout: TimeInterval = TimeInterval(LifecycleConstants.DEFAULT_LIFECYCLE_TIMEOUT),
                        isInstall: Bool) -> LifecycleSessionInfo? {
        let sessionContainer: LifecyclePersistedContext? = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT)
        // Build default LifecycleMetrics
        let metricsBuilder = LifecycleMetricsBuilder(dataStore: dataStore, date: date).addDeviceData()
        let defaultMetrics = metricsBuilder.build()
        if !isInstall {
            applyApplicationUpgrade(appId: defaultMetrics.appId)
        }

        guard let previousSessionInfo = lifecycleSession.start(date: date, sessionTimeout: sessionTimeout, coreMetrics: defaultMetrics) else { return nil }

        var lifecycleData = LifecycleContextData()

        if isInstall {
            metricsBuilder.addInstallData().addLaunchEventData()
        } else {
            // upgrade and launch hits
            let upgrade = isUpgrade()
            metricsBuilder.addLaunchEventData()
                .addLaunchData(prevOsVersion: sessionContainer?.osVersion, prevAppId: sessionContainer?.appId)
                .addUpgradeData(upgrade: upgrade)
                .addCrashData(previousSessionCrash: previousSessionInfo.isCrash)

            let sessionContextData = lifecycleSession.getSessionData(startDate: date, sessionTimeout: sessionTimeout, previousSessionInfo: previousSessionInfo)
            lifecycleData.sessionContextData = sessionContextData
        }

        lifecycleData.lifecycleMetrics = metricsBuilder.build()

        lifecycleData.additionalContextData = additionalContextData ?? [:]
        lifecycleData.advertisingIdentifier = adId

        // Update lifecycle context data and persist lifecycle info into local storage
        lifecycleContextData = lifecycleData

        persistLifecycleContextData(startDate: date)

        return previousSessionInfo
    }

    /// Pauses the current lifecycle session
    /// - Parameter pauseDate: date at which the pause event occurred
    mutating func pause(pauseDate: Date) {
        lifecycleSession.pause(pauseDate: pauseDate)
    }

    /// Gets the current context data stored in memory, if none in memory will check data store, if not present will return nil
    mutating func getContextData() -> LifecycleContextData? {
        return lifecycleContextData ?? previousSessionLifecycleContextData
    }

    /// Gets the current session start date from data store, if not present will return nil
    func getSessionStartDate() -> Date? {
        return lifecycleSession.getPersistedStartDate()
    }

    /// Updates the application identifier in the in-memory lifecycle context data
    /// - Parameter appId: the application identifier
    mutating func applyApplicationUpgrade(appId: String?) {
        // early out if this isn't an upgrade
        if !isUpgrade() { return }

        // get a map of lifecycle data in shared preferences or memory
        guard var lifecycleData = getContextData() else { return }

        // update the version in our map
        lifecycleData.lifecycleMetrics.appId = appId

        if lifecycleContextData == nil {
            // update the previous session's map
            previousSessionLifecycleContextData?.lifecycleMetrics.appId = appId
            dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA, value: lifecycleData)
        } else {
            // if we have the map in memory update it
            lifecycleContextData = lifecycleContextData?.merging(with: lifecycleData) ?? lifecycleData
        }
    }

    // MARK: Private APIs

    /// Returns true if the current app version does not equal the app version stored in the data store
    private func isUpgrade() -> Bool {
        let appVersion = ServiceProvider.shared.systemInfoService.getApplicationBuildNumber()
        return dataStore.getString(key: LifecycleConstants.DataStoreKeys.LAST_VERSION) != appVersion
    }

    /// Saves `lifecycleContextData` to the data store along with the start date and application version number
    /// - Parameter startDate: Date the lifecycle session started
    private func persistLifecycleContextData(startDate: Date) {
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA, value: lifecycleContextData)
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LAST_LAUNCH_DATE, value: startDate)
        let appVersion = ServiceProvider.shared.systemInfoService.getApplicationBuildNumber()
        dataStore.set(key: LifecycleConstants.DataStoreKeys.LAST_VERSION, value: appVersion)
    }
}
