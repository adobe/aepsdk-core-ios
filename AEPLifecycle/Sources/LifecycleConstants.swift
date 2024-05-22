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

/// Constants for `Lifecycle`
enum LifecycleConstants {
    static let EXTENSION_NAME = "com.adobe.module.lifecycle"
    static let FRIENDLY_NAME = "Lifecycle"
    static let EXTENSION_VERSION = "5.1.0"

    static let DATA_STORE_NAME = LifecycleConstants.EXTENSION_NAME

    static let START = "start"
    static let PAUSE = "pause"
    static let MAX_SESSION_LENGTH_SECONDS = 86400.0 * 7.0 // 7 days
    static let DEFAULT_LIFECYCLE_TIMEOUT = 300 // 5 min

    static let LOG_TAG = "Lifecycle"

    enum SharedStateKeys {
        static let CONFIGURATION = "com.adobe.module.configuration"
    }

    enum EventNames {
        static let LIFECYCLE_START = "LifecycleStart"
    }

    enum EventDataKeys {
        static let ACTION_KEY = "action"
        static let ADDITIONAL_CONTEXT_DATA = "additionalcontextdata"
        // LifecycleSession Keys
        static let OPERATING_SYSTEM = "osversion"
        static let APP_ID = "AppId"
        static let PREVIOUS_SESSION_LENGTH = "prevsessionlength"
        static let IGNORED_SESSION_LENGTH = "ignoredsessionlength"
        static let LIFECYCLE_CONTEXT_DATA = "lifecyclecontextdata"
        static let SESSION_EVENT = "sessionevent"
        static let SESSION_START_TIMESTAMP = "starttimestampmillis"
        static let MAX_SESSION_LENGTH = "maxsessionlength"
        static let PREVIOUS_SESSION_START_TIMESTAMP = "previoussessionstarttimestampmillis"
        static let PREVIOUS_SESSION_PAUSE_TIMESTAMP = "previoussessionpausetimestampmillis"
        static let CONFIG_SESSION_TIMEOUT = "lifecycle.sessionTimeout"
    }

    enum DataStoreKeys {
        static let INSTALL_DATE = "install.date"
        static let LAST_LAUNCH_DATE = "last.date.used"
        static let UPGRADE_DATE = "upgrade.date"
        static let LAUNCHES_SINCE_UPGRADE = "launches.after.upgrade"
        static let PERSISTED_CONTEXT = "persisted.context"
        static let LIFECYCLE_DATA = "lifecycle.data"
        static let LAST_VERSION = "last.version"
    }

    enum Identity {
        static let NAME = "com.adobe.module.identity"
        enum EventDataKeys {
            static let ADVERTISING_IDENTIFIER = "advertisingidentifier"
        }
    }
}
