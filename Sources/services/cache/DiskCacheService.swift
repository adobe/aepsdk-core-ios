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
public class DiskCacheService: CacheService {
    let cachePrefix = "com.adobe.mobile.diskcache"
    let fileManager = FileManager.default
    
    // MARK: CacheService
    
    public func set(cacheName: String, key: String, data: Data?) throws {
        _ = fileManager.createFile(atPath: filePath(for: cacheName, with: key), contents: data, attributes: nil)
    }
    
    public func get(cacheName: String, key: String) throws -> Data? {
        return try Data(contentsOf: URL(fileURLWithPath: filePath(for: cacheName, with: key)))
    }
    
    public func remove(cacheName: String, key: String) throws {
        try fileManager.removeItem(atPath: filePath(for: cacheName, with: key))
    }
    
    public func removeAll(cacheName: String) throws {
        try fileManager.removeItem(atPath: cachePath(for: cacheName))
    }
    
    // MARK: Helpers
    
    /// Builds the file path for the given key
    /// - Parameters:
    ///   - cacheName: name of the cache
    ///   - key: key or file name
    private func filePath(for cacheName: String, with key: String) -> String {
        return "\(cachePath(for: cacheName))/\(key)"
    }
    
    /// Builds the directory path for the cache using the cache prefix and cache name
    /// - Parameter cacheName: name of the cache
    /// - Returns: a string representing the path to the cache for `name`
    private func cachePath(for cacheName: String) -> String {
        let url = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url?.appendingPathComponent("\(cachePrefix).\(cacheName)", isDirectory: true).path ?? ""
    }
    
}
