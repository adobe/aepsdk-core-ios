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

struct IdentityConstants {
    static let EXTENSION_NAME = "com.adobe.module.identity"
    static let EXTENSION_VERSION = "0.0.1"
    static let DATASTORE_NAME = EXTENSION_NAME
    
    static let API_TIMEOUT = TimeInterval(0.5) // Get API requests timeout after half a second
    static let DEFAULT_TTL = TimeInterval(600)
    static let RESPONSE_KEY_ORGID = "d_orgid"
    static let RESPONSE_KEY_MID = "d_mid"
    static let RESPONSE_KEY_BLOB = "d_blob"
    static let RESPONSE_KEY_HINT = "dcs_region"
    static let VISITOR_ID_PARAMETER_KEY_CUSTOMER = "d_cid_ic"
    static let KEY_PATH_OPTOUT = "/demoptout.jpg"
    static let DEFAULT_SERVER = "dpm.demdex.net"
    static let CID_DELIMITER = "%01"
    static let ADID_DSID = "DSID_20915"
    
    struct SharedStateKeys {
        static let CONFIGURATION = "com.adobe.module.configuration"
    }
    
    struct Configuration {
        static let EXPERIENCE_CLOUD_ORGID = "experienceCloud.org"
        static let EXPERIENCE_CLOUD_SERVER = "experienceCloud.server"
        static let GLOBAL_CONFIG_PRIVACY = "global.privacy"
    }
    
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
        static let ADVERTISING_IDENTIFIER = "advertisingidentifier"
        static let PUSH_IDENTIFIER = "pushidentifier"
        static let VISITOR_ID_BLOB = "blob"
        static let VISITOR_ID_LOCATION_HINT = "locationhint"
        static let VISITOR_IDS_LAST_SYNC = "lastsync"
        static let MCPNS_DPID = "20920"
    }
    
    struct DataStoreKeys {
        static let IDENTITY_PROPERTIES = "identitiesproperties"
    }
    
    struct URLKeys {
        static let VISITOR_TIMESTAMP_KEY = "TS"
        static let VISITOR_PAYLOAD_MARKETING_CLOUD_ID_KEY = "MCMID"
        static let VISITOR_PAYLOAD_KEY = "adobe_mc"
        static let VISITOR_PAYLOAD_MARKETING_CLOUD_ORG_ID = "MCORGID"
        static let VISITOR_PAYLOAD_ANALYTICS_ID_KEY = "MCAID"
        static let ANALYTICS_PAYLOAD_KEY = "adobe_aa_vid"
    }
    
    struct Analytics {
        static let ANALYTICS_ID = "aid"
        static let VISITOR_IDENTIFIER  = "vid"
    }
}
