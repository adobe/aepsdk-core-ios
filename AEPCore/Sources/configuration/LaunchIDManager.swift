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

/// Handles loading and saving the launch appId to the data store and manifest
struct LaunchIDManager {
    let dataStore: NamedCollectionDataStore
    private let logTag = "LaunchIDManager"

    /// Loads the appId from the data store, if not present in the data store loads from the manifest
    /// - Returns: appId loaded from persistence or manifest, nil if not present in either
    func loadAppId() -> String? {
        // Prefer appId stored in persistence over in manifest
        return loadAppIdFromPersistence() ?? loadAppIdFromManifest()
    }

    /// Saves the appId to the data store
    /// - Parameter appId: appId to be saved to data store
    func saveAppIdToPersistence(appId: String) {
        if appId.isEmpty {
            Log.trace(label: logTag, "Attempting to set App ID in data store with empty string")
            return
        }
        dataStore.set(key: ConfigurationConstants.DataStoreKeys.PERSISTED_APPID, value: appId)
    }

    /// Removes persisted appId from persistence
    func removeAppIdFromPersistence() {
        dataStore.remove(key: ConfigurationConstants.DataStoreKeys.PERSISTED_APPID)
    }

    /// Loads the appId from the data store
    /// - Returns: appId loaded from persistence, nil if not present
    func loadAppIdFromPersistence() -> String? {
        if let appId = dataStore.getString(key: ConfigurationConstants.DataStoreKeys.PERSISTED_APPID) {
            Log.trace(label: logTag, "Loading App ID from persistence with appId: \(appId)")
            return appId
        }
        Log.trace(label: logTag, "App ID not found in data store")
        return nil
    }

    /// Loads the appId from the manifest
    /// - Returns: appId loaded from the manifest, nil if not present
    func loadAppIdFromManifest() -> String? {
        if let appId = ServiceProvider.shared.systemInfoService.getProperty(for: ConfigurationConstants.CONFIG_MANIFEST_APPID_KEY) {
            saveAppIdToPersistence(appId: appId)
            Log.trace(label: logTag, "Loading App ID from manifest with appId: \(appId)")
            return appId
        }
        Log.trace(label: logTag, "App ID not found in manifest")
        return nil
    }
}
