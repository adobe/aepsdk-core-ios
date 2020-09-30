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

/// Defines a type which fetches configuration from various locations
protocol ConfigurationDownloadable {
    /// Loads the bundled config located at `filePath`.
    /// - Parameter filePath: Path to the config to load
    /// - Returns: The configuration at `filePath`, nil if not found
    func loadConfigFrom(filePath: String) -> [String: Any]?

    /// Loads the default config in the main bundled named `ConfigurationConstants.CONFIG_BUNDLED_FILE_NAME`.
    /// - Returns: The default configuration stored in the manifest, nil if not found
    func loadDefaultConfigFromManifest() -> [String: Any]?

    /// Loads the cached configuration for `appId`.
    /// - Parameters:
    ///   - appId: Optional app id, if provided the `ConfigurationDownloader` will attempt to download a configuration with `appId`
    ///   - dataStore: Optional `NamedCollectionDataStore`, if provided this will be used as the cache for retrieving and storing configurations.
    /// - Returns: The cached configuration for `appId` in `dataStore`, nil if not found
    func loadConfigFromCache(appId: String, dataStore: NamedCollectionDataStore) -> [String: Any]?

    /// Loads the remote configuration for `appId` and caches the result.
    /// - Parameters:
    ///   - appId: Optional app id, if provided the `ConfigurationDownloader` will attempt to download a configuration with `appId`
    ///   - dataStore: Optional `NamedCollectionDataStore`, if provided this will be used as the cache for retrieving and storing configurations.
    ///   - completion: Invoked with the loaded configuration, nil if loading the configuration failed.
    func loadConfigFromUrl(appId: String, dataStore: NamedCollectionDataStore, completion: @escaping ([String: Any]?) -> Void)
}
