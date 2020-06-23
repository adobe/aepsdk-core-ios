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

public class DiskCache: CacheService {
    let cachePrefix = "com.adobe.mobile.diskcache"
    let fileManager = FileManager.default
    
    // MARK: Cache
    
    public func set(cacheName: String, key: String, data: Data?) throws {
        guard let filePath = filePath(for: cacheName, with: key) else { return }
        _ = fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
    }
    
    public func get(cacheName: String, key: String) throws -> Data? {
        guard let filePath = filePath(for: cacheName, with: key) else { return nil }
        return try Data(contentsOf: URL(fileURLWithPath: filePath))
    }
    
    public func remove(cacheName: String, key: String) throws {
        guard let filePath = filePath(for: cacheName, with: key) else { return }
        try fileManager.removeItem(atPath: filePath)
    }
    
    public func removeAll(cacheName: String) throws {
        guard let cachePath = cachePath(for: cacheName) else { return }
        try fileManager.removeItem(atPath: cachePath)
    }
    
    // MARK: Helpers
    
    private func filePath(for cacheName: String, with key: String) -> String? {
        guard let cachePath = cachePath(for: cacheName) else { return nil }
        return "\(cachePath)/\(fileName(for: key))"
    }
    
    private func fileName(for key: String) -> String {
      let fileExtension = URL(fileURLWithPath: key).pathExtension
      let fileName = key // todo hash?

      switch fileExtension.isEmpty {
      case true:
        return fileName
      case false:
        return "\(fileName).\(fileExtension)"
      }
    }
    
    private func cachePath(for name: String) -> String? {
        guard let url = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        return url.appendingPathComponent("\(cachePrefix).\(name)", isDirectory: true).path
    }
    
}
