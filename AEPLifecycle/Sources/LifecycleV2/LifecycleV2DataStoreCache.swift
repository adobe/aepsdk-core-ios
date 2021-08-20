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

import AEPServices
import Foundation

/// Lifecycle DataStore Cache layer for persisting the date values required for Lifecycle session computation in XDM,
/// including close date to be used for app close time approximation, start and pause dates.
class LifecycleV2DataStoreCache {
    private var closeDate: Date?
    private var lastClosePersistedDate: Date?
    private let dataStore: NamedCollectionDataStore

    init(dataStore: NamedCollectionDataStore) {
        self.dataStore = dataStore
        if let persistedCloseDate = dataStore.getObject(key: LifecycleV2Constants.DataStoreKeys.APP_CLOSE_DATE) as Date? {
            self.closeDate = Date(timeIntervalSince1970: (persistedCloseDate.timeIntervalSince1970) + LifecycleV2Constants.CACHE_TIMEOUT_SECONDS)
        }
    }

    /// The last known close date value to be updated in cache and, if needed, in persistence as well.
    /// The write will execute after `LifecycleConstants.CACHE_TIMEOUT_SECONDS` since last update.
    /// - Parameter date: current date
    func setLastKnownDate(_ date: Date) {
        if (date.timeIntervalSince1970 - (lastClosePersistedDate?.timeIntervalSince1970 ?? 0.0)) >= LifecycleV2Constants.CACHE_TIMEOUT_SECONDS {
            dataStore.setObject(key: LifecycleV2Constants.DataStoreKeys.APP_CLOSE_DATE, value: date)
            lastClosePersistedDate = date
        }
    }

    /// Returns the approximated app close date. This value is loaded from persistence when
    /// `LifeCycleDataStoreCache` is initialized it includes the ` LifecycleConstants.CACHE_TIMEOUT_SECONDS`
    /// the eventuality when the application was closed before the last commit was executed.
    ///
    /// - Returns: the last known close date value or nil if not found, for example on first launch
    func getCloseDate() -> Date? {
        return closeDate
    }

    /// Updates the last app start date in persistence.
    ///
    /// - Parameter date: start date
    func setAppStartDate(_ date: Date) {
        dataStore.setObject(key: LifecycleV2Constants.DataStoreKeys.APP_START_DATE, value: date)
    }

    /// Reads the last app start date from persistence and returns the value.
    ///
    /// - Returns: the app start Date or nil if not found
    func getAppStartDate() -> Date? {
        return dataStore.getObject(key: LifecycleV2Constants.DataStoreKeys.APP_START_DATE)
    }

    /// Updates the last app pause date in persistence.
    ///
    /// - Parameter date: pause date
    func setAppPauseDate(_ date: Date) {
        dataStore.setObject(key: LifecycleV2Constants.DataStoreKeys.APP_PAUSE_DATE, value: date)
    }

    /// Reads the last app pause date from persistence and returns the value.
    ///
    /// - Returns: the app pause date or nil if not found
    func getAppPauseDate() -> Date? {
        return dataStore.getObject(key: LifecycleV2Constants.DataStoreKeys.APP_PAUSE_DATE)
    }
}
