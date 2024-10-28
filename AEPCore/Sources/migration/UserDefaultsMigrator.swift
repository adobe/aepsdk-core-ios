//
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
import AEPServices

struct UserDefaultsMigrator {
    private let LOG_TAG = "UserDefaultsMigrator"
    private typealias constants = UserDefaultMigratorConstants
    private let dataStore = ServiceProvider.shared.namedKeyValueService
    private var defaults: UserDefaults {
        if let appGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup() {
            return UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
        }
        
        return UserDefaults.standard
    }
    
    func migrate() {
        if needToMigrate() {
            Log.debug(label: LOG_TAG, "Beginning UserDefaults migration")
            for (collectionName, keys) in constants.migrationDict {
                for key in keys {
                    if var valueToMigrate = getAndDelete(key: keyWithPrefix(datastoreName: collectionName, key: key)) {
                        if valueToMigrate is Data {
                            valueToMigrate = String(data: valueToMigrate as! Data, encoding: .utf8) as Any
                        }
                        dataStore.set(collectionName: collectionName, key: key, value: valueToMigrate)
                    }
                }
                Log.debug(label: LOG_TAG, "UserDefaults Migration complete for \(collectionName)")
            }
            dataStore.set(collectionName: constants.MIGRATION_STORE_NAME, key: constants.MIGRATION_COMPLETE, value: true)
            Log.debug(label: LOG_TAG, "UserDefaults migration complete")
        }
    }
    
    private func needToMigrate() -> Bool {
        guard let migrationComplete = dataStore.get(collectionName: constants.MIGRATION_STORE_NAME, key: constants.MIGRATION_COMPLETE) as? Bool else {
            return true
        }
        
        return !migrationComplete
        
    }
    
    private func keyWithPrefix(datastoreName: String, key: String) -> String {
        return "Adobe.\(datastoreName).\(key)"
    }
    
    private func getAndDelete(key: String) -> Any? {
        guard let value = defaults.object(forKey: key) else {
            Log.trace(label: LOG_TAG, "No value for \(key) found")
            return nil
        }
        
        defaults.removeObject(forKey: key)
        return value
    }
}
