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

/// Responsible for downloading configuration files and caching them
struct ConfigurationDownloader: ConfigurationDownloadable {

    func loadConfigFrom(filePath: String) -> [String: Any]? {
        guard let data = try? String(contentsOfFile: filePath).data(using: .utf8) else { return nil }
        let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: data)
        return AnyCodable.toAnyDictionary(dictionary: decoded)
    }

    func loadDefaultConfigFromManifest() -> [String: Any]? {
        let systemInfoService = AEPServiceProvider.shared.systemInfoService
        guard let data = systemInfoService.getAsset(fileName: ConfigurationConstants.CONFIG_BUNDLED_FILE_NAME, fileType: "json")?.data(using: .utf8) else { return nil }
        let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: data)
        return AnyCodable.toAnyDictionary(dictionary: decoded)
    }

    func loadConfigFromCache(appId: String, dataStore: NamedKeyValueStore) -> [String: Any]? {
        return AnyCodable.toAnyDictionary(dictionary: getCachedConfig(appId: appId, dataStore: dataStore)?.config)
    }

    func loadConfigFromUrl(appId: String, dataStore: NamedKeyValueStore, completion: @escaping ([String: Any]?) -> ()) {
        guard !appId.isEmpty, let url = URL(string: ConfigurationConstants.CONFIG_URL_BASE + appId + ".json") else {
            // error - bad url
            completion(nil)
            return
        }

        // 304, not modified support
        var headers = [String: String]()
        if let cachedConfig = getCachedConfig(appId: appId, dataStore: dataStore) {
            headers[NetworkServiceConstants.Headers.IF_MODIFIED_SINCE_HEADER] = cachedConfig.lastModified
            headers[NetworkServiceConstants.Headers.IF_NONE_MATCH] = cachedConfig.eTag
        }

        let networkRequest = NetworkRequest(url: url, httpMethod: .get, httpHeaders: headers)
        
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { (httpConnection) in
            if let data = httpConnection.data, let configDict = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
                let config = CachedConfiguration(config: configDict,
                                             lastModified: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.LAST_MODIFIED] as? String,
                                      eTag: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.ETAG] as? String)
                
                dataStore.setObject(key: self.buildCacheKey(appId: appId), value: config) // cache config
                completion(AnyCodable.toAnyDictionary(dictionary: config.config))
            } else {
                completion(nil)
            }
            
        }
    }
    
    /// Formats the `appId` into a Adobe namespace key
    /// - Parameter appId: appId to be encoded into the cache key
    private func buildCacheKey(appId: String) -> String {
        return "\(ConfigurationConstants.Keys.CONFIG_CACHE_PREFIX)\(appId)"
    }
    
    /// Retrieves the cached configuration stored for `appId`, if any
    /// - Parameters:
    ///   - appId: The appId of the cached configuration
    ///   - dataStore: The datastore used to cache configurations
    /// Returns: A `CachedConfiguration` for `appId`, nil if not found
    private func getCachedConfig(appId: String, dataStore: NamedKeyValueStore) -> CachedConfiguration? {
        let config: CachedConfiguration? = dataStore.getObject(key: buildCacheKey(appId: appId))
        return config
    }

}
