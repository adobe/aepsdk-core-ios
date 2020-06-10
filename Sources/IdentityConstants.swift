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

import Foundation

struct IdentityConstants {
    static let RESPONSE_KEY_ORGID = "d_orgid"
    static let RESPONSE_KEY_MID = "d_mid"
    static let KEY_PATH_OPTOUT = "/demoptout.jpg"
    static let DEFAULT_SERVER = "dpm.demdex.net"

    struct EventDataKeys {
        static let BASE_URL = "baseurl"
        static let UPDATED_URL = "updatedurl"
        static let VISITOR_IDS_LIST = "visitoridslist"
        static let VISITOR_ID_MID = "mid"
        static let IDENTIFIERS = "visitoridentifiers"
        static let AUTHENTICATION_STATE = "authenticationstate"
        static let FORCE_SYNC = "forcesync"
        static let IS_SYNC_EVENT = "issyncevent"
        static let URL_VARIABLES = "urlvariables"

        struct Audience {
            static let OPTED_OUT_HIT_SENT = ""
        }

    }
}
