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

/// A type which provides functionality for migrating keys from V5 to V5
struct V5Migrator {
    private let LOG_TAG = "V5Migrator"
    let idParser: IDParsing

    private var v5Defaults: UserDefaults {
        if let v5AppGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup(), !v5AppGroup.isEmpty {
            return UserDefaults(suiteName: v5AppGroup) ?? UserDefaults.standard
        }

        return UserDefaults.standard
    }

    /// Migrates the V5 datastore into V5 Swift datastore
    func migrate() {
        if defaultsNeedsMigration() {
            Log.debug(label: LOG_TAG, "Migrating Adobe SDK v5 NSUserDefaults for use with Adobe SDK Swift v5.")
            migrateLocalStorage()
            migrateConfigurationLocalStorage()
            Log.debug(label: LOG_TAG, "Full migration of NSUserDefaults successful.")
        } else if configNeedsMigration() {
            Log.debug(label: LOG_TAG, "Migrating Adobe SDK v5 Configuration NSUserDefaults for use with Adobe SDK Swift v5.")
            migrateConfigurationLocalStorage()
            Log.debug(label: LOG_TAG, "Full migration of NSUserDefaults successful.")
        }

        if visitorIdNeedsMigration() {
            Log.debug(label: LOG_TAG, "Migrating Adobe SDK v5 Identity to Analytics NSUserDefaults for use with Adobe SDK Swift v5.")
            migrateVisitorIdLocalStorage()
            Log.debug(label: LOG_TAG, "Full migration of Identity to Analytics NSUserDefaults successful.")
        }
    }

    // MARK: Private APIs

    /// Determine if we need to migrate V5 to V5
    /// - Returns: True if an install date exists in V5 user defaults, false otherwise
    private func defaultsNeedsMigration() -> Bool {
        let installDateKey = keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.InstallDate)
        return v5Defaults.object(forKey: installDateKey) != nil
    }

    /// Determine if we need to migrate V5 to V5
    /// - Returns: True if a privacy status key exists in the V5 defaults
    private func configNeedsMigration() -> Bool {
        guard let config = getV5OverriddenConfig() else { return false }
        return config[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] != nil
    }

    private func getV5OverriddenConfig() -> [String: Any]? {
        let overriddenConfigKey = keyWithPrefix(V5MigrationConstants.Configuration.DATASTORE_NAME, V5MigrationConstants.Configuration.OVERRIDDEN_CONFIG)
        guard let configJsonData = v5Defaults.string(forKey: overriddenConfigKey)?.data(using: .utf8) else { return nil }
        let config = try? JSONSerialization.jsonObject(with: configJsonData, options: .mutableContainers) as? [String: Any]

        return config
    }

    /// Determine whether we need to migrate vid from Identity to Analytics
    /// - Returns: True if we need to migrate the vid from Identity to Analytics
    private func visitorIdNeedsMigration() -> Bool {
        // TOOD: Implement when implementing the Analytics extension
        return false
    }

    private func migrateLocalStorage() {
        // Identity
        migrateIdentityLocalStorage()

        // Lifecycle
        migrateLifecycleLocalStorage()

        // TODO: Target
        // TODO: Acquisition
        // TODO: Analytics
        // TODO: Audience Manager
    }

    /// Migrates the v4 Identity values into the v5 Identity data store
    private func migrateIdentityLocalStorage() {
        let mid = v5Defaults.string(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.MID))
        let hint = v5Defaults.string(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.Hint))
        let blob = v5Defaults.string(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.Blob))
        let ids = v5Defaults.string(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.Ids))
        let pushEnabled = v5Defaults.bool(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.PushEnabled))

        // Build data
        let identityPropsDict: [String: Any?] = [
            "mid": ["midString": mid],
            "locationHint": hint,
            "blob": blob,
            "customerIds": idParser.convertStringToIds(idString: ids),
            "ttl": 30,
            "privacyStatus": PrivacyStatus.unknown.rawValue
        ]

        // save values
        let identityDataStore = NamedCollectionDataStore(name: V5MigrationConstants.Identity.DATASTORE_NAME)
        let identityPropsData = try? JSONSerialization.data(withJSONObject: identityPropsDict)
        identityDataStore.setObject(key: V5MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES, value: identityPropsData)
        identityDataStore.set(key: V5MigrationConstants.Identity.DataStoreKeys.PUSH_ENABLED, value: pushEnabled)

        // remove identity values from v5 data store
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.MID))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.TTL))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.VID))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.Hint))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.Blob))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.Ids))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.PushEnabled))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.SyncTime))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Identity.DATASTORE_NAME, V5MigrationConstants.Identity.PushToken))

        Log.debug(label: LOG_TAG, "Migration complete for Identity data.")
    }

    /// Migrates the v5 Lifecycle values into the v5 Lifecycle data store
    private func migrateLifecycleLocalStorage() {
        let installDateInterval = v5Defaults.double(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.InstallDate))
        let lastVersion = v5Defaults.string(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.LastVersion))
        let lastUsedDateInterval = v5Defaults.double(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.LastUsedDate))
        let launches = v5Defaults.integer(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.Launches))
        let successfulClose = v5Defaults.bool(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.SuccessfulClose))

        let lifecycleDataStore = NamedCollectionDataStore(name: V5MigrationConstants.Lifecycle.DATASTORE_NAME)
        lifecycleDataStore.setObject(key: V5MigrationConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, value: Date(timeIntervalSince1970: installDateInterval))
        lifecycleDataStore.set(key: V5MigrationConstants.Lifecycle.DataStoreKeys.LAST_VERSION, value: lastVersion)
        lifecycleDataStore.setObject(key: V5MigrationConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, value: Date(timeIntervalSince1970: lastUsedDateInterval))

        let persistedDict = ["launches": launches, "successfulClose": successfulClose] as [String: Any]
        let persistedData = try? JSONSerialization.data(withJSONObject: persistedDict)
        lifecycleDataStore.setObject(key: V5MigrationConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT, value: persistedData)

        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.InstallDate))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.LastVersion))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.LastUsedDate))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.Launches))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.SuccessfulClose))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.LifecycleData))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.StartDate))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.AppId))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.OsVersion))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.PauseDate))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.UpgradeDate))
        v5Defaults.removeObject(forKey: keyWithPrefix(V5MigrationConstants.Lifecycle.DATASTORE_NAME, V5MigrationConstants.Lifecycle.LaunchesAfterUpgrade))

        Log.debug(label: LOG_TAG, "Migration complete for Lifecycle data.")
    }

    /// Migrates the v5 Configuration values into the v5 Configuration data store
    private func migrateConfigurationLocalStorage() {
        let v5OverridenConfig = getV5OverriddenConfig()
        if let existingPrivacyStatus = v5OverridenConfig?[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? String, let v5PrivacyStatus = PrivacyStatus(rawValue: existingPrivacyStatus) {

            let configDataStore = NamedCollectionDataStore(name: V5MigrationConstants.Configuration.DATASTORE_NAME)
            let overriddenConfig: [String: AnyCodable]? = configDataStore.getObject(key: V5MigrationConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)

            if var overriddenConfig = overriddenConfig {
                if let _ = overriddenConfig[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY]?.value as? String {
                    Log.debug(label: LOG_TAG, "V5 Swift configuration data already contains setting for global privacy. Existing V5 global privacy not migrated.")
                } else {
                    overriddenConfig[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] = AnyCodable(v5PrivacyStatus.rawValue)
                    configDataStore.setObject(key: V5MigrationConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: overriddenConfig)
                    Log.debug(label: LOG_TAG, "V5 Swift configuration data did not contain a global privacy. Migrated V5 global privacy with value of \(v5PrivacyStatus.rawValue)")
                }
            } else {
                // no current v5 overridden config, create one with migrated v5 privacy status
                let overriddenConfig: [String: AnyCodable] = [CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY: AnyCodable(v5PrivacyStatus.rawValue)]
                configDataStore.setObject(key: V5MigrationConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: overriddenConfig)
            }
        }

        let overriddenConfigKey = keyWithPrefix(V5MigrationConstants.Configuration.DATASTORE_NAME, V5MigrationConstants.Configuration.OVERRIDDEN_CONFIG)
        v5Defaults.removeObject(forKey: overriddenConfigKey)
    }

    private func migrateVisitorIdLocalStorage() {
        // TOOD: Implement when implementing the Analytics extension
    }

    /// Appends the datastore name and the key to create the key to be used in user defaults
    /// - Parameters:
    ///   - datastoreName: name of the datastore
    ///   - key: key for the value
    /// - Returns: a string representing the prefixed key with the datastore name
    private func keyWithPrefix(_ datastoreName: String, _ key: String) -> String {
        return "Adobe.\(datastoreName).\(key)"
    }
}
