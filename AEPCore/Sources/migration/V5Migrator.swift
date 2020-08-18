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
    private let LOG_TAG = "V4Migrator"
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
        let installDateKey = keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.INSTALL_DATE)
        return v5Defaults.object(forKey: installDateKey) != nil
    }

    /// Determine if we need to migrate V5 to V5
    /// - Returns: True if a privacy status key exists in the V5 defaults
    private func configNeedsMigration() -> Bool {
        guard let config = getV5OverriddenConfig() else { return false }
        return config[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] != nil
    }
    
    private func getV5OverriddenConfig() -> [String: Any]? {
        let overriddenConfigKey = keyWithPrefix(datastoreName: V5MigrationConstants.Configuration.DATASTORE_NAME, key: V5MigrationConstants.Configuration.OVERRIDDEN_CONFIG)
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
        let mid = v4Defaults.string(forKey: V4MigrationConstants.Identity.V4MID)
        let hint = v4Defaults.string(forKey: V4MigrationConstants.Identity.V4Hint)
        let blob = v4Defaults.string(forKey: V4MigrationConstants.Identity.V4Blob)
        let ids = v4Defaults.string(forKey: V4MigrationConstants.Identity.V4Ids)
        let pushEnabled = v4Defaults.bool(forKey: V4MigrationConstants.Identity.V4PushEnabled)

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
        let identityDataStore = NamedCollectionDataStore(name: CoreConstants.Identity.DATASTORE_NAME)
        let identityPropsData = try? JSONSerialization.data(withJSONObject: identityPropsDict)
        identityDataStore.setObject(key: CoreConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES, value: identityPropsData)
        identityDataStore.set(key: CoreConstants.Identity.DataStoreKeys.PUSH_ENABLED, value: pushEnabled)

        // remove identity values from v4 data store
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4MID)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4TTL)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4Vid)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4Hint)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4Blob)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4Ids)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4PushEnabled)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4SyncTime)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Identity.V4PushToken)

        Log.debug(label: LOG_TAG, "Migration complete for Identity data.")
    }

    /// Migrates the v4 Lifecycle values into the v5 Lifecycle data store
    private func migrateLifecycleLocalStorage() {
        let installDate = v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4InstallDate) as? Date
        let lastVersion = v4Defaults.string(forKey: V4MigrationConstants.Lifecycle.V4LastVersion)
        let lastUsedDate = v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4LastUsedDate) as? Date
        let launches = v4Defaults.integer(forKey: V4MigrationConstants.Lifecycle.V4Launches)
        let successfulClose = v4Defaults.bool(forKey: V4MigrationConstants.Lifecycle.V4SuccessfulClose)

        let lifecycleDataStore = NamedCollectionDataStore(name: CoreConstants.Lifecycle.DATASTORE_NAME)
        lifecycleDataStore.setObject(key: CoreConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, value: installDate)
        lifecycleDataStore.set(key: CoreConstants.Lifecycle.DataStoreKeys.LAST_VERSION, value: lastVersion)
        lifecycleDataStore.setObject(key: CoreConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, value: lastUsedDate)

        let persistedDict = ["launches": launches, "successfulClose": successfulClose] as [String: Any]
        let persistedData = try? JSONSerialization.data(withJSONObject: persistedDict)
        lifecycleDataStore.setObject(key: CoreConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT, value: persistedData)

        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4InstallDate)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4LastVersion)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4LastUsedDate)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4Launches)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4SuccessfulClose)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4LifecycleData)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4StartDate)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4ApplicationID)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4OS)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4PauseDate)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4UpgradeDate)
        v4Defaults.removeObject(forKey: V4MigrationConstants.Lifecycle.V4LaunchesAfterUpgrade)

        Log.debug(label: LOG_TAG, "Migration complete for Lifecycle data.")
    }

    /// Migrates the v4 Configuration values into the v5 Configuration data store
    private func migrateConfigurationLocalStorage() {
        let v4PrivacyStatus = v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4PrivacyStatus) as? NSNumber
        if let v4PrivacyStatus = v4PrivacyStatus, v4PrivacyStatus.intValue > 0 && v4PrivacyStatus.intValue < 4 {
            var v5PrivacyStatus = PrivacyStatus.unknown
            switch v4PrivacyStatus {
            case 1:
                v5PrivacyStatus = .optedIn
            case 2:
                v5PrivacyStatus = .optedOut
            default:
                v5PrivacyStatus = .unknown
            }

            let configDataStore = NamedCollectionDataStore(name: CoreConstants.Configuration.DATASTORE_NAME)
            let overriddenConfig: [String: AnyCodable]? = configDataStore.getObject(key: CoreConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)

            if var overriddenConfig = overriddenConfig {
                if let _ = overriddenConfig[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY]?.value as? String {
                    Log.debug(label: LOG_TAG, "V5 Swift configuration data already contains setting for global privacy. Existing V5 global privacy not migrated.")
                } else {
                    overriddenConfig[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] = AnyCodable(v5PrivacyStatus.rawValue)
                    configDataStore.setObject(key: CoreConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: overriddenConfig)
                    Log.debug(label: LOG_TAG, "V5 Swift configuration data did not contain a global privacy. Migrated V5 global privacy with value of \(v5PrivacyStatus.rawValue)")
                }
            } else {
                // no current v5 overridden config, create one with migrated v4 privacy status
                let overriddenConfig: [String: AnyCodable] = [CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY: AnyCodable(v5PrivacyStatus.rawValue)]
                configDataStore.setObject(key: CoreConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: overriddenConfig)
            }
        }

        v4Defaults.removeObject(forKey: V4MigrationConstants.Configuration.V4PrivacyStatus)
    }

    private func migrateVisitorIdLocalStorage() {
        // TOOD: Implement when implementing the Analytics extension
    }

    private func keyWithPrefix(datastoreName: String, key: String) -> String {
        return "Adobe.\(datastoreName).\(key)"
    }
}
