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
    private let queue = DispatchQueue(label: "com.adobe.fileSystemNamedCollection.queue")
    private let adobeDirectory = "com.adobe.aep.datastore"
    private var appGroupUrl: URL?
    private let fileManager = FileManager.default
    private let LOG_TAG = "FileSystemNamedCollection"
    private var appGroup: String?

    func setAppGroup(_ appGroup: String?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.appGroup = appGroup
            if let appGroup = appGroup {
                self.appGroupUrl = self.fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            }
        }
    }

    func getAppGroup() -> String? {
        return queue.sync {
            appGroup
        }
    }

    func set(collectionName: String, key: String, value: Any?) {
        queue.async { [weak self] in
            guard let self = self, let fileUrl = self.fileUrl(for: collectionName) else {
                return
            }
            var dict = self.getDictFor(collectionName: collectionName) ?? [:]
            guard !dict.isEmpty || value != nil else {
                return
            }
            dict[key] = value
            if JSONSerialization.isValidJSONObject(dict) {
                if let updatedStorageData = try? JSONSerialization.data(withJSONObject: dict) {
                    do {
                        try updatedStorageData.write(to: fileUrl, options: .atomic)
                    } catch {
                        Log.warning(label: self.LOG_TAG, "Error '\(error)' when writing '\(key)' to collection '\(collectionName)'")
                    }
                }
            } else {
                Log.warning(label: self.LOG_TAG, "Setting value: \(String(describing: value)) with dict: \(dict) failed. Not serializable.")
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
        queue.async { [weak self] in
            guard let self = self, let fileUrl = self.fileUrl(for: collectionName) else {
                return
            }
            if var dict = self.getDictFor(collectionName: collectionName) {
                dict.removeValue(forKey: key)
                if let updatedStorageData = try? JSONSerialization.data(withJSONObject: dict) {
                    do {
                        try updatedStorageData.write(to: fileUrl, options: .atomic)
                    } catch {
                        Log.warning(label: self.LOG_TAG, "Error '\(error)' when attempting to remove key '\(key)' from collection '\(collectionName)'")
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

        guard let storageData = try? Data(contentsOf: fileUrl) else {
            return nil
        }

        guard let jsonResult = try? JSONSerialization.jsonObject(with: storageData) as? [String: Any] else {
            Log.warning(label: LOG_TAG, "Failed to read dictionary from collection '\(collectionName)'")
            return nil
        }

        return jsonResult
    }

    ///
    /// Gets the URL for the file given a collection name
    /// - Parameter collectionName: The collectionName, in this case is used to destinguish a file
    /// - Returns: The URL to the file or nil if it could not be found
    ///
    private func fileUrl(for collectionName: String) -> URL? {
        if let appGroupUrl = appGroupUrl {
            return findOrCreateAdobeSubdirectory(at: appGroupUrl)?.appendingPathComponent(collectionName).appendingPathExtension("json")
        } else {
            let filePath = fileManager.urls(for: .libraryDirectory, in: .allDomainsMask)[0]
            return findOrCreateAdobeSubdirectory(at: filePath)?.appendingPathComponent(collectionName).appendingPathExtension("json")
        }
    }

    ///
    /// Finds or creates the Adobe subdirectory where all data store files will reside
    /// - Parameter baseUrl: The baseUrl where the Adobe directory should reside
    /// - Returns: The URL to the Adobe directory or nil if it could not be found or created
    ///
    private func findOrCreateAdobeSubdirectory(at baseUrl: URL) -> URL? {
        // Validate baseUrl
        if baseUrl.isSafeUrl() {
            let adobeBaseUrl = baseUrl.appendingPathComponent(adobeDirectory, isDirectory: true)
            do {
                try fileManager.createDirectory(at: adobeBaseUrl, withIntermediateDirectories: true)
                try fileManager.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: adobeBaseUrl.path)
            } catch {
                Log.warning(label: adobeDirectory, "Failed to create storage directory with error: \(error)")
                return nil
            }

            return adobeBaseUrl
        } else {
            Log.warning(label: adobeDirectory, "Failed to create storage directory, baseURL is not valid.")
            return nil
        }
    }

}
