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
import AEPServices

/// Constants for V4 -> V5 migration
private enum MigrationConstants {
    // V4 Datastore Name
    static let V4AppGroup = "ADB_APP_GROUP"
    static let V4UserDefaultsKey = "adbUserDefaults"
    
    enum MobileServices {
        static let InAppExcludeList = "ADBMessageBlackList"
    }
    
    enum Configuration {
        static let V4PrivacyStatus = "PrivacyStatus"
        static let V5PrivacyStatus = "global.privacy"
        static let V5OverriddenConfig = "config.overridden.map"
    }
    
    enum Identity {
        // Migrate
        static let V4MID = "ADBMOBILE_PERSISTED_MID"
        static let V4Hint = "ADBMOBILE_PERSISTED_MID_HINT"
        static let V4Blob = "ADBMOBILE_PERSISTED_MID_BLOB"
        static let V4Ids = "ADBMOBILE_VISITORID_IDS"
        static let V4PushEnabled = "ADBMOBILE_KEY_PUSH_ENABLED"
        static let V4Vid = "AOMS_AppMeasurement_StoredDefaults_VisitorID"
        // Keys to be deleted
        static let V4TTL = "ADBMOBILE_VISITORID_TTL"
        static let V4SyncTime = "ADBMOBILE_VISITORID_SYNCTIME"
        static let V4PushToken = "ADBMOBILE_KEY_PUSH_TOKEN"
    }
    
    enum Lifecycle {
        // Migrate
        static let V4InstallDate = "OMCK1"
        static let V4LastVersion = "OMCK2"
        static let V4LastUsedDate = "OMCK5"
        static let V4Launches = "OMCK6"
        static let V4SuccessfulClose = "OMCK7"
        // Keys to be deleted
        static let V4LifecycleData         = "ADMS_LifecycleData"
        static let V4StartDate             = "ADMS_START"
        static let V4ApplicationID         = "ADOBEMOBILE_STOREDDEFAULTS_APPID"
        static let V4OS                    = "ADOBEMOBILE_STOREDDEFAULTS_OS"
        static let V4PauseDate             = "ADMS_PAUSE"
        static let V4UpgradeDate           = "OMCK3"
        static let V4LaunchesAfterUpgrade  = "OMCK4"
    }
}

/// A type which provides functionality for migrating keys from V4 to V5
struct V4Migrator {
    private static var v4Defaults: UserDefaults {
        if let v4AppGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup(), !v4AppGroup.isEmpty {
            return UserDefaults(suiteName: v4AppGroup) ?? UserDefaults.standard
        }
        
        return UserDefaults.standard
    }

    /// Migrates the V4 datastore into V5 datastore
    static func migrate() {
        if defaultsNeedsMigration() {
            migrateLocalStorage()
            migrateConfigurationLocalStorage()
            // add log
        } else if configNeedsMigration() {
            migrateConfigurationLocalStorage()
            // log
        }

        if visitorIdNeedsMigration() {
            migrateVisitorIdLocalStorage()
            // log
        }
    }
    
    // MARK: Private APIs
    
    /// Determine if we need to migrate V4 to V5
    /// - Returns: True if an install date exists in V4 user defaults, false otherwise
    private static func defaultsNeedsMigration() -> Bool {
        return v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4InstallDate) != nil
    }
    
    /// Determine if we need to migrate V4 to V5
    /// - Returns: True if a privacy status key exists in the V4 defaults
    private static func configNeedsMigration() -> Bool {
        return v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus) != nil
    }

    /// Determine whether we need to migrate vid from Identity to Analytics
    /// - Returns: True if we need to migrate the vid from Identity to Analytics
    private static func visitorIdNeedsMigration() -> Bool {
        // TOOD: Implement when implementing the Analytics extension
        return false
    }

    private static func migrateLocalStorage() {
        // TODO: mobile services
        // TODO: acquisition
        // TODO: analytics
        // TODO: audience manager

        // Identity
        let mid = v4Defaults.string(forKey: MigrationConstants.Identity.V4MID)
        let hint = v4Defaults.string(forKey: MigrationConstants.Identity.V4Hint)
        let blob = v4Defaults.string(forKey: MigrationConstants.Identity.V4Blob)
        let ids = v4Defaults.string(forKey: MigrationConstants.Identity.V4Ids)
        let pushEnabled = v4Defaults.string(forKey: MigrationConstants.Identity.V4PushEnabled)
        // TODO: Put in v5 storage
        
        
        
        v4Defaults.removeObject(forKey: MigrationConstants.Identity.V4MID)
        v4Defaults.removeObject(forKey: MigrationConstants.Identity.V4Hint)
        v4Defaults.removeObject(forKey: MigrationConstants.Identity.V4Blob)
        v4Defaults.removeObject(forKey: MigrationConstants.Identity.V4Ids)
        v4Defaults.removeObject(forKey: MigrationConstants.Identity.V4PushEnabled)
        
        // Lifecycle
        let installDate = v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4InstallDate) as? Date
        let lastVersion = v4Defaults.string(forKey: MigrationConstants.Lifecycle.V4LastVersion)
        let lastUsedDate = v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LastUsedDate) as? Date
        let launches = v4Defaults.integer(forKey: MigrationConstants.Lifecycle.V4Launches)
        let successfulClose = v4Defaults.bool(forKey: MigrationConstants.Lifecycle.V4SuccessfulClose)
        // TODO: Put in v5 storage
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4InstallDate)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4LastVersion)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4LastUsedDate)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4Launches)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4SuccessfulClose)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4LifecycleData)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4StartDate)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4ApplicationID)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4OS)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4PauseDate)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4UpgradeDate)
        v4Defaults.removeObject(forKey: MigrationConstants.Lifecycle.V4LaunchesAfterUpgrade)
        
        // TODO: target
    }

    private static func migrateConfigurationLocalStorage() {
        let v4PrivacyStatus = v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus) as? NSNumber
        if let v4PrivacyStatus = v4PrivacyStatus, v4PrivacyStatus.intValue > 0 && v4PrivacyStatus.intValue < 4 {
            var v5PrivacyStatus = PrivacyStatus.unknown
            
            switch v4PrivacyStatus {
            case 1:
                v5PrivacyStatus = .optedIn
            case 2:
                v5PrivacyStatus = .optedOut
            default:
                v5PrivacyStatus = .unknown
            }
            
            
        }
    }

    private static func migrateVisitorIdLocalStorage() {
        // TOOD: Implement when implementing the Analytics extension
    }

}
