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

enum SignalConstants {
    static let EXTENSION_NAME = "com.adobe.module.signal"
    static let FRIENDLY_NAME = "Signal"
    static let EXTENSION_VERSION = "5.1.0"

    static let DATASTORE_NAME = EXTENSION_NAME
    static let LOG_PREFIX = FRIENDLY_NAME

    enum Configuration {
        static let NAME = "com.adobe.module.configuration"
        static let GLOBAL_PRIVACY = "global.privacy"
    }

    enum Defaults {
        static let TIMEOUT: TimeInterval = 2
        static let CONTENT_TYPE = "application/json"
    }

    enum ConsequenceTypes {
        static let POSTBACK = "pb"
        static let PII = "pii"
        static let OPEN_URL = "url"
    }

    enum EventDataKeys {
        static let TRIGGERED_CONSEQUENCE = "triggeredconsequence"
        static let ID = "id"
        static let DETAIL = "detail"
        static let TYPE = "type"

        static let CONTENT_TYPE = "contenttype"
        static let TEMPLATE_BODY = "templatebody"
        static let TEMPLATE_URL = "templateurl"
        static let TIMEOUT = "timeout"

        static let URL = "url"
    }
}
