//
/*
 Copyright 2023 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/


import Foundation

struct UserDefaultsMigrator {
    
}

enum UserDefaultMigratorConstants {
    enum Configuration {
        static let DATASTORE_NAME = "com.adobe.module.configuration"
        
        enum DataStoreKeys {
            static let OVERRIDDEN_MAP = "config.overridden.map"
            static let APP_ID = "config.appID"
        }
    }
    
    enum Lifecycle {
        static let DATASTORE_NAME = "com.adobe.module.lifecycle"
        
        enum DataStoreKeys {
            static let INSTALL_DATE = "install.date"
            static let LAST_LAUNCH_DATE = "last.date.used"
            static let UPGRADE_DATE = "upgrade.date"
            static let LAUNCHES_SINCE_UPGRADE = "launches.after.upgrade"
            static let PERSISTED_CONTEXT = "persisted.context"
            static let LIFECYCLE_DATA = "lifecycle.data"
            static let LAST_VERSION = "last.version"
            static let V2_LAST_VERSION = "v2.last.app.version"
            static let V2_APP_START_DATE = "v2.app.start.date"
            static let V2_APP_PAUSE_DATE = "v2.app.pause.date"
            static let V2_APP_CLOSE_DATE = "v2.app.close.date"
        }
    }
    
    enum Identity {
        static let DATASTORE_NAME = "com.adobe.module.identity"
        
        enum DataStoreKeys {
            static let IDENTITY_PROPERTIES = "identity.properties"
            static let PUSH_ENABLED = "push.enabled"
            static let ANALYTICS_PUSH_ENABLED = "analytics.push.enabled"
        }
    }
    
    enum Assurance {
        static let DATASTORE_NAME = "com.adobe.module.assurance"
        
        enum DataStoreKeys {
            static let SESSION_ID = "assurance.session.Id"
            static let CLIENT_ID = "assurance.client.Id"
            static let ENVIRONMENT = "assurance.environment"
            static let SOCKET_URL = "assurance.socketurl"
            static let MODIFIED_CONFIG_KEYS = "assurance.control.modifiedConfigKeys"
        }
    }
    
    enum Analytics {
        static let DATASTORE_NAME = "com.adobe.module.analytics"
        
        enum DataStoreKeys {
            static let LAST_HIT_TS = "mostrecenthittimestamp"
            static let AID = "aid"
            static let VID = "vid"
            static let DATA_MIGRATED = "data.migrated"
        }
    }
    
    enum Audience {
        static let DATASTORE_NAME = "com.adobe.module.audience"
        
        enum DataStoreKeys {
            static let USER_PROFILE = "AAMUserProfile"
            static let USER_ID = "AAMUserId"
        }
    }
    
    enum Target {
        static let DATASTORE_NAME = "com.adobe.module.target"
        
        enum DataStoreKeys {
            static let SESSION_TIMESTAMP = "session.timestamp"
            static let SESSION_ID = "session.id"
            static let TNT_ID = "tnt.id"
            static let EDGE_HOST = "edge.host"
            static let THIRD_PARTY_ID = "thirdparty.id"
        }
    }
    
    enum Campaign {
        static let DATASTORE_NAME = "com.adobe.module.campaign"
        
        enum DataStoreKeys {
            static let REMOTE_URL = "CampaignRemoteUrl"
            static let ECID = "ExperienceCloudId"
            static let REGISTRATION_TS = "CampaignRegistrationTimestamp"
        }
    }
    
    enum CampaignClassic {
        static let DATASTORE_NAME = "com.adobe.module.campaignclassic"
        
        enum DataStoreKeys {
            static let TOKEN_HASH = "ADOBEMOBILE_STOREDDEFAULTS_TOKENHASH"
        }
    }
    
    enum Places {
        static let DATASTORE_NAME = "PlacesDataStore"
        
        enum DataStoreKeys {
            static let ACCURACY = "places_accuracy"
            static let AUTH_STATUS = "places_auth_status"
            static let CURRENT_POI = "places_current_poi"
            static let LAST_ENTERED_POI = "places_last_entered_poi"
            static let LAST_EXITED_POI = "places_last_exited_poi"
            static let LAST_KNOWN_LATITUDE = "places_last_known_latitude"
            static let LAST_KNOWN_LONGITUDE = "places_last_known_longitude"
            static let MEMBERSHIP = "places_membership_valid_until"
            static let NEARBY_POIS = "places_nearby_pois"
            static let USER_WITHIN_POIS = "places_user_within_pois"
        }
    }
    
    enum UserProfile {
        static let DATASTORE_NAME = "com.adobe.module.userProfile"
        
        enum DataStoreKeys {
            static let ATTRIBUTES = "attributes"
        }
    }
    
    enum Edge {
        static let DATASTORE_NAME = "com.adobe.edge"
        static let PAYLOAD_DATASTORE_NAME = "AEPEdge"
        
        enum DataStoreKeys {
           static let RESET_IDENTITIES_DATE = "reset.identities.date"
            static let EDGE_PROPERTIES = "edge.properties"
            static let STORE_PAYLOADS = "storePayloads"
        }
    }
    
    enum EdgeIdentity {
        static let DATASTORE_NAME = "com.adobe.edge.identity"
        
        enum DataStoreKeys {
           static let IDENTITY_PROPERTIES = "identity.properties"
        }
    }
    
    enum EdgeConsent {
        static let DATASTORE_NAME = "com.adobe.edge.consent"
        
        enum DataStoreKeys {
           static let CONSENT_PREFERENCES = "consent.preferences.consents"
        }
    }
}
