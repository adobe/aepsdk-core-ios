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

enum IdentityConstants {
    static let EXTENSION_NAME = "com.adobe.module.identity"
    static let FRIENDLY_NAME = "Identity"
    static let EXTENSION_VERSION = "5.1.0"

    static let DATASTORE_NAME = EXTENSION_NAME

    static let API_TIMEOUT = TimeInterval(0.5) // Get API requests timeout after half a second
    static let VISITOR_ID_PARAMETER_KEY_CUSTOMER = "d_cid_ic"
    static let KEY_PATH_OPTOUT = "/demoptout.jpg"
    static let CID_DELIMITER = "%01"
    static let ADID_DSID = "DSID_20915"

    enum SharedStateKeys {
        static let CONFIGURATION = "com.adobe.module.configuration"
        static let ANALYTICS = "com.adobe.module.analytics"
        static let AUDIENCE = "com.adobe.module.audience"
        static let TARGET = "com.adobe.module.target"
    }

    enum Hub {
        static let SHARED_OWNER_NAME = "com.adobe.module.eventhub"
        static let EXTENSIONS = "extensions"
    }

    enum Configuration {
        static let EXPERIENCE_CLOUD_ORGID = "experienceCloud.org"
        static let EXPERIENCE_CLOUD_SERVER = "experienceCloud.server"
        static let GLOBAL_CONFIG_PRIVACY = "global.privacy"
        static let ALL_IDENTIFIERS = "config.allidentifiers"
        static let UPDATE_CONFIG = "config.update"
        static let AAM_CONFIG_SERVER = "audience.server"
    }

    enum EventNames {
        static let ANALYTICS_FOR_IDENTITY_REQUEST = "AnalyticsForIdentityRequest"
        static let CONFIGURATION_RESPONSE_IDENTITY_EVENT = "Configuration Response Identity Event"
        static let CONFIGURATION_UPDATE_FROM_IDENTITY_MODULE = "Configuration Update From Identity Module"
        static let IDENTITY_APPENDED_URL = "IDENTITY_APPENDED_URL"
        static let IDENTITY_REQUEST_IDENTITY = "IdentityRequestIdentity"
        static let IDENTITY_RESPONSE_CONTENT_ONE_TIME = "IDENTITY_RESPONSE_CONTENT_ONE_TIME"
        static let IDENTITY_URL_VARIABLES = "IDENTITY_URL_VARIABLES"
        static let UPDATED_IDENTITY_RESPONSE = "UPDATED_IDENTITY_RESPONSE"
        static let AVID_SYNC_EVENT = "AVID Sync"
    }

    enum EventDataKeys {
        static let BASE_URL = "baseurl"
        static let UPDATED_URL = "updatedurl"
        static let VISITOR_IDS_LIST = "visitoridslist"
        static let VISITOR_ID_ECID = "mid"
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
        static let ANALYTICS_ID = "AVID"
    }

    enum DataStoreKeys {
        static let IDENTITY_PROPERTIES = "identity.properties"
        static let PUSH_ENABLED = "push.enabled"
        static let ANALYTICS_PUSH_SYNC = "analytics.push.sync"
    }

    enum URLKeys {
        static let ORGID = "d_orgid"
        static let ECID = "d_mid"
        static let BLOB = "d_blob"
        static let HINT = "dcs_region"
        static let VISITOR_TIMESTAMP_KEY = "TS"
        static let VISITOR_PAYLOAD_MARKETING_CLOUD_ID_KEY = "MCMID"
        static let VISITOR_PAYLOAD_KEY = "adobe_mc"
        static let VISITOR_PAYLOAD_MARKETING_CLOUD_ORG_ID = "MCORGID"
        static let VISITOR_PAYLOAD_ANALYTICS_ID_KEY = "MCAID"
        static let ANALYTICS_PAYLOAD_KEY = "adobe_aa_vid"
        static let DEVICE_CONSENT = "device_consent"
        static let CONSENT_INTEGRATION_CODE = "d_consent_ic"
    }

    enum Default {
        static let TTL = TimeInterval(600)
        static let TIMEOUT = TimeInterval(2000)
        static let SERVER = "dpm.demdex.net"
        static let ZERO_ADVERTISING_ID = "00000000-0000-0000-0000-000000000000"
    }

    enum Analytics {
        static let ANALYTICS_ID = "aid"
        static let VISITOR_IDENTIFIER = "vid"
        static let TRACK_ACTION = "action"
        static let CONTEXT_DATA = "contextdata"
        static let EVENT_PUSH_STATUS = "a.push.optin"
        static let PUSH_ID_ENABLED_ACTION_NAME = "Push"
        static let TRACK_INTERNAL = "trackinternal"
    }

    enum Audience {
        static let DPID = "dpid"
        static let DPUUID = "dpuuid"
        static let UUID = "uuid"
        static let OPTED_OUT_HIT_SENT = "optedouthitsent"
    }

    enum Target {
        static let TNT_ID = "tntid"
        static let THIRD_PARTY_ID = "thirdpartyid"
    }
}
