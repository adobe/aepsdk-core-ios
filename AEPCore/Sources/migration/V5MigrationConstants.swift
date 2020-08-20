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

/// Constants for V5 C++ -> V5 Swift migration
enum V5MigrationConstants {
    enum Configuration {
        static let DATASTORE_NAME = "com.adobe.module.configuration"
        static let LEGACY_DATASTORE_NAME = "AdobeMobile_ConfigState"
        static let OVERRIDDEN_CONFIG = "config.overridden.map"

        enum DataStoreKeys {
            static let PERSISTED_OVERRIDDEN_CONFIG = "config.overridden.map"
        }
    }

    enum Identity {
        static let DATASTORE_NAME = "com.adobe.module.identity"
        static let LEGACY_DATASTORE_NAME = "visitorIDServiceDataStore"
        // migrate
        static let MID = "ADOBEMOBILE_PERSISTED_MID"
        static let Hint = "ADOBEMOBILE_PERSISTED_MID_HINT"
        static let Blob = "ADOBEMOBILE_PERSISTED_MID_BLOB"
        static let Ids = "ADOBEMOBILE_VISITORID_IDS"
        static let PushEnabled = "ADOBEMOBILE_PUSH_ENABLED"
        static let VID = "ADOBEMOBILE_VISITOR_ID"

        // delete
        static let TTL = "ADBMOBILE_VISITORID_TTL"
        static let SyncTime = "ADBMOBILE_VISITORID_SYNCTIME"
        static let PushToken = "ADBMOBILE_KEY_PUSH_TOKEN"

        enum DataStoreKeys {
            static let IDENTITY_PROPERTIES = "identitiesproperties"
            static let PUSH_ENABLED = "ADOBEMOBILE_PUSH_ENABLED"
        }
    }

    enum Lifecycle {
        // migrate
        static let DATASTORE_NAME = "com.adobe.module.lifecycle"
        static let LEGACY_DATASTORE_NAME = "AdobeMobile_Lifecycle"
        static let InstallDate = "InstallDate"
        static let LastVersion = "LastVersion"
        static let LastUsedDate = "LastDateUsed"
        static let Launches = "Launches"
        static let SuccessfulClose = "SuccessfulClose"

        // delete
        static let LifecycleData = "LifecycleData"
        static let StartDate = "SessionStart"
        static let AppId = "AppId"
        static let OsVersion = "OsVersion"
        static let PauseDate = "PauseDate"
        static let UpgradeDate = "UpgradeDate"
        static let LaunchesAfterUpgrade = "LaunchesAfterUpgrade"

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
