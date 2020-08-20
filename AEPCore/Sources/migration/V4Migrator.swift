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

/// A type which provides functionality for migrating keys from V4 to V5
struct V4Migrator {
    private let LOG_TAG = "V4Migrator"
    private var v4Defaults: UserDefaults {
        if let v4AppGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup(), !v4AppGroup.isEmpty {
            return UserDefaults(suiteName: v4AppGroup) ?? UserDefaults.standard
        }

        return UserDefaults.standard
    }

    let idParser: IDParsing

    /// Migrates the V4 datastore into V5 datastore
    func migrate() {
        if defaultsNeedsMigration() {
            Log.debug(label: LOG_TAG, "Migrating Adobe SDK v4 NSUserDefaults for use with Adobe SDK v5.")
            migrateLocalStorage()
            migrateConfigurationLocalStorage()
            Log.debug(label: LOG_TAG, "Full migration of NSUserDefaults successful.")
        } else if configNeedsMigration() {
            Log.debug(label: LOG_TAG, "Migrating Adobe SDK v4 Configuration NSUserDefaults for use with Adobe SDK v5.")
            migrateConfigurationLocalStorage()
            Log.debug(label: LOG_TAG, "Full migration of NSUserDefaults successful.")
        }

        if visitorIdNeedsMigration() {
            Log.debug(label: LOG_TAG, "Migrating Adobe SDK v4 Identity to Analytics NSUserDefaults for use with Adobe SDK v5.")
            migrateVisitorIdLocalStorage()
            Log.debug(label: LOG_TAG, "Full migration of Identity to Analytics NSUserDefaults successful.")
        }
    }

    // MARK: Private APIs

    /// Determine if we need to migrate V4 to V5
    /// - Returns: True if an install date exists in V4 user defaults, false otherwise
    private func defaultsNeedsMigration() -> Bool {
        return v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4InstallDate) != nil
    }

    /// Determine if we need to migrate V4 to V5
    /// - Returns: True if a privacy status key exists in the V4 defaults
    private func configNeedsMigration() -> Bool {
        return v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4PrivacyStatus) != nil
    }

    /// Determine whether we need to migrate vid from Identity to Analytics
    /// - Returns: True if we need to migrate the vid from Identity to Analytics
    private func visitorIdNeedsMigration() -> Bool {
        // TOOD: Implement when implementing the Analytics extension
        return false
    }

    private func migrateLocalStorage() {
        // Mobile Services
        migrateMobileServicesLocalStorage()

        // Identity
        migrateIdentityLocalStorage()

        // Lifecycle
        migrateLifecycleLocalStorage()

        // TODO: Target
        // TODO: Acquisition
        // TODO: Analytics
        // TODO: Audience Manager
    }

    /// Migrates the v4 Mobile Services values into the v5 Mobile Services data store
    private func migrateMobileServicesLocalStorage() {
        let acquisitionDataMap = v4Defaults.object(forKey: V4MigrationConstants.MobileServices.V4AcquisitionData) as? [String: String]
        let installDate = v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4InstallDate) as? Date
        let excludeList = v4Defaults.object(forKey: V4MigrationConstants.MobileServices.V4InAppExcludeList) as? [String: Int]

        let mobileServicesDataStore = NamedCollectionDataStore(name: V4MigrationConstants.MobileServices.DATASTORE_NAME)
        mobileServicesDataStore.setObject(key: V4MigrationConstants.MobileServices.V5AcquisitionData, value: acquisitionDataMap)
        mobileServicesDataStore.setObject(key: V4MigrationConstants.MobileServices.install, value: installDate)
        mobileServicesDataStore.setObject(key: V4MigrationConstants.MobileServices.installSearchAd, value: installDate)
        mobileServicesDataStore.setObject(key: V4MigrationConstants.MobileServices.V5InAppExcludeList, value: excludeList)

        v4Defaults.removeObject(forKey: V4MigrationConstants.MobileServices.V4AcquisitionData) // should be removed after acquisition migration
        v4Defaults.removeObject(forKey: V4MigrationConstants.MobileServices.V4InAppExcludeList)

        Log.debug(label: LOG_TAG, "Migration complete for Mobile Services data.")
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
        let identityDataStore = NamedCollectionDataStore(name: V4MigrationConstants.Identity.DATASTORE_NAME)
        let identityPropsData = try? JSONSerialization.data(withJSONObject: identityPropsDict)
        identityDataStore.setObject(key: V4MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES, value: identityPropsData)
        identityDataStore.set(key: V4MigrationConstants.Identity.DataStoreKeys.PUSH_ENABLED, value: pushEnabled)

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

        let lifecycleDataStore = NamedCollectionDataStore(name: V4MigrationConstants.Lifecycle.DATASTORE_NAME)
        lifecycleDataStore.setObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, value: installDate)
        lifecycleDataStore.set(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_VERSION, value: lastVersion)
        lifecycleDataStore.setObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, value: lastUsedDate)

        let persistedDict = ["launches": launches, "successfulClose": successfulClose] as [String: Any]
        let persistedData = try? JSONSerialization.data(withJSONObject: persistedDict)
        lifecycleDataStore.setObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT, value: persistedData)

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

            let configDataStore = NamedCollectionDataStore(name: V4MigrationConstants.Configuration.DATASTORE_NAME)
            let overriddenConfig: [String: AnyCodable]? = configDataStore.getObject(key: V4MigrationConstants.Configuration.V5OverriddenConfig)

            if var overriddenConfig = overriddenConfig {
                if let _ = overriddenConfig[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY]?.value as? String {
                    Log.debug(label: LOG_TAG, "V5 configuration data already contains setting for global privacy. V4 global privacy not migrated.")
                } else {
                    overriddenConfig[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] = AnyCodable(v5PrivacyStatus.rawValue)
                    configDataStore.setObject(key: V4MigrationConstants.Configuration.V5OverriddenConfig, value: overriddenConfig)
                    Log.debug(label: LOG_TAG, "V5 configuration data did not contain a global privacy. Migrated V4 global privacy with value of \(v5PrivacyStatus.rawValue)")
                }
            } else {
                // no current v5 overridden config, create one with migrated v4 privacy status
                let overriddenConfig: [String: AnyCodable] = [CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY: AnyCodable(v5PrivacyStatus.rawValue)]
                configDataStore.setObject(key: V4MigrationConstants.Configuration.V5OverriddenConfig, value: overriddenConfig)
            }
        }

        v4Defaults.removeObject(forKey: V4MigrationConstants.Configuration.V4PrivacyStatus)
    }

    private func migrateVisitorIdLocalStorage() {
        // TOOD: Implement when implementing the Analytics extension
    }

}
