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

/// Manages the internal state for the `Configuration` extension
class ConfigurationState {
    let dataStore: NamedKeyValueStore
    let appIdManager: AppIDManager
    let configDownloader: ConfigurationDownloadable
    
    private(set) var currentConfiguration = [String: Any]()
    private(set) var programmaticConfig: [String: AnyCodable] {
        set {
            dataStore.setObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG, value: newValue)
        }

        get {
            let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
            return storedConfig ?? [:]
        }
    }
    
    /// Creates a new `ConfigurationState` with an empty current configuration
    /// - Parameters:
    ///   - dataStore: The datastore in which configurations are cached
    ///   - appIdManager: An `AppIDManager` which will manage loading and saving appIds to persistence
    ///   - configDownloader: A `ConfigurationDownloadable` which will be responsible for loading the configuration from various locations
    init(dataStore: NamedKeyValueStore, appIdManager: AppIDManager, configDownloader: ConfigurationDownloadable) {
        self.dataStore = dataStore
        self.appIdManager = appIdManager
        self.configDownloader = configDownloader
    }
    
    /// Loads the first configuration at launch
    func loadInitialConfig() {
        let systemInfoService = AEPServiceProvider.shared.systemInfoService
        var config = [String: Any]()
        
        // Load any existing application ID, either saved in persistence or read from the ADBMobileAppID property in the platform's System Info Service.
        if let appId = appIdManager.loadAppId() {
            config = configDownloader.loadConfigFromCache(appId: appId, dataStore: dataStore)
                        ?? configDownloader.loadDefaultConfigFrom(systemInfoService: systemInfoService)
                        ?? [:]
        } else {
            config = configDownloader.loadDefaultConfigFrom(systemInfoService: systemInfoService) ?? [:]
        }
        
        updateConfigWith(newConfig: config)
    }
    
    /// Merges the current configuration to `newConfig` then applies programmatic configuration on top
    /// - Parameter newConfig: The new configuration
    func updateConfigWith(newConfig: [String: Any]) {
        currentConfiguration.merge(newConfig) { (_, updated) in updated }

        // Apply any programmatic configuration updates
        currentConfiguration.merge(AnyCodable.toAnyDictionary(dictionary: programmaticConfig) ?? [:]) { (_, updated) in updated }
    }
    
    /// Updates the programmatic config, then applies these changes to the current configuration
    /// - Parameter programmaticConfig: programmatic configuration to be applied
    func updateProgrammaticConfig(updatedConfig: [String: Any]) {
        // Any existing programmatic configuration updates are retrieved from persistence.
        // New configuration updates are applied over the existing persisted programmatic configurations
        // New programmatic configuration updates are saved to persistence.
        programmaticConfig.merge(AnyCodable.from(dictionary: updatedConfig) ?? [:]) { (_, updated) in updated }
        
        // The current configuration is updated with these new programmatic configuration changes.
        currentConfiguration.merge(AnyCodable.toAnyDictionary(dictionary: programmaticConfig) ?? [:]) { (_, updated) in updated }
    }
    
    /// Attempts to download the configuration associated with `appId`, if downloading the remote config fails we check cache for cached config
    /// - Parameter appId: appId associated with the remote config
    /// - Returns: True if the configuration was downloaded or if it was loaded from cache, false otherwise
    func updateConfigWith(appId: String, completion: @escaping ([String: Any]?) -> ()) {
        // Save the AppID in persistence for loading configuration on future launches.
        appIdManager.saveAppIdToPersistence(appId: appId)

        // Try to download config from network, if fails try to load from cache
        configDownloader.loadConfigFromUrl(appId: appId, dataStore: dataStore, completion: { [weak self] (config) in
            if let store = self?.dataStore, let loadedConfig = config ?? self?.configDownloader.loadConfigFromCache(appId: appId, dataStore: store) {
                self?.replaceConfigurationWith(newConfig: loadedConfig)
                completion(loadedConfig)
            } else {
                completion(config)
            }
            
        })
    }
    
    /// Attempts to load the configuration stored at `filePath`
    /// - Parameter filePath: Path to a configuration file
    /// - Returns: True if the configuration was loaded, false otherwise
    func updateConfigWith(filePath: String) -> Bool {
         guard let bundledConfig = configDownloader.loadConfigFrom(filePath: filePath) else {
            return false
        }
        
        replaceConfigurationWith(newConfig: bundledConfig)
        return true
    }
    
    /// Replaces `currentConfiguration` with `newConfig` and then applies the existing programmatic configuration on-top
    /// - Parameter newConfig: A configuration to replace the current configuration
    private func replaceConfigurationWith(newConfig: [String: Any]) {
        currentConfiguration = newConfig
        // Apply any programmatic configuration updates
        currentConfiguration.merge(AnyCodable.toAnyDictionary(dictionary: programmaticConfig) ?? [:]) { (_, updated) in updated }
    }
}
