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

/// Responsible for downloading configuration files and caching them
struct ConfigurationDownloader: ConfigurationDownloadable {

    private let logTag = "ConfigurationDownloader"

    /// Retrieves a configuration Dictionary from the provided `filePath`
    /// If the provided `filePath` is invalid or if does not contain valid JSON, `nil` is returned.
    /// - Parameter filePath: A String representing the path to a file containing an SDK configuration
    /// - Returns: An optional Dictionary containing an SDK configuration
    func loadConfigFrom(filePath: String) -> [String: Any]? {
        guard let data = try? String(contentsOfFile: filePath).data(using: .utf8) else {
            Log.error(label: logTag, "Failed to load config from file path: \(filePath)")
            return nil
        }
        let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: data)
        return AnyCodable.toAnyDictionary(dictionary: decoded)
    }

    /// Retrieves a configuration Dictionary from the bundle
    /// Tries to read the file named `ADBMobileConfig.json` to retrieve the configuration.
    /// If there is no bundled file named `ADBMobileConfig.json`, this method returns `nil`.
    /// - Returns: An optional Dictionary containing an SDK configuration
    func loadDefaultConfigFromManifest() -> [String: Any]? {
        let systemInfoService = ServiceProvider.shared.systemInfoService
        guard let data = systemInfoService.getAsset(fileName: ConfigurationConstants.CONFIG_BUNDLED_FILE_NAME, fileType: "json")?.data(using: .utf8) else {
            Log.error(label: logTag, "Loading config from manifest failed")
            return nil
        }
        let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: data)
        return AnyCodable.toAnyDictionary(dictionary: decoded)
    }

    /// Retrieves a configuration Dictionary that has been previously stored to disk by the SDK
    /// If no cached configuration for the provided `appId` can be found in the `dataStore`, this method returns `nil`.
    /// - Parameters:
    ///   - appId: A String representing the application identifier as provided by Adobe Launch
    ///   - dataStore: The `NamedCollectionDataStore` where the cache is located
    /// - Returns: An optional Dictionary containing an SDK configuration
    func loadConfigFromCache(appId: String, dataStore: NamedCollectionDataStore) -> [String: Any]? {
        return AnyCodable.toAnyDictionary(dictionary: getCachedConfig(appId: appId, dataStore: dataStore)?.cacheable)
    }

    /// Retrieves a configuration Dictionary from Adobe Launch servers
    /// This method does a conditional GET from the Adobe Launch servers to retrieve remote configuration for the
    /// provided `appId`. The underlying network call is asynchronous and the `completion` method will be invoked
    /// with the remote configuration upon receipt and processing of the response. If an error occurs while processing
    /// the response from Launch, `nil` will be passed in `completion`.
    /// - Parameters:
    ///   - appId: A String representing the application identifier as provided by Adobe Launch
    ///   - dataStore: The `NamedCollectionDataStore` where previous responses from the Adobe server is cached
    ///   - completion: A closure that accepts an optional Dictionary containing configuration information.
    func loadConfigFromUrl(appId: String, dataStore: NamedCollectionDataStore, completion: @escaping ([String: Any]?) -> Void) {
        guard !appId.isEmpty, let url = URL(string: ConfigurationConstants.CONFIG_URL_BASE + appId + ".json") else {
            Log.error(label: logTag, "Failed to load config from URL: \(ConfigurationConstants.CONFIG_URL_BASE + appId + ".json")")
            completion(nil)
            return
        }

        // 304, not modified support
        var headers = [String: String]()
        if let cachedConfig = getCachedConfig(appId: appId, dataStore: dataStore) {
            headers = cachedConfig.notModifiedHeaders()
        }

        let networkRequest = NetworkRequest(url: url, httpMethod: .get, httpHeaders: headers)

        ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { httpConnection in
            // If we get a 304 back, we can use the config in cache and exit early
            if httpConnection.responseCode == 304 {
                completion(AnyCodable.toAnyDictionary(dictionary: self.getCachedConfig(appId: appId, dataStore: dataStore)?.cacheable))
                return
            }

            if let data = httpConnection.data, let configDict = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
                let config = CachedConfiguration(cacheable: configDict,
                                                 lastModified: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.LAST_MODIFIED] as? String,
                                                 eTag: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.ETAG] as? String)

                dataStore.setObject(key: self.buildCacheKey(appId: appId), value: config) // cache config
                completion(AnyCodable.toAnyDictionary(dictionary: config.cacheable))
            } else {
                Log.error(label: self.logTag, "Loading config from URL \(url.absoluteString) failed with response code: \(httpConnection.responseCode as Int?)")
                completion(nil)
            }
        }
    }

    /// Formats the `appId` into a Adobe namespace key
    /// - Parameter appId: appId to be encoded into the cache key
    private func buildCacheKey(appId: String) -> String {
        return "\(ConfigurationConstants.DataStoreKeys.CONFIG_CACHE_PREFIX)\(appId)"
    }

    /// Retrieves the cached configuration stored for `appId`, if any
    /// This method returns `nil` if a cached configuration cannot be found for the provided `appId`.
    /// - Parameters:
    ///   - appId: The appId of the cached configuration
    ///   - dataStore: The datastore used to cache configurations
    /// Returns: An optional `CachedConfiguration` for the provided `appId`
    private func getCachedConfig(appId: String, dataStore: NamedCollectionDataStore) -> CachedConfiguration? {
        let config: CachedConfiguration? = dataStore.getObject(key: buildCacheKey(appId: appId))
        return config
    }
}
