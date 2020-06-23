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
    
    private func filePath(for cacheName: String, with key: String) -> String {
        return "\(cachePath(for: cacheName))/\(fileName(for: key))"
    }
    
    private func fileName(for key: String) -> String {
      let fileExtension = URL(fileURLWithPath: key).pathExtension
      let fileName = key

      switch fileExtension.isEmpty {
      case true:
        return fileName
      case false:
        return "\(fileName).\(fileExtension)"
      }
    }
    
    private func cachePath(for name: String) -> String {
        let url = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url?.appendingPathComponent("\(cachePrefix).\(name)", isDirectory: true).path ?? ""
    }
    
}
