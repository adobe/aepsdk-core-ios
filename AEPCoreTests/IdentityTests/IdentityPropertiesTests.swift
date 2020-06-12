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

import XCTest
@testable import AEPCore

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
        properties.mid = MID()
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
        XCTAssertEqual(properties.mid?.midString, eventData[IdentityConstants.EventDataKeys.VISITOR_ID_MID] as? String)
        XCTAssertEqual(properties.advertisingIdentifier, eventData[IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] as? String)
        XCTAssertEqual(properties.pushIdentifier, eventData[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] as? String)
        XCTAssertEqual(properties.blob, eventData[IdentityConstants.EventDataKeys.VISITOR_ID_BLOB] as? String)
        XCTAssertEqual(properties.locationHint, eventData[IdentityConstants.EventDataKeys.VISITOR_ID_LOCATION_HINT] as? String)
        XCTAssertNotNil(eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity])
        XCTAssertEqual(properties.lastSync?.timeIntervalSince1970, eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LAST_SYNC] as? TimeInterval)
    }

}
