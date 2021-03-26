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
    enum MobileServices {
        static let DATASTORE_NAME = "MobileServices"

        static let V4_IN_APP_EXCLUDE_LIST = "ADBMessageBlackList"
        static let V5_IN_APP_EXCLUDE_LIST = "Adobe.MobileServices.blacklist"
        static let V4_ACQUISITION_DATA = "ADBAcquisitionData"
        static let V5_ACQUISITION_DATA = "Adobe.MobileServices.acquisition_json"
        static let INSTALL = "Adobe.MobileServices.install"
        static let INSTALL_SEARCH_AD = "Adobe.MobileServices.install.searchad"
    }

    enum Configuration {
        static let DATASTORE_NAME = "com.adobe.module.configuration"

        static let V4_PRIVACY_STATUS = "PrivacyStatus"
        static let V5PrivacyStatus = "global.privacy"
        static let V5_OVERIDDEN_CONFIG = "config.overridden.map"
    }

    enum Identity {
        static let DATASTORE_NAME = "com.adobe.module.identity"
        static let CID_DELIMITER = "%01"

        // Migrate
        static let V4_ECID = "ADBMOBILE_PERSISTED_MID"
        static let V4_HINT = "ADBMOBILE_PERSISTED_MID_HINT"
        static let V4_BLOB = "ADBMOBILE_PERSISTED_MID_BLOB"
        static let V4_IDS = "ADBMOBILE_VISITORID_IDS"
        static let V4_PUSH_ENABLED = "ADBMOBILE_KEY_PUSH_ENABLED"
        static let V4_VID = "AOMS_AppMeasurement_StoredDefaults_VisitorID"
        // Keys to be deleted
        static let V4_TTL = "ADBMOBILE_VISITORID_TTL"
        static let V4_SYNC_TIME = "ADBMOBILE_VISITORID_SYNCTIME"
        static let V4_PUSH_TOKEN = "ADBMOBILE_KEY_PUSH_TOKEN"

        enum DataStoreKeys {
            static let IDENTITY_PROPERTIES = "identity.properties"
            static let PUSH_ENABLED = "push.enabled"
        }
    }

    enum Lifecycle {
        static let DATASTORE_NAME = "com.adobe.module.lifecycle"

        // Migrate
        static let V4_INSTALL_DATE = "OMCK1"
        static let V4_LAST_VERSION = "OMCK2"
        static let V4_LAST_USED_DATE = "OMCK5"
        static let V4_LAUNCHES = "OMCK6"
        static let V4_SUCCESSFUL_CLOSE = "OMCK7"
        // Keys to be deleted
        static let V4_LIFECYCLE_DATA         = "ADMS_LifecycleData"
        static let V4_START_DATE             = "ADMS_START"
        static let V4_APPLICATION_ID         = "ADOBEMOBILE_STOREDDEFAULTS_APPID"
        static let V4_OS                    = "ADOBEMOBILE_STOREDDEFAULTS_OS"
        static let V4_PAUSE_DATE             = "ADMS_PAUSE"
        static let V4_UPGRADE_DATE           = "OMCK3"
        static let V4_LAUNCHES_AFTER_UPGRADE  = "OMCK4"

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
