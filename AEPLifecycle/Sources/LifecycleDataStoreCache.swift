/*
 <<<<<<< HEAD
  Copyright 2021 Adobe. All rights reserved.
 =======
  Copyright 2020 Adobe. All rights reserved.
 >>>>>>> 74186683882ddf128618225e28aac9c4e0f49aed
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

/// Lifecycle DataStore Cache layer for persisting the timestamp values required for Lifecycle session computation in XDM,
/// including close timestamp to be used for app close time approximation, start and pause timestamps.
class LifecycleDataStoreCache {

    static let LOG_TAG = "LifecycleDataStoreCache"
    private var closeTimestampSec = TimeInterval()
    private var lastClosePersistedTimestampSec = TimeInterval()
    private(set) var dataStore: NamedCollectionDataStore

    init(dataStore: NamedCollectionDataStore) {
        self.dataStore = dataStore
        self.lastClosePersistedTimestampSec = dataStore.getDouble(key: LifecycleConstants.DataStoreKeys.APP_CLOSE_TIMESTAMP_SEC) ?? TimeInterval()
        if lastClosePersistedTimestampSec > TimeInterval() {
            self.closeTimestampSec = lastClosePersistedTimestampSec + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        }
    }

    /// The last known close timestamp value to be updated in cache and, if needed, in persistence as well.
    /// The write will execute after `LifecycleConstants.CACHE_TIMEOUT_SECONDS` since last update.
    /// - Parameter ts: current timestamp (seconds)
    func setLastKnownTimestamp(ts: TimeInterval) {
        if (ts - lastClosePersistedTimestampSec) >= TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS) {
            dataStore.set(key: LifecycleConstants.DataStoreKeys.APP_CLOSE_TIMESTAMP_SEC, value: ts)
            lastClosePersistedTimestampSec = ts
        }
    }

    /// Returns the approximated app close timestamp in seconds. This value is loaded from persistence when
    /// `LifeCycleDataStoreCache` is initialized it includes the ` LifecycleConstants.CACHE_TIMEOUT_SECONDS`
    /// the eventuality when the application was closed before the last commit was executed.
    ///
    /// - Returns: the last known close timestamp value or 0.0 if not found, for example on first launch
    func getCloseTimestampSec() -> TimeInterval {
        return closeTimestampSec
    }

    /// Updates the last app start timestamp in persistence.
    ///
    /// - Parameter ts: start timestamp (seconds)
    func setAppStartTimestamp(ts: TimeInterval) {
        dataStore.set(key: LifecycleConstants.DataStoreKeys.APP_START_TIMESTAMP_SEC, value: ts)
    }

    /// Reads the last app start timestamp from persistence and returns the value.
    ///
    /// - Returns: the app start timestamp (seconds) or 0.0 if not found
    func getAppStartTimestampSec() -> TimeInterval {
        return dataStore.getDouble(key: LifecycleConstants.DataStoreKeys.APP_START_TIMESTAMP_SEC) ?? TimeInterval()
    }

    /// Updates the last app pause timestamp in persistence.
    ///
    /// - Parameter ts: pause timestamp (seconds)
    func setAppPauseTimestamp(ts: TimeInterval) {
        dataStore.set(key: LifecycleConstants.DataStoreKeys.APP_PAUSE_TIMESTAMP_SEC, value: ts)
    }

    /// Reads the last app pause timestamp from persistence and returns the value.
    ///
    /// - Returns: the app pause timestamp (seconds) or 0.0 if not found
    func getAppPauseTimestampSec() -> TimeInterval {
        return dataStore.getDouble(key: LifecycleConstants.DataStoreKeys.APP_PAUSE_TIMESTAMP_SEC) ?? TimeInterval()
    }
}
