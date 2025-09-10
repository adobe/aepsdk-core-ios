/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import AEPServices

struct EventHistoryDatabaseMigrator {
    static let LOG_PREFIX = "EventHistoryDatabaseMigrator"
    static let dbName = "com.adobe.eventHistory"
    static let dbFilePath: FileManager.SearchPathDirectory = .applicationSupportDirectory
    static let legacyDbFilePath: FileManager.SearchPathDirectory = .cachesDirectory
    
    static func migrate() {
        let fileManager = FileManager.default
        guard let cachesUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            Log.warning(label: LOG_PREFIX, "Unable to obtain url for 'Caches' directory from the file manager. EventHistory database migration failed.")
            return
        }
        
        let oldDbFilePath = cachesUrl.appendingPathComponent(dbName).path
        
        // migrate existing EventHistory database if it exists
        if FileManager.default.fileExists(atPath: oldDbFilePath) {
            guard let applicationSupportUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                Log.warning(label: LOG_PREFIX, "Unable to obtain url for 'Application Support' directory from the file manager. EventHistory database migration failed.")
                return
            }
            
            // create the Application Support directory if it doesn't exist
            guard FileManager.default.createDirectoryIfNeeded(at: applicationSupportUrl) else {
                Log.warning(label: LOG_PREFIX, "Unable to create 'Application Support' directory. EventHistory database migration failed.")
                return
            }
            
            let newDbFilePath = applicationSupportUrl.appendingPathComponent(dbName).path
            do {
                Log.debug(label: Self.LOG_PREFIX, "Attempting to migrate EventHistory database from '\(oldDbFilePath)' to '\(newDbFilePath)'...")
                try FileManager.default.moveItem(atPath: oldDbFilePath, toPath: newDbFilePath)
                Log.debug(label: Self.LOG_PREFIX, "Successfully migrated EventHistory database.")
            } catch {
                Log.warning(label: Self.LOG_PREFIX, "Failed to migrate database: \(error.localizedDescription).")
            }
        }
    }
}
