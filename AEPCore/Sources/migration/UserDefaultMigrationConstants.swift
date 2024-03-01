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

enum UserDefaultMigratorConstants {
    
    static let MIGRATION_STORE_NAME = "com.adobe.migration"
    static let MIGRATION_COMPLETE = "migration.userdefaults.complete"
    
    static let migrationDict: [String: [String]] = [
        Configuration.DATASTORE_NAME: Configuration.DataStoreKeys.allCases.map {$0.rawValue},
        Identity.DATASTORE_NAME: Identity.DataStoreKeys.allCases.map {$0.rawValue},
        Lifecycle.DATASTORE_NAME: Lifecycle.DataStoreKeys.allCases.map {$0.rawValue},
        Assurance.DATASTORE_NAME: Assurance.DataStoreKeys.allCases.map {$0.rawValue},
        Analytics.DATASTORE_NAME: Analytics.DataStoreKeys.allCases.map {$0.rawValue},
        Audience.DATASTORE_NAME: Audience.DataStoreKeys.allCases.map {$0.rawValue},
        Target.DATASTORE_NAME: Target.DataStoreKeys.allCases.map {$0.rawValue},
        Campaign.DATASTORE_NAME: Campaign.DataStoreKeys.allCases.map {$0.rawValue},
        CampaignClassic.DATASTORE_NAME: CampaignClassic.DataStoreKeys.allCases.map {$0.rawValue},
        Places.DATASTORE_NAME: Places.DataStoreKeys.allCases.map {$0.rawValue},
        UserProfile.DATASTORE_NAME: UserProfile.DataStoreKeys.allCases.map {$0.rawValue},
        Edge.DATASTORE_NAME: Edge.EdgeDataStoreKeys.allCases.map {$0.rawValue},
        Edge.PAYLOAD_DATASTORE_NAME: Edge.EdgePayloadStoreKeys.allCases.map {$0.rawValue},
        EdgeIdentity.DATASTORE_NAME: EdgeIdentity.DataStoreKeys.allCases.map {$0.rawValue},
        EdgeConsent.DATASTORE_NAME: EdgeConsent.DataStoreKeys.allCases.map {$0.rawValue}
    ]
    
    enum Configuration {
        static let DATASTORE_NAME = "com.adobe.module.configuration"
        
        enum DataStoreKeys: String, CaseIterable {
            case OVERRIDDEN_MAP = "config.overridden.map"
            case APP_ID = "config.appID"
        }
    }
    
    enum Lifecycle {
        static let DATASTORE_NAME = "com.adobe.module.lifecycle"
        
        enum DataStoreKeys: String, CaseIterable {
            case INSTALL_DATE = "install.date"
            case LAST_LAUNCH_DATE = "last.date.used"
            case UPGRADE_DATE = "upgrade.date"
            case LAUNCHES_SINCE_UPGRADE = "launches.after.upgrade"
            case PERSISTED_CONTEXT = "persisted.context"
            case LIFECYCLE_DATA = "lifecycle.data"
            case LAST_VERSION = "last.version"
            case V2_LAST_VERSION = "v2.last.app.version"
            case V2_APP_START_DATE = "v2.app.start.date"
            case V2_APP_PAUSE_DATE = "v2.app.pause.date"
            case V2_APP_CLOSE_DATE = "v2.app.close.date"
        }
    }
    
    enum Identity {
        static let DATASTORE_NAME = "com.adobe.module.identity"
        
        enum DataStoreKeys: String, CaseIterable {
            case IDENTITY_PROPERTIES = "identity.properties"
            case PUSH_ENABLED = "push.enabled"
            case ANALYTICS_PUSH_ENABLED = "analytics.push.enabled"
        }
    }
    
    enum Assurance {
        static let DATASTORE_NAME = "com.adobe.module.assurance"
        
        enum DataStoreKeys: String, CaseIterable {
            case CLIENT_ID = "assurance.client.Id"
            case ENVIRONMENT = "assurance.environment"
            case SOCKET_URL = "assurance.socketurl"
            case MODIFIED_CONFIG_KEYS = "assurance.control.modifiedConfigKeys"
        }
    }
    
    enum Analytics {
        static let DATASTORE_NAME = "com.adobe.module.analytics"
        
        enum DataStoreKeys: String, CaseIterable {
            case LAST_HIT_TS = "mostrecenthittimestamp"
            case AID = "aid"
            case VID = "vid"
            case DATA_MIGRATED = "data.migrated"
        }
    }
    
    enum Audience {
        static let DATASTORE_NAME = "com.adobe.module.audience"
        
        enum DataStoreKeys: String, CaseIterable {
            case USER_PROFILE = "AAMUserProfile"
            case USER_ID = "AAMUserId"
        }
    }
    
    enum Target {
        static let DATASTORE_NAME = "com.adobe.module.target"
        
        enum DataStoreKeys: String, CaseIterable {
            case SESSION_TIMESTAMP = "session.timestamp"
            case SESSION_ID = "session.id"
            case TNT_ID = "tnt.id"
            case EDGE_HOST = "edge.host"
            case THIRD_PARTY_ID = "thirdparty.id"
        }
    }
    
    enum Campaign {
        static let DATASTORE_NAME = "com.adobe.module.campaign"
        
        enum DataStoreKeys: String, CaseIterable {
            case REMOTE_URL = "CampaignRemoteUrl"
            case ECID = "ExperienceCloudId"
            case REGISTRATION_TS = "CampaignRegistrationTimestamp"
        }
    }
    
    enum CampaignClassic {
        static let DATASTORE_NAME = "com.adobe.module.campaignclassic"
        
        enum DataStoreKeys: String, CaseIterable {
            case TOKEN_HASH = "ADOBEMOBILE_STOREDDEFAULTS_TOKENHASH"
        }
    }
    
    enum Places {
        static let DATASTORE_NAME = "PlacesDataStore"
        
        enum DataStoreKeys: String, CaseIterable {
            case ACCURACY = "places_accuracy"
            case AUTH_STATUS = "places_auth_status"
            case CURRENT_POI = "places_current_poi"
            case LAST_ENTERED_POI = "places_last_entered_poi"
            case LAST_EXITED_POI = "places_last_exited_poi"
            case LAST_KNOWN_LATITUDE = "places_last_known_latitude"
            case LAST_KNOWN_LONGITUDE = "places_last_known_longitude"
            case MEMBERSHIP = "places_membership_valid_until"
            case NEARBY_POIS = "places_nearby_pois"
            case USER_WITHIN_POIS = "places_user_within_pois"
        }
    }
    
    enum UserProfile {
        static let DATASTORE_NAME = "com.adobe.module.userProfile"
        
        enum DataStoreKeys: String, CaseIterable {
            case ATTRIBUTES = "attributes"
        }
    }
    
    enum Edge {
        static let DATASTORE_NAME = "com.adobe.edge"
        static let PAYLOAD_DATASTORE_NAME = "AEPEdge"
        
        enum EdgeDataStoreKeys: String, CaseIterable {
            case RESET_IDENTITIES_DATE = "reset.identities.date"
            case EDGE_PROPERTIES = "edge.properties"
        }
        
        enum EdgePayloadStoreKeys: String, CaseIterable {
            case STORE_PAYLOADS = "storePayloads"
        }
    }
    
    enum EdgeIdentity {
        static let DATASTORE_NAME = "com.adobe.edge.identity"
        
        enum DataStoreKeys: String, CaseIterable {
            case IDENTITY_PROPERTIES = "identity.properties"
        }
    }
    
    enum EdgeConsent {
        static let DATASTORE_NAME = "com.adobe.edge.consent"
        
        enum DataStoreKeys: String, CaseIterable {
            case CONSENT_PREFERENCES = "consent.preferences"
        }
    }
}
