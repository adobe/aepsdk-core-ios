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

/// Provides functionality for migrating keys from c++ V5 to Swift V5
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
    }

    // MARK: - Private APIs

    /// Determine if we need to migrate c++ V5 to Swift V5
    /// - Returns: True if an install date exists in c++ V5 user defaults
    private func defaultsNeedsMigration() -> Bool {
        let installDateKey = keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME,
                                           key: V5MigrationConstants.Lifecycle.INSTALL_DATE)
        return v5Defaults.object(forKey: installDateKey) != nil
    }

    /// Determine if we need to migrate c++ V5 to Swift V5
    /// - Returns: True if a privacy status key exists in the c++ V5 defaults
    private func configNeedsMigration() -> Bool {
        guard let config = getV5OverriddenConfig() else { return false }
        return !config.isEmpty
    }

    /// Gets overridden config from existing c++ V5 implementation
    /// - Returns: an optional dictionary of existing overridden config values
    private func getV5OverriddenConfig() -> [String: Any]? {
        let overriddenConfigKey = keyWithPrefix(datastoreName: V5MigrationConstants.Configuration.LEGACY_DATASTORE_NAME,
                                                key: V5MigrationConstants.Configuration.OVERRIDDEN_CONFIG)
        guard let configJsonData = v5Defaults.string(forKey: overriddenConfigKey)?.data(using: .utf8) else { return nil }
        let config = try? JSONSerialization.jsonObject(with: configJsonData, options: .mutableContainers) as? [String: Any]

        return config
    }

    /// Migrates local storage for each extension
    private func migrateLocalStorage() {
        // Identity
        migrateIdentityLocalStorage()

        // Lifecycle
        migrateLifecycleLocalStorage()
    }

    /// Migrates the c++ V5 Identity values into the Swift V5 Identity data store
    private func migrateIdentityLocalStorage() {
        let ecid = v5Defaults.string(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.ECID))
        let hint = v5Defaults.string(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.HINT))
        let blob = v5Defaults.string(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.BLOB))
        let ids = v5Defaults.string(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.IDS))
        let pushEnabled = v5Defaults.bool(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.PUSH_ENABLED))

        // Build data
        let identityPropsDict: [String: Any?] = [
            "ecid": ["ecidString": ecid],
            "locationHint": hint,
            "blob": blob,
            "customerIds": idParser.convertStringToIds(idString: ids),
            "ttl": 30,
            "privacyStatus": PrivacyStatus.unknown.rawValue
        ]

        // save values
        let identityDataStore = NamedCollectionDataStore(name: V5MigrationConstants.Identity.DATASTORE_NAME)
        let identityPropsData = AnyCodable.from(dictionary: identityPropsDict)
        identityDataStore.setObject(key: V5MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES, value: identityPropsData)
        identityDataStore.set(key: V5MigrationConstants.Identity.DataStoreKeys.PUSH_ENABLED, value: pushEnabled)

        // remove identity values from v5 data store
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.ECID))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.TTL))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.VID))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.HINT))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.BLOB))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.IDS))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.PUSH_ENABLED))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.SYNC_TIME))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Identity.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Identity.PUSH_TOKEN))

        Log.debug(label: LOG_TAG, "Migration complete for Identity data.")
    }

    /// Migrates the c++ V5 Lifecycle values into the Swift V5 Lifecycle data store
    private func migrateLifecycleLocalStorage() {
        let installDateInterval = v5Defaults.double(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.INSTALL_DATE))
        let lastVersion = v5Defaults.string(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LAST_VERSION))
        let lastUsedDateInterval = v5Defaults.double(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LAST_USED_DATE))
        let launches = v5Defaults.integer(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LAUNCHES))
        let successfulClose = v5Defaults.bool(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.SUCCESSFUL_CLOSE))
        let osVersion = v5Defaults.string(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.OS_VERSION))
        let appId = v5Defaults.string(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.APP_ID))

        let lifecycleDataStore = NamedCollectionDataStore(name: V5MigrationConstants.Lifecycle.DATASTORE_NAME)
        lifecycleDataStore.setObject(key: V5MigrationConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, value: Date(timeIntervalSince1970: installDateInterval))
        lifecycleDataStore.set(key: V5MigrationConstants.Lifecycle.DataStoreKeys.LAST_VERSION, value: lastVersion)
        lifecycleDataStore.setObject(key: V5MigrationConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, value: Date(timeIntervalSince1970: lastUsedDateInterval))

        let persistedDict = ["launches": launches, "successfulClose": successfulClose, "osVersion": osVersion, "appId": appId] as [String: Any?]
        let persistedData = AnyCodable.from(dictionary: persistedDict)
        lifecycleDataStore.setObject(key: V5MigrationConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT, value: persistedData)

        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.INSTALL_DATE))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LAST_VERSION))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LAST_USED_DATE))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LAUNCHES))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.SUCCESSFUL_CLOSE))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LIFECYCLE_DATA))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.START_DATE))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.APP_ID))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.OS_VERSION))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.PAUSE_DATE))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.UPGRADE_DATE))
        v5Defaults.removeObject(forKey: keyWithPrefix(datastoreName: V5MigrationConstants.Lifecycle.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Lifecycle.LAUNCHES_AFTER_UPGRADE))

        Log.debug(label: LOG_TAG, "Migration complete for Lifecycle data.")
    }

    /// Migrates the c++ V5 Configuration values into the Swift V5 Configuration data store
    private func migrateConfigurationLocalStorage() {
        var legacyV5OverriddenConfig = AnyCodable.from(dictionary: getV5OverriddenConfig()) ?? [:]
        let configDataStore = NamedCollectionDataStore(name: V5MigrationConstants.Configuration.DATASTORE_NAME)

        // attempt to load existing swift overridden config
        if let overriddenConfig: [String: AnyCodable] = configDataStore.getObject(key: V5MigrationConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG) {
            // if v5 swift overridden config exists, apply it over the existing legacy v5 overridden config
            legacyV5OverriddenConfig = legacyV5OverriddenConfig.merging(overriddenConfig) { (_, new) in new }
        }

        configDataStore.setObject(key: V5MigrationConstants.Configuration.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: legacyV5OverriddenConfig)
        let overriddenConfigKey = keyWithPrefix(datastoreName: V5MigrationConstants.Configuration.LEGACY_DATASTORE_NAME, key: V5MigrationConstants.Configuration.OVERRIDDEN_CONFIG)
        v5Defaults.removeObject(forKey: overriddenConfigKey)
    }

    /// Appends the datastore name and the key to create the key to be used in user defaults
    /// - Parameters:
    ///   - datastoreName: name of the datastore
    ///   - key: key for the value
    /// - Returns: a string representing the prefixed key with the datastore name
    private func keyWithPrefix(datastoreName: String, key: String) -> String {
        return "Adobe.\(datastoreName).\(key)"
    }
}
