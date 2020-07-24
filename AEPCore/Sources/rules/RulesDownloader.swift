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
import AdSupport

///
/// The Rules Downloader responsible for loading rules from cache, or downloading the rules remotely
///
struct RulesDownloader: RulesLoader {
    private let loggingService = AEPServiceProvider.shared.loggingService
    private let fileUnzipper: Unzipper
    private let cache: Cache

    init(fileUnzipper: Unzipper) {
        self.fileUnzipper = fileUnzipper
        self.cache = Cache(name: RulesDownloaderConstants.RULES_CACHE_NAME)
    }

    enum RulesDownloaderError: Error {
        case unableToCreateTempDirectory
        case unableToStoreDataInTempDirectory
    }
    
    func loadRulesFromCache(rulesUrl: URL) -> [String : Any]? {
        return AnyCodable.toAnyDictionary(dictionary: getCachedRules(rulesUrl: rulesUrl.absoluteString)?.cacheableDict)
    }
    
    func loadRulesFromUrl(rulesUrl: URL, completion: @escaping ([String: Any]?) -> Void) {

        /// 304 - Not Modified support
        var headers = [String: String]()
        if let cachedRules = getCachedRules(rulesUrl: rulesUrl.absoluteString) {
            headers = cachedRules.notModifiedHeaders()
        }

        let networkRequest = NetworkRequest(url: rulesUrl, httpMethod: .get, httpHeaders: headers)
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { (httpConnection) in
            if let data = httpConnection.data {
                // Store Zip file in temp directory for unzipping
                switch self.storeDataInTempDirectory(data: data) {
                case .success(let url):
                    // Unzip the rules.json from the zip file in the temp directory and get the rules dict from the json file
                    guard let rulesDict = self.unzipRules(at: url) else {
                        completion(nil)
                        return
                    }
                    let cachedRules = CachedRules(cacheableDict: rulesDict,
                                                  lastModified: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.LAST_MODIFIED] as? String,
                                                  eTag: httpConnection.response?.allHeaderFields[NetworkServiceConstants.Headers.ETAG] as? String)
                    // Cache the rules, if fails, log message
                    if !self.setCachedRules(rulesUrl: rulesUrl.absoluteString, cachedRules: cachedRules) {
                        self.loggingService.log(level: .warning, label: "rules downloader", message: "Unable to cache rules")
                    }
                    completion(AnyCodable.toAnyDictionary(dictionary: rulesDict))
                    return
                case .failure(let error):
                    Log.warning(label: "rules downloader", error.localizedDescription)
                    completion(nil)
                    return
                }
            } else if httpConnection.responseCode == 304 {
                completion(AnyCodable.toAnyDictionary(dictionary: self.getCachedRules(rulesUrl: rulesUrl.absoluteString)?.cacheableDict))
                return
            }
            
            completion(nil)
        }
        
    }
    
    ///
    /// Stores the requested rules.zip data in a temp directory
    /// - Parameter data: The rules.zip as data to be stored in the temp directory
    /// - Returns a `Result<URL, RulesDownloaderError>` with a `URL` to the zip file if successful or a `RulesDownloaderError` if a failure occurs
    private func storeDataInTempDirectory(data: Data) -> Result<URL, RulesDownloaderError> {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(RulesDownloaderConstants.RULES_TEMP_DIR)
        do {
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return .failure(.unableToCreateTempDirectory)
        }
        let temporaryDirectoryWithZip = temporaryDirectory.appendingPathComponent(RulesDownloaderConstants.RULES_ZIP_FILE_NAME)
        guard let _ = try? data.write(to: temporaryDirectoryWithZip) else {
            return .failure(.unableToStoreDataInTempDirectory)
        }
        
        return .success(temporaryDirectoryWithZip)
    }
    
    ///
    /// Unzips the rules at the source url to a destination url and returns the rules as a dictionary
    /// - Parameter source: source URL for the zip file
    /// - Returns: The unzipped rules as a dictionary
    private func unzipRules(at source: URL) -> [String: AnyCodable]? {
        let destination = source.deletingLastPathComponent()
        let unzippedItems = fileUnzipper.unzipItem(at: source, to: destination)
        // Should only be one item in the rules zip
        guard let unzippedItemName = unzippedItems.first else { return nil }
        do {
            let data = try Data(contentsOf: destination.appendingPathComponent(unzippedItemName))
            return try JSONDecoder().decode([String: AnyCodable].self, from: data)
        } catch {
            return nil
        }
    }
    
    ///
    /// Builds the cache key from the rules url and the rules cache prefix
    /// - Parameter rulesUrl: The rules url
    /// - Returns: The built cache key for the rules
    private func buildCacheKey(rulesUrl: String) -> String {
        let utf8RulesUrl = rulesUrl.data(using: .utf8)
        guard let base64RulesUrl = utf8RulesUrl?.base64EncodedString() else {
            return RulesDownloaderConstants.Keys.RULES_CACHE_PREFIX + rulesUrl
        }
        
        return RulesDownloaderConstants.Keys.RULES_CACHE_PREFIX + base64RulesUrl
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
            try self.cache.set(key: buildCacheKey(rulesUrl: rulesUrl), entry: cacheEntry)
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
        guard let cachedEntry = cache.get(key: buildCacheKey(rulesUrl: rulesUrl)) else {
            return nil
        }
        return try? JSONDecoder().decode(CachedRules.self, from: cachedEntry.data)
    }

}

