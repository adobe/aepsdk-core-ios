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

class Cache {
    private var cacheService: CacheService {
        return AEPServiceProvider.shared.cacheService
    }
    private var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func set(key: String, data: Data?) throws {
        try cacheService.set(cacheName: name, key: key, data: data)
    }
    
    func get(key: String) throws -> Data? {
        return try cacheService.get(cacheName: name, key: key)
    }

    func remove(key: String) throws {
        try cacheService.remove(cacheName: name, key: key)
    }

    func removeAll() throws {
        try cacheService.removeAll(cacheName: name)
    }
}
