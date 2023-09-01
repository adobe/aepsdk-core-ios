/*
 Copyright 2023 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import Foundation

class FileSystemNamedCollection: NamedCollectionProcessing {
    private let queue = DispatchQueue(label: "FileSystemNamedCollection.barrierQueue")
    private let adobeDirectory = "com.adobe.aep.datastore"
    private var appGroupUrl: URL?
    private let fileManager = FileManager.default
    private let LOG_TAG = "FileSystemNamedCollection"
    var appGroup: String?

    func setAppGroup(_ appGroup: String?) {
        self.appGroup = appGroup
        if let appGroup = appGroup {
            self.appGroupUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
        }
    }

    func getAppGroup() -> String? {
        return appGroup
    }

    func set(collectionName: String, key: String, value: Any?) {
        guard let fileUrl = fileUrl(for: collectionName) else {
            return
        }
        queue.sync {
            var dict = self.getDictFor(collectionName: collectionName) ?? [:]
            guard !dict.isEmpty || value != nil else {
                return
            }
            dict[key] = value
            if let updatedStorageData = try? JSONSerialization.data(withJSONObject: dict) {
                do {
                    try updatedStorageData.write(to: fileUrl, options: .atomic)
                } catch {
                    Log.error(label: LOG_TAG, "Error when writing to file: \(error)")
                }
            }
        }
    }

    func get(collectionName: String, key: String) -> Any? {
        return queue.sync {
            if let dict = getDictFor(collectionName: collectionName) {
                return dict[key]
            }
            return nil
        }
    }

    func remove(collectionName: String, key: String) {
        queue.sync {
            guard let fileUrl = self.fileUrl(for: collectionName) else {
                return
            }
            if var dict = self.getDictFor(collectionName: collectionName) {
                dict.removeValue(forKey: key)
                if let updatedStorageData = try? JSONSerialization.data(withJSONObject: dict) {
                    do {
                        try updatedStorageData.write(to: fileUrl, options: .atomic)
                    } catch {
                        Log.error(label: LOG_TAG, "Error when attempting to remove value from file: \(error)")
                    }
                }
            }
        }
    }
    
    ///
    /// Gets the JSON dictionary from the file with the given collection name
    /// - Parameter collectionName: The collectionName, in this case used to destinguish a file
    /// - Returns: The JSON dictionary if it exists, or nil if there is an error / it doesn't exist
    ///
    private func getDictFor(collectionName: String) -> [String: Any]? {
        guard let fileUrl = fileUrl(for: collectionName) else {
            return nil
        }
        
        if let storageData = try? Data(contentsOf: fileUrl) {
            if let jsonResult = try? JSONSerialization.jsonObject(with: storageData) as? Dictionary<String, Any> {
                return jsonResult
            }
        }
        
        return nil
    }
    
    private func fileUrl(for collectionName: String) -> URL? {
        if let appGroupUrl = appGroupUrl {
            return findOrCreateAdobeSubdirectory(at: appGroupUrl)?.appendingPathComponent(collectionName).appendingPathExtension("json")
        } else {
            let filePath = fileManager.urls(for: .libraryDirectory, in: .allDomainsMask)[0]
            return findOrCreateAdobeSubdirectory(at: filePath)?.appendingPathComponent(collectionName).appendingPathExtension("json")
        }
    }
    
    private func findOrCreateAdobeSubdirectory(at baseUrl: URL) -> URL? {
        // Validate baseUrl
        if baseUrl.isSafeUrl() {
            let adobeBaseUrl = baseUrl.appendingPathComponent(adobeDirectory, isDirectory: true)
            do {
                try fileManager.createDirectory(at: adobeBaseUrl, withIntermediateDirectories: true)
            } catch {
                Log.error(label: adobeDirectory, "Failed to create storage directory with error: \(error)")
                return nil
            }
            
            return adobeBaseUrl
        } else {
            Log.error(label: adobeDirectory, "Failed to create storage directory, baseURL is not valid.")
            return nil
        }
    }
    
}
