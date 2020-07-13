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

struct ConfigurationConstants {
    static let EXTENSION_NAME = "com.adobe.module.configuration"
    static let EXTENSION_VERSION = "0.0.1"
    static let DATA_STORE_NAME = EXTENSION_NAME

    static let CONFIG_URL_BASE = "https://assets.adobedtm.com/"
    static let CONFIG_BUNDLED_FILE_NAME  = "ADBMobileConfig"
    static let CONFIG_MANIFEST_APPID_KEY = "ADBMobileAppID"
    static let DOWNLOAD_RETRY_INTERVAL = TimeInterval(5) // 5 seconds
    static let API_TIMEOUT = TimeInterval(1) // 1 second
    static let ENVIRONMENT_PREFIX_DELIMITER = "__"

    struct Keys {
        static let GLOBAL_CONFIG_PRIVACY = "global.privacy"
        static let UPDATE_CONFIG = "config.update"
        static let RETRIEVE_CONFIG = "config.getData"
        static let JSON_APP_ID = "config.appId"
        static let JSON_FILE_PATH = "config.filePath"
        static let PERSISTED_OVERRIDDEN_CONFIG = "config.overridden.map"
        static let PERSISTED_APPID = "config.appID"
        static let IS_INTERNAL_EVENT = "config.isinternalevent"
        static let CONFIG_CACHE_PREFIX = "cached.config."
        static let ALL_IDENTIFIERS = "config.allidentifiers"
        static let BUILD_ENVIRONMENT = "build.environment"
        static let EXPERIENCE_CLOUD_ORGID = "experienceCloud.org"
    }

    struct Privacy {
        static let UNKNOWN = "optunknown"
        static let OPT_OUT = "optedout"
        static let OPT_IN = "optedin"
    }
}
