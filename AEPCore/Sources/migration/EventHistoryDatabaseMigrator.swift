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
    static func migrate() {
        let LOG_PREFIX = "EventHistoryDatabaseMigrator"
        
        let fileManager = FileManager.default
        
        // most common scenario is that the database has already been migrated, so check that first
        if let existingNewDbUrl = fileManager.urls(for: EventHistoryConstants.dbFilePath, in: .userDomainMask).first?.appendingPathComponent(EventHistoryConstants.dbNameWithSubdirectory) {
            guard !fileManager.fileExists(atPath: existingNewDbUrl.path) else {
                return
            }
        }
        
        // next make sure we have a legacy database to migrate
        guard let legacyDbUrl = fileManager.urls(for: EventHistoryConstants.legacyDbFilePath, in: .userDomainMask).first?.appendingPathComponent(EventHistoryConstants.dbName),
              fileManager.fileExists(atPath: legacyDbUrl.path) else {
            return
        }
        
        guard let applicationSupportUrl = fileManager.urls(for: EventHistoryConstants.dbFilePath, in: .userDomainMask).first else {
            Log.warning(label: LOG_PREFIX, "Unable to obtain url for 'Application Support' directory from the file manager. EventHistory database migration failed.")
            return
        }
        
        // create the Application Support directory if it doesn't exist
        guard fileManager.createDirectoryIfNeeded(at: applicationSupportUrl.appendingPathComponent(EventHistoryConstants.dbSubdirectoryName)) else {
            Log.warning(label: LOG_PREFIX, "Unable to create 'Application Support' directory. EventHistory database migration failed.")
            return
        }
        
        let newDbUrl = applicationSupportUrl.appendingPathComponent(EventHistoryConstants.dbNameWithSubdirectory)
        do {
            Log.debug(label: LOG_PREFIX, "Attempting to migrate EventHistory database from '\(legacyDbUrl)' to '\(newDbUrl)'...")
            try FileManager.default.moveItem(atPath: legacyDbUrl.path, toPath: newDbUrl.path)
            Log.debug(label: LOG_PREFIX, "Successfully migrated EventHistory database.")
        } catch {
            Log.warning(label: LOG_PREFIX, "Failed to migrate database: \(error.localizedDescription).")
        }
    }
}
