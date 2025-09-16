//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPServices

public extension FileManager {
    /// Clears the cache for specified items within the application's cache directory. Ex: the event database for a given extension.
    ///
    /// This method removes cache items based on the provided list of cache item names and directory flags. If no list is provided,
    /// a default set of cache items is used. This operation is intended to clear cached data related to specific extensions or
    /// functionalities within an app, such as consent, identity, and disk caches. The method handles both file and directory types
    /// of cache items.
    ///
    /// - Parameter cacheItems: An optional array of tuples where each tuple contains the `name` of the cache item (as a `String`)
    ///   and a `Bool` indicating whether the cache item is a directory (`true`) or a file (`false`). If `nil`, a default list of
    ///   cache items is used.
    func clearCache(_ cacheItems: [(name: String, isDirectory: Bool)]? = nil) {
        // Use caller provided values, defaults otherwise.
        let cacheItems = cacheItems ?? [(name: "com.adobe.edge", isDirectory: false),
                                        (name: "com.adobe.edge.consent", isDirectory: false),
                                        (name: "com.adobe.edge.identity", isDirectory: false),
                                        (name: "com.adobe.eventHistory", isDirectory: false),
                                        (name: "com.adobe.mobile.diskcache", isDirectory: true),
                                        (name: "com.adobe.module.signal", isDirectory: false),
                                        (name: "com.adobe.module.identity", isDirectory: false)
        ]
        
        clearCachedItems(cacheItems, in: .cachesDirectory)
        
        let migratedEventHistoryDb = [(name: "com.adobe.aep.db/com.adobe.eventHistory", isDirectory: false)]
        clearCachedItems(migratedEventHistoryDb, in: .applicationSupportDirectory)
    }
    
    private func clearCachedItems(_ cachedItems: [(name: String, isDirectory: Bool)], in directory: FileManager.SearchPathDirectory) {
        let LOG_TAG = "FileManager"
        
        guard let url = self.urls(for: directory, in: .userDomainMask).first else {
            Log.warning(label: LOG_TAG, "Unable to find valid cache directory path.")
            return
        }

        for cacheItem in cachedItems {
            do {
                try self.removeItem(at: URL(fileURLWithPath: "\(url.relativePath)/\(cacheItem.name)", isDirectory: cacheItem.isDirectory))
                if let dqService = ServiceProvider.shared.dataQueueService as? DataQueueService {
                    _ = dqService.store.removeValue(forKey: cacheItem.name)
                }
            } catch {
                let errorCode = (error as NSError).code
                if errorCode != NSFileNoSuchFileError, errorCode != NSFileReadNoSuchFileError {
                    Log.error(label: LOG_TAG, "Error removing cache item, with reason: \(error)")
                }
            }
        }
    }

    /// Removes the Adobe cache directory within the app's data storage (persistence) from the specified app group's container directory or in the default library directory
    /// if no app group is provided.
    ///
    /// - Parameters:
    ///   - name: A `String` specifying the name of the directory to remove. Defaults to `"com.adobe.aep.datastore"` if not specified.
    ///   - appGroup: An optional `String` representing the app group identifier. If provided, the method will look for the directory within the app group container. If `nil`, the method will search in the current application's library directory.
    /// - Requires: Before calling this method, ensure that the caller has the appropriate permissions to access and modify the file system, especially if working with app group directories.
    func clearDirectory(_ name: String = "com.adobe.aep.datastore", inAppGroup appGroup: String? = nil) {
        let LOG_TAG = "FileManager"
        let fileManager = FileManager.default

        // Recreate the directory URL
        var directoryUrl: URL?
        if let appGroup = appGroup {
            directoryUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
                .appendingPathComponent(name, isDirectory: true)
        } else {
            directoryUrl = fileManager.urls(for: .libraryDirectory, in: .allDomainsMask).first?
                .appendingPathComponent(name, isDirectory: true)
        }

        guard let directoryUrl = directoryUrl else {
            Log.error(label: LOG_TAG, "Could not compute the directory URL for \(name) for removal.")
            return
        }

        // Remove the directory
        do {
            try fileManager.removeItem(at: directoryUrl)
            Log.debug(label: LOG_TAG, "Successfully removed directory at \(directoryUrl.path).")
        } catch {
            let errorCode = (error as NSError).code
            if errorCode != NSFileNoSuchFileError, errorCode != NSFileReadNoSuchFileError {
                Log.warning(label: LOG_TAG, "Failed to remove directory at \(directoryUrl.path) with error: \(error)")
            }
        }
    }
}
