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

/// Manages the internal state for the `Configuration` extension
class ConfigurationState {
    let dataStore: NamedCollectionDataStore
    let appIdManager: LaunchIDManager
    let configDownloader: ConfigurationDownloadable
    private var downloadedAppIds = Set<String>() // a set of appIds, if an appId is present then we have downloaded and applied the config
    private let logTag = "ConfigurationState"

    private(set) var currentConfiguration = [String: Any]()
    var environmentAwareConfiguration: [String: Any] {
        return computeEnvironmentConfig(config: currentConfiguration)
    }

    private(set) var programmaticConfigInDataStore: [String: AnyCodable] {
        get {
            if let storedConfig: [String: AnyCodable] = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG) {
                return storedConfig
            } else {
                Log.trace(label: logTag, "Config not found in data store, returning empty config")
                return [:]
            }
        }
        set {
            dataStore.setObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: newValue)
        }
    }

    /// Creates a new `ConfigurationState` with an empty current configuration
    /// - Parameters:
    ///   - dataStore: The datastore in which configurations are cached
    ///   - configDownloader: A `ConfigurationDownloadable` which will be responsible for loading the configuration from various locations
    init(dataStore: NamedCollectionDataStore, configDownloader: ConfigurationDownloadable) {
        self.dataStore = dataStore
        self.configDownloader = configDownloader
        appIdManager = LaunchIDManager(dataStore: dataStore)
    }

    /// Loads the first configuration at launch
    func loadInitialConfig() {
        var config = [String: Any]()

        // Load any existing application ID, either saved in persistence or read from the ADBMobileAppID property in the platform's System Info Service.
        if let appId = appIdManager.loadAppId() {
            config = configDownloader.loadConfigFromCache(appId: appId, dataStore: dataStore)
                ?? configDownloader.loadDefaultConfigFromManifest()
                ?? [:]
        } else {
            Log.trace(label: logTag, "App ID not found, attempting to load default config from manifest")
            config = configDownloader.loadDefaultConfigFromManifest() ?? [:]
        }

        updateWith(newConfig: config)
    }

    /// Merges the current configuration to `newConfig` then applies programmatic configuration on top
    /// - Parameter newConfig: The new configuration
    func updateWith(newConfig: [String: Any]) {
        currentConfiguration.merge(newConfig) { _, updated in updated }

        // Apply any programmatic configuration updates
        currentConfiguration.merge(AnyCodable.toAnyDictionary(dictionary: programmaticConfigInDataStore) ?? [:]) { _, updated in updated }
    }

    /// Updates the programmatic config, then applies these changes to the current configuration
    /// - Parameter programmaticConfig: programmatic configuration to be applied
    func updateWith(programmaticConfig: [String: Any]) {
        // Map any config keys to their correct environment key
        let mappedEnvironmentKeyConfig = mapEnvironmentKeys(programmaticConfig: programmaticConfig)

        // Any existing programmatic configuration updates are retrieved from persistence.
        // New configuration updates are applied over the existing persisted programmatic configurations
        // New programmatic configuration updates are saved to persistence.
        programmaticConfigInDataStore.merge(AnyCodable.from(dictionary: mappedEnvironmentKeyConfig) ?? [:]) { _, updated in updated }

        // The current configuration is updated with these new programmatic configuration changes.
        currentConfiguration.merge(AnyCodable.toAnyDictionary(dictionary: programmaticConfigInDataStore) ?? [:]) { _, updated in updated }
    }

    /// Attempts to download the configuration associated with `appId`, if downloading the remote config fails we check cache for cached config
    /// - Parameter appId: appId associated with the remote config
    /// - Parameter completion: A closure that is invoked with the downloaded config, nil if unable to download config with `appId`
    func updateWith(appId: String, completion: @escaping ([String: Any]?) -> Void) {
        // Save the AppID in persistence for loading configuration on future launches.
        appIdManager.saveAppIdToPersistence(appId: appId)

        // Try to download config from network, if fails try to load from cache
        configDownloader.loadConfigFromUrl(appId: appId, dataStore: dataStore, completion: { [weak self] config in
            if let loadedConfig = config {
                self?.downloadedAppIds.insert(appId)
                self?.replaceConfigurationWith(newConfig: loadedConfig)
            }

            completion(config)
        })
    }

    /// Attempts to load the configuration stored at `filePath`
    /// - Parameter filePath: Path to a configuration file
    /// - Returns: True if the configuration was loaded, false otherwise
    func updateWith(filePath: String) -> Bool {
        guard let bundledConfig = configDownloader.loadConfigFrom(filePath: filePath) else {
            return false
        }

        replaceConfigurationWith(newConfig: bundledConfig)
        return true
    }

    /// Determines if we have already downloaded the configuration associated with `appId`
    /// - Parameter appId: A valid appId
    func hasDownloadedConfig(appId: String) -> Bool {
        return downloadedAppIds.contains(appId)
    }

    /// Replaces `currentConfiguration` with `newConfig` and then applies the existing programmatic configuration on-top
    /// - Parameter newConfig: A configuration to replace the current configuration
    private func replaceConfigurationWith(newConfig: [String: Any]) {
        currentConfiguration = newConfig
        // Apply any programmatic configuration updates
        currentConfiguration.merge(AnyCodable.toAnyDictionary(dictionary: programmaticConfigInDataStore) ?? [:]) { _, updated in updated }
    }

    /// Computes the environment aware configuration based on `config`
    /// - Parameter config: The current configuration
    /// - Returns: A configuration with the correct values for each key given the build environment, while also removing all keys prefix with `ConfigurationConstants.ENVIRONMENT_PREFIX_DELIMITER`
    func computeEnvironmentConfig(config _: [String: Any]) -> [String: Any] {
        // Remove all __env__ keys, only need to process config keys who do not have the environment prefix
        var environmentAwareConfig = currentConfiguration.filter { !$0.key.hasPrefix(ConfigurationConstants.ENVIRONMENT_PREFIX_DELIMITER) }
        guard let buildEnvironment = currentConfiguration[ConfigurationConstants.Keys.BUILD_ENVIRONMENT] as? String else {
            Log.trace(label: logTag, "Build environment not found, returning environment aware config")
            return environmentAwareConfig
        }

        for key in environmentAwareConfig.keys {
            let environmentKey = keyForEnvironment(key: key, environment: buildEnvironment)
            // If a config value for the current build environment exists, replace `key` value with `environmentKey` value
            if let environmentValue = currentConfiguration[environmentKey] {
                environmentAwareConfig[key] = environmentValue
            }
        }

        return environmentAwareConfig
    }

    /// Maps config keys to their respective build environment keys if they exist
    /// - Parameter programmaticConfig: The programmatic config from the user
    /// - Returns: `programmaticConfig` with all keys mapped to their build environment equivalent
    func mapEnvironmentKeys(programmaticConfig: [String: Any]) -> [String: Any] {
        guard let buildEnvironment = currentConfiguration[ConfigurationConstants.Keys.BUILD_ENVIRONMENT] as? String else {
            Log.trace(label: logTag, "")
            return programmaticConfig
        }

        var mappedConfig = [String: Any]()
        for (key, value) in programmaticConfig {
            let environmentKey = keyForEnvironment(key: key, environment: buildEnvironment)
            let keyToUse = currentConfiguration[environmentKey] != nil ? environmentKey : key
            mappedConfig[keyToUse] = value
        }

        return mappedConfig
    }

    /// Formats a configuration key with the build environment prefix
    /// - Parameters:
    ///   - key: configuration key to be prefixed
    ///   - env: the current build environment
    /// - Returns: the configuration key formatted with the build environment prefix
    private func keyForEnvironment(key: String, environment: String) -> String {
        guard !environment.isEmpty else { return key }
        let delimiter = ConfigurationConstants.ENVIRONMENT_PREFIX_DELIMITER
        return "\(delimiter)\(environment)\(delimiter)\(key)"
    }
}
