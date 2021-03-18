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
        static let ECID = "ADOBEMOBILE_PERSISTED_MID"
        static let HINT = "ADOBEMOBILE_PERSISTED_MID_HINT"
        static let BLOB = "ADOBEMOBILE_PERSISTED_MID_BLOB"
        static let IDS = "ADOBEMOBILE_VISITORID_IDS"
        static let PUSH_ENABLED = "ADOBEMOBILE_PUSH_ENABLED"
        static let VID = "ADOBEMOBILE_VISITOR_ID"

        // delete
        static let TTL = "ADBMOBILE_VISITORID_TTL"
        static let SYNC_TIME = "ADBMOBILE_VISITORID_SYNCTIME"
        static let PUSH_TOKEN = "ADBMOBILE_KEY_PUSH_TOKEN"

        enum DataStoreKeys {
            static let IDENTITY_PROPERTIES = "identity.properties"
            static let PUSH_ENABLED = "push.enabled"
        }
    }

    enum Lifecycle {
        // migrate
        static let DATASTORE_NAME = "com.adobe.module.lifecycle"
        static let LEGACY_DATASTORE_NAME = "AdobeMobile_Lifecycle"
        static let INSTALL_DATE = "InstallDate"
        static let LAST_VERSION = "LastVersion"
        static let LAST_USED_DATE = "LastDateUsed"
        static let LAUNCHES = "Launches"
        static let SUCCESSFUL_CLOSE = "SuccessfulClose"

        // delete
        static let LIFECYCLE_DATA = "LifecycleData"
        static let START_DATE = "SessionStart"
        static let APP_ID = "AppId"
        static let OS_VERSION = "OsVersion"
        static let PAUSE_DATE = "PauseDate"
        static let UPGRADE_DATE = "UpgradeDate"
        static let LAUNCHES_AFTER_UPGRADE = "LaunchesAfterUpgrade"

        enum DataStoreKeys {
            static let INSTALL_DATE = "install.date"
            static let LAST_LAUNCH_DATE = "last.date.used"
            static let UPGRADE_DATE = "upgrade.date"
            static let LAUNCHES_SINCE_UPGRADE = "launches.after.upgrade"
            static let PERSISTED_CONTEXT = "persisted.context"
            static let LIFECYCLE_DATA = "lifecycle.data"
            static let LAST_VERSION = "last.version"
        }
    }
}
