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
import AEPServices
import Foundation

/// Represents a type which contains instances variables for the Identity extension
struct IdentityProperties: Codable {
    /// The current Experience Cloud ID
    var ecid: ECID?

    /// The IDFA from retrieved Apple APIs
    var advertisingIdentifier: String? {
        didSet {
            saveToPersistence()
        }
    }

    /// The push Identifier
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
    var ttl = IdentityConstants.Default.TTL

    /// The current privacy status provided by the Configuration extension, defaults to `unknown`
    var privacyStatus = PrivacyStatus.unknown

    /// The aid synced status for handle analytics response event, set defaults to `false`
    var isAidSynced: Bool? = false

    /// Converts `IdentityProperties` into an event data representation
    /// - Returns: A dictionary representing this `IdentityProperties`
    func toEventData() -> [String: Any] {
        var eventData = [String: Any]()
        eventData[IdentityConstants.EventDataKeys.VISITOR_ID_ECID] = ecid?.ecidString
        eventData[IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] = advertisingIdentifier
        eventData[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] = pushIdentifier
        eventData[IdentityConstants.EventDataKeys.VISITOR_ID_BLOB] = blob
        eventData[IdentityConstants.EventDataKeys.VISITOR_ID_LOCATION_HINT] = locationHint
        if let customerIds = customerIds, !customerIds.isEmpty {
            eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] = customerIds.map({$0.asDictionary()})
        }
        eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LAST_SYNC] = lastSync?.timeIntervalSince1970

        return eventData.filter { (_, value) -> Bool in
            // Remove any empty strings from the dictionary
            if value is String, let value = value as? String {
                return !value.isEmpty
            }
            return true
        }
    }

    /// Populates the fields with values stored in the Identity data store
    mutating func loadFromPersistence() {
        let dataStore = NamedCollectionDataStore(name: IdentityConstants.DATASTORE_NAME)
        let savedProperties: IdentityProperties? = dataStore.getObject(key: IdentityConstants.DataStoreKeys.IDENTITY_PROPERTIES)

        if let savedProperties = savedProperties {
            self = savedProperties
        }
    }

    /// Saves this instance of `IdentityProperties` to the Identity data store
    func saveToPersistence() {
        let dataStore = NamedCollectionDataStore(name: IdentityConstants.DATASTORE_NAME)
        dataStore.setObject(key: IdentityConstants.DataStoreKeys.IDENTITY_PROPERTIES, value: self)
    }

    /// Merges `newCustomIds` into `customerIds` by overwriting duplicate identities with new values in `newCustomIds`, and removes any identifiers with an empty or nil identifier
    /// - Parameter newCustomIds: a list of new custom ids to be merged into 1customerIds
    mutating func mergeAndCleanCustomerIds(_ newCustomerIds: [CustomIdentity]) {
        // convert array of IDs to a dict of <identifier, ID>, then merge by taking the new ID for duplicate IDs, then convert back into an array
        customerIds = idListToDict(customerIds).merging(idListToDict(newCustomerIds), uniquingKeysWith: { _, new in new }).map { $0.value }
        customerIds?.removeAll(where: { $0.identifier?.isEmpty ?? true }) // clean all identifiers by removing all that have a nil or empty identifier
    }

    /// Returns a dict where the key is the `identifier` of the identity and the value is the `CustomIdentity`
    /// - Parameter ids: a list of identities
    private func idListToDict(_ ids: [CustomIdentity]?) -> [String?: CustomIdentity] {
        guard let ids = ids else { return [:] }
        return Dictionary(ids.map { ($0.type, $0) }, uniquingKeysWith: {_, new in return new})
    }
}
