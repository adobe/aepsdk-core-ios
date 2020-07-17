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

///
/// Represents a Cached rules type which has some additional metadata on top of the rules
///
struct CachedRules: Codable {
    
    /// The rules dictionary
    let rules: [String: AnyCodable]
    
    let lastModified: String?
    
    let eTag: String?
}

///
/// Defines a type which can load rules from cache, or download the rules remotely
///
protocol RulesLoader {
    /// Loads the cached rules for `appId`.
    /// - Parameter rulesUrl: rulesUrl string, if provided the `RulesDownloader` will attempt to load a rules with `appId`
    /// - Returns: The cached rules for `appId` in `DiskCache`, nil if not found
    func loadRulesFromCache(rulesUrl: String) -> [String : Any]?
    
    /// Loads the remote rules for `appId` and caches the result.
    /// - Parameters:
    ///   - appId: Optional app id, if provided the `RulesDownloader` will attempt to download rules with `appId`
    ///   - completion: Invoked with the loaded rules, nil if loading the rules failed. NOTE: Fails if 304 not-modified is returned from the server
    func loadRulesFromUrl(rulesUrl: URL, completion: @escaping ([String: Any]?) -> Void)
}

///
/// The Rules Downloader responsible for loading rules from cache, or downloading the rules remotely
///
struct RulesDownloader: RulesLoader {
    let cacheService = AEPServiceProvider.shared.cacheService
    
    enum RulesDownloaderError: Error {
        case unableToCreateTempDirectory
        case unableToStoreDataInTempDirectory
    }
    
    func loadRulesFromCache(rulesUrl: String) -> [String : Any]? {
        return AnyCodable.toAnyDictionary(dictionary: getCachedRules(rulesUrl: rulesUrl)?.rules)
    }
    
    func loadRulesFromUrl(rulesUrl: URL, completion: @escaping ([String: Any]?) -> Void) {

        /// 304 - Not Modified support
        var headers = [String: String]()
        if let cachedRules = getCachedRules(rulesUrl: rulesUrl.absoluteString) {
            headers[NetworkServiceConstants.Headers.IF_MODIFIED_SINCE_HEADER] = cachedRules.lastModified
            headers[NetworkServiceConstants.Headers.IF_NONE_MATCH] = cachedRules.eTag
        }
        
        let networkRequest = NetworkRequest(url: rulesUrl, httpMethod: .get, httpHeaders: headers)
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { (httpConnection) in
            if let data = httpConnection.data {
                switch self.storeDataInTempDirectory(data: data) {
                case .success(let url):
                    let destinationURL = url.deletingLastPathComponent()
                    if let rulesDict = self.unzipRules(at: url, to: destinationURL) {
                        let cachedRules = CachedRules(rules: rulesDict,
                                                      lastModified: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.LAST_MODIFIED] as? String,
                                                      eTag: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.ETAG] as? String)
                        if self.setCachedRules(rulesUrl: rulesUrl.absoluteString, cachedRules: cachedRules) {
                            completion(AnyCodable.toAnyDictionary(dictionary: rulesDict))
                        } else {
                            // TODO: - Log error setting cached rules here
                            completion(nil)
                        }
                    }
                case .failure(_):
                    // TODO: - Log error here
                    completion(nil)
                }
            } else if httpConnection.responseCode == 304 {
                completion(AnyCodable.toAnyDictionary(dictionary: self.getCachedRules(rulesUrl: rulesUrl.absoluteString)?.rules))
            }
        }
        
    }
    
    ///
    /// Stores the requested rules.zip data in a temp directory
    /// - Parameter data: The rules.zip as data to be stored in the temp directory
    /// - Returns a `Result<URL, RulesDownloaderError>` with a `URL` to the zip file if successful or a `RulesDownloaderError` if a failure occurs
    private func storeDataInTempDirectory(data: Data) -> Result<URL, RulesDownloaderError> {
        guard let temporaryDirectory = try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            return .failure(.unableToCreateTempDirectory)
        }
        guard let _ = try? data.write(to: temporaryDirectory.appendingPathComponent(RulesConstants.RULES_ZIP_FILE_NAME.rawValue)) else {
            return .failure(.unableToStoreDataInTempDirectory)
        }
        
        return .success(temporaryDirectory)
    }
    
    ///
    /// Unzips the rules at the source url to a destination url and returns the rules as a dictionary
    /// - Parameters:
    ///     - source: source URL for the zip file
    ///     - destination: The destination url where the unzipped rules will go
    /// - Returns: The unzipped rules as a dictionary
    private func unzipRules(at source: URL, to destination: URL) -> [String: AnyCodable]? {
        let fileUnzipper = FileUnzipper()
        if fileUnzipper.unzipItem(at: source, to: destination) {
            do {
                let data = try Data(contentsOf: destination, options: .mappedIfSafe)
                return try JSONDecoder().decode([String: AnyCodable].self, from: data)
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    ///
    /// Builds the cache key from the rules url and the rules cache prefix
    /// - Parameter rulesUrl: The rules url
    /// - Returns: The built cache key for the rules
    private func buildCacheKey(rulesUrl: String) -> String {
        return RulesConstants.Keys.RULES_CACHE_PREFIX.rawValue + rulesUrl
    }
   
    ///
    /// Caches the given rules
    /// - Parameters:
    ///     - rulesUrl: The rules url string to be used for building the key
    ///     - cachedRules: The `CachedRules` to be set in cache
    /// - Returns: A boolean indicating if caching succeeded or not
    private func setCachedRules(rulesUrl: String, cachedRules: CachedRules) -> Bool {
        do {
            let data = try JSONEncoder().encode(cachedRules)
            let cacheEntry = CacheEntry(data: data, expiry: .never, metadata: nil)
            try self.cacheService.set(cacheName: RulesConstants.RULES_CACHE_NAME.rawValue, key: buildCacheKey(rulesUrl: rulesUrl), entry: cacheEntry)
            return true
        } catch {
            // Handle Error
            return false
        }
    }
    
    ///
    /// Gets the cached rules for the given rulesUrl
    /// - Parameter rulesUrl: The rules url as a string to be used to get the right cached rules
    /// - Returns: The `CachedRules` for the given rulesUrl
    private func getCachedRules(rulesUrl: String) -> CachedRules? {
        guard let cachedEntry = cacheService.get(cacheName: RulesConstants.RULES_CACHE_NAME.rawValue, key: buildCacheKey(rulesUrl: rulesUrl)) else {
            return nil
        }
        return try? JSONDecoder().decode(CachedRules.self, from: cachedEntry.data)
    }

}

enum RulesConstants: String {
    
    case RULES_CACHE_NAME = "rules.cache"

    case RULES_ZIP_FILE_NAME = "rules.zip"
    
    enum Keys: String {
        case RULES_CACHE_PREFIX = "cached.rules"
    }
}
