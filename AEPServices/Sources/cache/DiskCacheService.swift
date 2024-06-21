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

/// Implements a cache which saves and retrieves data from the disk
class DiskCacheService: Caching {
    private let dataStore = NamedCollectionDataStore(name: "DiskCacheService")
    private let cachePrefix = "com.adobe.mobile.diskcache/"
    private let fileManager = FileManager.default
    private let LOG_PREFIX = "DiskCacheService"
    private let EXPIRY_DATE = "expirydate"
    private let METADATA = "metadata"
    private let METADATA_KEY_PATH = "PATH"

    // MARK: Caching

    public func set(cacheName: String, key: String, entry: CacheEntry) throws {
        try createDirectoryIfNeeded(cacheName: cacheName)
        let path = filePath(for: cacheName, with: key)
        _ = fileManager.createFile(atPath: path, contents: entry.data, attributes: nil)

        var newMetadata = [METADATA_KEY_PATH: path]
        if let meta = entry.metadata, !meta.isEmpty {
            newMetadata.merge(meta) { current, _ in current }
        }

        let attributes: [String: Any] = [
            EXPIRY_DATE: entry.expiry.date.timeIntervalSince1970,
            METADATA: newMetadata
        ]
        Log.trace(label: LOG_PREFIX, "Updating cache '\(cacheName)' - setting key '\(key)' to value: \n\(attributes as AnyObject)")
        dataStore.set(key: dataStoreKey(for: cacheName, with: key), value: attributes)
    }

    public func get(cacheName: String, key: String) -> CacheEntry? {
        try? createDirectoryIfNeeded(cacheName: cacheName)
        let path = filePath(for: cacheName, with: key)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        let attributes = dataStore.getDictionary(key: dataStoreKey(for: cacheName, with: key)) as? [String: Any]

        guard let attributes = attributes, let expiryDate = attributes[EXPIRY_DATE] as? Double else {
            // Expiry date attribute is either missing or unreadable, remove from cache
            try? remove(cacheName: cacheName, key: key)
            return nil
        }

        let expiry = CacheExpiry.date(Date(timeIntervalSince1970: expiryDate))
        if expiry.isExpired {
            // item is expired, remove from cache
            try? remove(cacheName: cacheName, key: key)
            return nil
        }

        let meta = attributes[METADATA] as? [String: String]        
        return CacheEntry(data: data, expiry: expiry, metadata: meta)
    }

    public func remove(cacheName: String, key: String) throws {
        let path = filePath(for: cacheName, with: key)
        try fileManager.removeItem(atPath: path)
        Log.trace(label: LOG_PREFIX, "Removing value for key '\(key)' in cache '\(cacheName)'.")
        dataStore.remove(key: path)
    }

    // MARK: Helpers

    /// Creates the directory to store the cache if it does not exist
    /// - Parameter cacheName: name of the cache to be created if needed
    private func createDirectoryIfNeeded(cacheName: String) throws {
        let path = cachePath(for: cacheName)
        guard !fileManager.fileExists(atPath: path) else {
            return
        }

        Log.trace(label: LOG_PREFIX, "Attempting to create directory at path '\(path)'")
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true,
                                        attributes: nil)
    }

    /// Builds the file path for the given key
    /// - Parameters:
    ///   - cacheName: name of the cache
    ///   - key: key or file name
    /// - Returns: the full path for the location of the cache entry
    private func filePath(for cacheName: String, with key: String) -> String {
        return "\(cachePath(for: cacheName.alphanumeric))/\(key.alphanumeric)"
    }

    /// Builds the directory path for the cache using the cache prefix and cache name
    /// - Parameter cacheName: name of the cache
    /// - Returns: a string representing the path to the cache for `name`
    func cachePath(for cacheName: String) -> String {
        let url = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url?.appendingPathComponent("\(cachePrefix)\(cacheName.alphanumeric)", isDirectory: true).path ?? ""
    }

    /// Formats the key for the entry given a cache name and key
    /// - Parameters:
    ///   - cacheName: name of the cache
    ///   - key: key for the entry
    /// - Returns: the key to be used in the datastore for the entry
    func dataStoreKey(for cacheName: String, with key: String) -> String {
        return "\(cacheName.alphanumeric)/\(key.alphanumeric)"
    }
}

/// Used to sanitize cache name and key
private extension String {
    var alphanumeric: String {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).joined().lowercased()
    }
}
