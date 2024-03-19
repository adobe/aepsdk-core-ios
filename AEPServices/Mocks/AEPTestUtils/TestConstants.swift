//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

public enum TestConstants {

    public enum EventName {
        public static let CONTENT_COMPLETE = "AEP Response Complete"
    }

    public enum EventType {
        public static let EDGE = "com.adobe.eventType.edge"
        public static let INSTRUMENTED_EXTENSION = "com.adobe.eventType.instrumentedExtension"
        public static let HUB = "com.adobe.eventType.hub"
        public static let CONFIGURATION = "com.adobe.eventType.configuration"
        public static let IDENTITY = "com.adobe.eventType.identity"
        public static let CONSENT = "com.adobe.eventType.edgeConsent"
    }

    public enum EventSource {
        public static let CONTENT_COMPLETE = "com.adobe.eventSource.contentComplete"
        public static let REQUEST_CONTENT = "com.adobe.eventSource.requestContent"
        public static let RESPONSE_CONTENT = "com.adobe.eventSource.responseContent"
        public static let ERROR_RESPONSE_CONTENT = "com.adobe.eventSource.errorResponseContent"
        public static let SHARED_STATE_REQUEST = "com.adobe.eventSource.requestState"
        public static let SHARED_STATE_RESPONSE = "com.adobe.eventSource.responseState"
        public static let UNREGISTER_EXTENSION = "com.adobe.eventSource.unregisterExtension"
        public static let SHARED_STATE = "com.adobe.eventSource.sharedState"
        public static let RESPONSE_IDENTITY = "com.adobe.eventSource.responseIdentity"
        public static let REQUEST_IDENTITY = "com.adobe.eventSource.requestIdentity"
        public static let BOOTED = "com.adobe.eventSource.booted"
        public static let LOCATION_HINT_RESULT = "locationHint:result"
        public static let STATE_STORE = "state:store"
    }

    public enum EventDataKey {
        public static let STATE_OWNER = "stateowner"
        public static let STATE = "state"
    }

    public enum SharedState {
        public static let CONFIGURATION = "com.adobe.module.configuration"
        public static let IDENTITY = "com.adobe.edge.identity"
    }
    public enum Defaults {
        public static let WAIT_EVENT_TIMEOUT: TimeInterval = 2
        public static let WAIT_SHARED_STATE_TIMEOUT: TimeInterval = 3
        public static let WAIT_NETWORK_REQUEST_TIMEOUT: TimeInterval = 2
        public static let WAIT_TIMEOUT: UInt32 = 1 // used when no expectation is set
    }

    public enum DataStoreKeys {
        public static let STORE_NAME = "AEPEdge"
        public static let STORE_PAYLOADS = "storePayloads"
    }

    public static let EX_EDGE_INTERACT_PROD_URL_STR = "https://edge.adobedc.net/ee/v1/interact"
    public static let EX_EDGE_INTERACT_PRE_PROD_URL_STR = "https://edge.adobedc.net/ee-pre-prd/v1/interact"
    public static let EX_EDGE_INTERACT_INTEGRATION_URL_STR = "https://edge-int.adobedc.net/ee/v1/interact"

    public static let EX_EDGE_CONSENT_PROD_URL_STR = "https://edge.adobedc.net/ee/v1/privacy/set-consent"
    public static let EX_EDGE_CONSENT_PRE_PROD_URL_STR = "https://edge.adobedc.net/ee-pre-prd/v1/privacy/set-consent"
    public static let EX_EDGE_CONSENT_INTEGRATION_URL_STR = "https://edge-int.adobedc.net/ee/v1/privacy/set-consent"

    public static let EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC = "https://edge.adobedc.net/ee/or2/v1/interact"
    public static let OR2_LOC = "or2"

    public static let EX_EDGE_MEDIA_PROD_URL_STR = "https://edge.adobedc.net/ee/va/v1/sessionstart"
    public static let EX_EDGE_MEDIA_PRE_PROD_URL_STR = "https://edge.adobedc.net/ee-pre-prd/va/v1/sessionstart"
    public static let EX_EDGE_MEDIA_INTEGRATION_URL_STR = "https://edge-int.adobedc.net/ee/va/v1/sessionstart"
}
