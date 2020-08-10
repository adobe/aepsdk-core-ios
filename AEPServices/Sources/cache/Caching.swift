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

/// Describes the interface for a data cache
public protocol Caching {
    /// Sets a key value pair in the cache
    /// - Parameters:
    ///   - cacheName: name of the cache
    ///   - key: key for the value
    ///   - entry: entry to be cached
    func set(cacheName: String, key: String, entry: CacheEntry) throws

    /// Gets the value for `key` from the cache with `cacheName`
    /// - Parameters:
    ///   - cacheName: name of the cache
    ///   - key: key to be read from the cache
    /// - Returns: the cache entry, nil if not found
    func get(cacheName: String, key: String) -> CacheEntry?

    /// Removes a key from the cache
    /// - Parameters:
    ///   - cacheName: name of the cache
    ///   - key: key to be removed from the cache
    func remove(cacheName: String, key: String) throws
}
