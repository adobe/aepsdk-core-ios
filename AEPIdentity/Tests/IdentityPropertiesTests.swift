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

@testable import AEPIdentity
import XCTest

class IdentityPropertiesTests: XCTestCase {
    /// When all properties all nil, the event data should be empty
    func testToEventDataEmpty() {
        // setup
        let properties = IdentityProperties()

        // test
        let eventData = properties.toEventData()

        // verify
        XCTAssertTrue(eventData.isEmpty)
    }

    /// Test that event data is populated correctly when all properties are non-nil
    func testToEventDataFull() {
        // setup
        var properties = IdentityProperties()
        properties.ecid = ECID()
        properties.advertisingIdentifier = "test-ad-id"
        properties.pushIdentifier = "test-push-id"
        properties.blob = "test-blob"
        properties.locationHint = "test-location-hint"
        properties.customerIds = [CustomIdentity(origin: "test-origin", type: "test-type", identifier: "test-identifier", authenticationState: .authenticated)]
        properties.lastSync = Date()

        // test
        let eventData = properties.toEventData()

        // verify
        XCTAssertEqual(7, eventData.count)
        XCTAssertEqual(properties.ecid?.ecidString, eventData[IdentityConstants.EventDataKeys.VISITOR_ID_ECID] as? String)
        XCTAssertEqual(properties.advertisingIdentifier, eventData[IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] as? String)
        XCTAssertEqual(properties.pushIdentifier, eventData[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] as? String)
        XCTAssertEqual(properties.blob, eventData[IdentityConstants.EventDataKeys.VISITOR_ID_BLOB] as? String)
        XCTAssertEqual(properties.locationHint, eventData[IdentityConstants.EventDataKeys.VISITOR_ID_LOCATION_HINT] as? String)
        XCTAssertNotNil(eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [[String: Any]])
        XCTAssertEqual(properties.lastSync?.timeIntervalSince1970, eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LAST_SYNC] as? TimeInterval)
    }

    /// Tests that when the existing customer ids and new customer ids are empty that it remains empty
    func testMergeAndCleanCustomerIdsBothEmpty() {
        // setup
        var properties = IdentityProperties()

        // test
        properties.mergeAndCleanCustomerIds([])

        // verify
        XCTAssertTrue(properties.customerIds?.isEmpty ?? true)
    }

    /// Tests that when merging with an empty list of ids that the original list is preserved
    func testMergeAndCleanCustomerIdsEmptyNew() {
        // setup
        var properties = IdentityProperties()
        let existingIds = [CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)]
        properties.customerIds = existingIds

        // test
        properties.mergeAndCleanCustomerIds([])

        // verify
        XCTAssertEqual(existingIds, properties.customerIds)
    }

    /// Tests that when the existing customer ids are empty, that the new ids are set properly
    func testMergeAndCleanCustomerIdsEmptyExisting() {
        // setup
        var properties = IdentityProperties()

        // test
        let newIds = [CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)]
        properties.mergeAndCleanCustomerIds(newIds)

        // verify
        XCTAssertEqual(newIds, properties.customerIds)
    }

    /// Tests that when no duplicate types are found that the lists of `CustomIdentity`'s are combined
    func testMergeAndCleanCustomerIdsNoDuplicates() {
        // setup
        var properties = IdentityProperties()
        let existingIds = [CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)]
        properties.customerIds = existingIds

        // test
        let newIds = [CustomIdentity(origin: "origin", type: "type_1", identifier: "id", authenticationState: .authenticated)]
        properties.mergeAndCleanCustomerIds(newIds)

        // verify
        XCTAssertEqual(existingIds.count + newIds.count, properties.customerIds!.count)
    }

    /// Tests that when two `CustomIdentity`'s have the same value for identifier they are properly merged
    func testMergeAndCleanCustomerIdsSomeDuplicates() {
        // setup
        var properties = IdentityProperties()
        let existingIds = [CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)]
        properties.customerIds = existingIds

        // test
        let newIds = [CustomIdentity(origin: "origin", type: "type", identifier: "id_1", authenticationState: .authenticated),
                      CustomIdentity(origin: "new_origin", type: "new_type", identifier: "id", authenticationState: .loggedOut)]
        properties.mergeAndCleanCustomerIds(newIds)

        // verify
        // can't guarantee order of IDs
        XCTAssertTrue(newIds == properties.customerIds || newIds.reversed() == properties.customerIds)
    }

    /// Tests that `CustomIdentity`'s with an empty identifier are removed after merging
    func testMergeAndCleanCustomerIdsEmptyIdentifiersRemoved() {
        // setup
        var properties = IdentityProperties()
        let existingIds = [CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated),
                           CustomIdentity(origin: "empty", type: "empty", identifier: "", authenticationState: .unknown)]
        properties.customerIds = existingIds

        // test
        let newIds = [CustomIdentity(origin: "origin", type: "type", identifier: "id_1", authenticationState: .authenticated),
                      CustomIdentity(origin: "new_origin", type: "new_type", identifier: "id", authenticationState: .loggedOut)]
        properties.mergeAndCleanCustomerIds(newIds)

        // verify
        // can't guarantee order of IDs
        XCTAssertTrue(newIds == properties.customerIds || newIds.reversed() == properties.customerIds)
    }

    /// When all properties all nil, the XDM data should have an empty top level identity map
    func testToXDMDataEmpty() {
        // setup
        let properties = IdentityProperties()

        // test
        let xdmData = properties.toXDMData()
        let identityMap = xdmData["identityMap"] as? [String: Any]

        // verify
        XCTAssertTrue(identityMap?.isEmpty ?? false)
    }

    /// Test that XDM data is populated correctly when all properties are non-nil
    func testToXDMDataFull() {
        // setup
        var properties = IdentityProperties()
        properties.ecid = ECID()
        properties.advertisingIdentifier = "test-ad-id"
        properties.pushIdentifier = "test-push-id"
        properties.blob = "test-blob"
        properties.locationHint = "test-location-hint"
        properties.customerIds = [CustomIdentity(origin: "test-origin", type: "test-type", identifier: "test-identifier", authenticationState: .authenticated)]
        properties.lastSync = Date()

        // test
        let xdmData = properties.toXDMData()
        let identityMapDict = xdmData["identityMap"] as? [String: Any]
        let identityMapData = try! JSONSerialization.data(withJSONObject: identityMapDict ?? [:], options: [])
        let identityMap = try! JSONDecoder().decode(IdentityMap.self, from: identityMapData)

        let ecidItem = identityMap.getItemsFor(namespace: "ECID")?.first
        let customIdItem = identityMap.getItemsFor(namespace: "test-type")?.first

        // verify
        XCTAssertEqual(properties.ecid!.ecidString, ecidItem?.id)
        XCTAssertEqual(properties.customerIds?.first?.identifier, customIdItem?.id)
    }
}
