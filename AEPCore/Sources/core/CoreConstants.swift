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

enum CoreConstants {

    static let API_TIMEOUT = TimeInterval(1) // 1 second

    enum EventNames {
        static let ANALYTICS_TRACK = "Analytics Track"
        static let COLLECT_PII = "Collect PII"
        static let COLLECT_DATA = "Collect Data"
        static let CONFIGURE_WITH_APP_ID = "Configure with App ID"
        static let CONFIGURE_WITH_FILE_PATH = "Configure with File Path"
        static let CLEAR_UPDATED_CONFIGURATION = "Clear Updated Configuration"
        static let CONFIGURATION_REQUEST_EVENT = "Configuration Request"
        static let CONFIGURATION_RESPONSE_EVENT = "Configuration Response"
        static let CONFIGURATION_UPDATE = "Configuration Update"
        static let GET_SDK_IDENTITIES = "Get SDK Identities"
        static let LIFECYCLE_PAUSE = "Lifecycle Pause"
        static let LIFECYCLE_RESUME = "Lifecycle Resume"
        static let PRIVACY_STATUS_REQUEST = "Privacy Status Request"
        static let SET_PUSH_IDENTIFIER = "Set Push Identifier"
        static let SET_ADVERTISING_IDENTIFIER = "Set Advertising Identifier"
        static let RESET_IDENTITIES_REQUEST = "Reset Identities Request"
    }

    enum Keys {
        static let ACTION = "action"
        static let STATE = "state"
        static let CONTEXT_DATA = "contextdata"
        static let ADDITIONAL_CONTEXT_DATA = "additionalcontextdata"
        static let GLOBAL_CONFIG_PRIVACY = "global.privacy"
        static let UPDATE_CONFIG = "config.update"
        static let CLEAR_UPDATED_CONFIG = "config.clearUpdates"
        static let RETRIEVE_CONFIG = "config.getData"
        static let JSON_APP_ID = "config.appId"
        static let JSON_FILE_PATH = "config.filePath"
        static let IS_INTERNAL_EVENT = "config.isinternalevent"
        static let CONFIG_CACHE_PREFIX = "cached.config."
        static let ALL_IDENTIFIERS = "config.allidentifiers"
        static let BUILD_ENVIRONMENT = "build.environment"
        static let EXPERIENCE_CLOUD_ORGID = "experienceCloud.org"
        static let EXPERIENCE_CLOUD_SERVER = "experienceCloud.server"
        static let ADVERTISING_IDENTIFIER = "advertisingidentifier"
        static let PUSH_IDENTIFIER = "pushidentifier"
    }

    enum DataStoreKeys {
        static let PERSISTED_OVERRIDDEN_CONFIG = "config.overridden.map"
        static let PERSISTED_APPID = "config.appid"
    }

    enum Privacy {
        static let UNKNOWN = "optunknown"
        static let OPT_OUT = "optedout"
        static let OPT_IN = "optedin"
    }

    enum WrapperType {
        static let REACT_NATIVE = "R"
        static let FLUTTER = "F"
        static let CORDOVA = "C"
        static let UNITY = "U"
        static let XAMARIN = "X"
        static let NONE = "N"
    }

    enum WrapperName {
        static let REACT_NATIVE = "React Native"
        static let FLUTTER = "Flutter"
        static let CORDOVA = "Cordova"
        static let UNITY = "Unity"
        static let XAMARIN = "Xamarin"
        static let NONE = "None"
    }

    enum Lifecycle {
        static let START = "start"
        static let PAUSE = "pause"
    }

    enum Signal {
        enum EventDataKeys {
            static let CONTEXT_DATA = "contextdata"
        }
    }

}
