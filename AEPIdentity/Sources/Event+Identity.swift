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

import AEPCore
import Foundation

extension Event {
    /// Returns true if this event is a sync event
    var isSyncEvent: Bool {
        return data?[IdentityConstants.EventDataKeys.IS_SYNC_EVENT] as? Bool ?? false
    }

    /// Reads the push identifier from the event data and packages it into dpids format
    var dpids: [String: String]? {
        guard let pushId = data?[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] as? String else { return nil }
        return [IdentityConstants.EventDataKeys.MCPNS_DPID: pushId]
    }

    /// Reads the identifiers from the event data
    var identifiers: [String: String]? {
        return data?[IdentityConstants.EventDataKeys.IDENTIFIERS] as? [String: String]
    }

    /// Reads the authentication state from the event data
    var authenticationState: MobileVisitorAuthenticationState {
        return data?[IdentityConstants.EventDataKeys.AUTHENTICATION_STATE] as? MobileVisitorAuthenticationState ?? .unknown
    }

    /// Returns true if the event data contains the force sync flag
    var forceSync: Bool {
        return data?[IdentityConstants.EventDataKeys.FORCE_SYNC] as? Bool ?? false
    }

    /// Reads the advertising from the event data and builds a `CustomIdentity`
    var adId: CustomIdentity? {
        var adId = data?[IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] as? String
        // If ad id is all zeros, treat as if null/empty
        if adId == IdentityConstants.Default.ZERO_ADVERTISING_ID {
            adId = ""
        }

        return CustomIdentity(origin: IdentityConstants.VISITOR_ID_PARAMETER_KEY_CUSTOMER,
                              type: IdentityConstants.ADID_DSID,
                              identifier: adId,
                              authenticationState: .authenticated)
    }

    /// Reads the base url from the event data if present
    var baseUrl: String? {
        return data?[IdentityConstants.EventDataKeys.BASE_URL] as? String
    }

    /// Reads the url variables flag from the event data, returns false if not present
    var urlVariables: Bool {
        return data?[IdentityConstants.EventDataKeys.URL_VARIABLES] as? Bool ?? false
    }

    /// Reads the Audience Manager opt-out sent flag, returns false if not present
    var optOutHitSent: Bool {
        return data?[IdentityConstants.Audience.OPTED_OUT_HIT_SENT] as? Bool ?? false
    }

    /// Reads the Analytics id if present in event data
    var aid: String? {
        return data?[IdentityConstants.Analytics.ANALYTICS_ID] as? String
    }

    /// Returns true if the event is either getExperienceCloudId event or getIdentifiers event
    var isGetIdentifierEvent: Bool {
        return type == EventType.identity && source == EventSource.requestIdentity && data?.isEmpty ?? true
    }
}
