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

/// Constants for V4 -> V5 migration
enum V4MigrationConstants {
    // V4 Datastore Name
    static let V4AppGroup = "ADB_APP_GROUP"
    static let V4UserDefaultsKey = "adbUserDefaults"

    enum MobileServices {
        static let DATASTORE_NAME = "MobileServices"

        static let V4InAppExcludeList = "ADBMessageBlackList"
        static let V5InAppExcludeList = "Adobe.MobileServices.blacklist"
        static let V4AcquisitionData = "ADBAcquisitionData"
        static let V5AcquisitionData = "Adobe.MobileServices.acquisition_json"
        static let install = "Adobe.MobileServices.install"
        static let installSearchAd = "Adobe.MobileServices.install.searchad"
    }

    enum Configuration {
        static let DATASTORE_NAME = "com.adobe.module.configuration"

        static let V4PrivacyStatus = "PrivacyStatus"
        static let V5PrivacyStatus = "global.privacy"
        static let V5OverriddenConfig = "config.overridden.map"
    }

    enum Identity {
        static let DATASTORE_NAME = "com.adobe.module.identity"
        static let CID_DELIMITER = "%01"

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

        enum DataStoreKeys {
            static let IDENTITY_PROPERTIES = "identitiesproperties"
            static let PUSH_ENABLED = "ADOBEMOBILE_PUSH_ENABLED"
        }
    }

    enum Lifecycle {
        static let DATASTORE_NAME = "com.adobe.module.lifecycle"

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

        enum DataStoreKeys {
            static let INSTALL_DATE = "InstallDate"
            static let LAST_LAUNCH_DATE = "LastDateUsed"
            static let UPGRADE_DATE = "UpgradeDate"
            static let LAUNCHES_SINCE_UPGRADE = "LaunchesAfterUpgrade"
            static let PERSISTED_CONTEXT = "PersistedContext"
            static let LIFECYCLE_DATA = "LifecycleData"
            static let LAST_VERSION = "LastVersion"
        }
    }
}
