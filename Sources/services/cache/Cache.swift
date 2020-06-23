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

/// Concrete class that provides disk caching capabilities
class Cache {
    private var cacheService: CacheService {
        return AEPServiceProvider.shared.cacheService
    }
    private var name: String
    
    /// Creates a new cache with a specified name
    /// - Parameter name: name of the cache
    init(name: String) {
        self.name = name
    }
    
    /// Sets data in the cache for `key`
    /// - Parameters:
    ///   - key: key where the data should be stored in the cache
    ///   - data: data to be stored in the cache
    func set(key: String, data: Data?) throws {
        try cacheService.set(cacheName: name, key: key, data: data)
    }
    
    /// Gets data from the cache for a given key
    /// - Parameter key: the key to be read from the cache
    /// - Returns: data in the cache if found, nil otherwise
    func get(key: String) throws -> Data? {
        return try cacheService.get(cacheName: name, key: key)
    }
    
    /// Removes a key from the cache
    /// - Parameter key: key to be removed
    func remove(key: String) throws {
        try cacheService.remove(cacheName: name, key: key)
    }
    
    /// Removes all values from the cache
    func removeAll() throws {
        try cacheService.removeAll(cacheName: name)
    }
}
