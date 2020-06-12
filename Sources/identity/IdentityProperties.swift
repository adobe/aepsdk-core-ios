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

/// Represents a type which contains instances variables for the Identity extension
struct IdentityProperties: Codable {
    
    /// The current Experience Cloud ID
    var mid: MID?
    
    /// The IDFA from retrieved Apple APIs
    var advertisingIdentifier: String?
    
    /// The SHA1 hashed push Identifier
    var pushIdentifier: String?
    
    /// The Blob value
    var blob: String?
    
    /// The Experience Cloud ID service region ID. A region ID (or location hint), is a numeric identifier for the geographic location of a particular ID service data center
    var locationHint: String?
    
    /// List of all the customer's customer identifiers
    var customerIds: [CustomIdentity]?
    
    /// Date of the last sync with the identity service
    var lastSync: Date?
    
    /// Time to live value
    var ttl = IdentityConstants.DEFAULT_TTL
    
    /// The current privacy status provided by the Configuration extension, defaults to `unknown`
    var privacyStatus = PrivacyStatus.unknown
    
    /// Converts `IdentityProperties` into an event data representation
    /// - Returns: A dictionary representing this `IdentityProperties`
    func toEventData() -> [String: Any] {
        var eventData = [String: Any]()
        eventData[IdentityConstants.EventDataKeys.VISITOR_ID_MID] = mid?.midString
        eventData[IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] = advertisingIdentifier
        eventData[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] = pushIdentifier
        eventData[IdentityConstants.EventDataKeys.VISITOR_ID_BLOB] = blob
        eventData[IdentityConstants.EventDataKeys.VISITOR_ID_LOCATION_HINT] = locationHint
        eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] = customerIds
        eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LAST_SYNC] = lastSync
        
        return eventData
    }
}
