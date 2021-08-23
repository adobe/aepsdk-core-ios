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
    private let stateManager: LifecycleV2StateManager

    private var dataStoreCache: LifecycleV2DataStoreCache
    private var systemInfoService: SystemInfoService {
        ServiceProvider.shared.systemInfoService
    }

    /// Creates a new `LifecycleV2` with the given `NamedCollectionDataStore`
    ///
    /// - Parameter dataStore: The `NamedCollectionDataStore` used for reading and writing data to persistence
    init(dataStore: NamedCollectionDataStore) {
        self.dataStore = dataStore
        let dispatchQueue = DispatchQueue(label: "\(LifecycleV2Constants.EXTENSION_NAME)")
        self.stateManager = LifecycleV2StateManager(dispatchQueue: dispatchQueue)
        dataStoreCache = LifecycleV2DataStoreCache(dataStore: self.dataStore)
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
            // todo: MOB-14878 create launch application event and if needed the close event
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

            // todo: MOB-14878 create close application event
        }

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
