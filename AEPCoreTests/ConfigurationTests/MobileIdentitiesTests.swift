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

class MobileIdentitiesTests: XCTestCase {
    
    let configurationSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-orgid"]
    var identitySharedState: [String: Any] {
        return buildIdentitySharedState()
    }
    
    private func buildIdentitySharedState() -> [String: Any] {
        var identitySharedState = [String: Any]()
        identitySharedState[IdentityConstants.EventDataKeys.VISITOR_ID_MID] = "test-mid"
        
        let customIdOne = CustomIdentity(origin: "origin1", type: "type1", identifier: "id1", authenticationState: .authenticated)
        let customIdTwo = CustomIdentity(origin: "origin2", type: "type2", identifier: "id2", authenticationState: .loggedOut)
        let customIdThree = CustomIdentity(origin: "origin3", type: "DSID_20915", identifier: "test-advertisingId", authenticationState: .loggedOut)
        
        identitySharedState[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] = [customIdOne, customIdTwo, customIdThree]
        identitySharedState[IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] = "test-advertisingId"
        identitySharedState[IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] = "test-pushid"
        
        return identitySharedState
    }
    
    // MARK: areSharedStatesReady() tests
    
    /// Tests that when all shared states are pending that we return false
    func testAreSharedStatesReadyAllPending() {
        // setup
        let event = Event(name: "test event", type: .hub, source: .sharedState, data: nil)
        
        // test
        let ready = MobileIdentities().areSharedStatesReady(event: event) { (_, _) -> ((value: [String : Any]?, status: SharedStateStatus)) in
            return (nil, .pending)
        }
        
        // verify
        XCTAssertFalse(ready)
    }
    
    /// Tests that when all shared states set to none that we return false
    func testAreSharedStatesReadyAllNone() {
        // setup
        let event = Event(name: "test event", type: .hub, source: .sharedState, data: nil)
        
        // test
        let ready = MobileIdentities().areSharedStatesReady(event: event) { (_, _) -> ((value: [String : Any]?, status: SharedStateStatus)) in
            return (nil, .none)
        }
        
        // verify
        XCTAssertFalse(ready)
    }
    
    /// Tests that when all shared states are set that we return true
    func testAreSharedStatesReadyAllSet() {
        // setup
        let event = Event(name: "test event", type: .hub, source: .sharedState, data: nil)
        
        // test
        let ready = MobileIdentities().areSharedStatesReady(event: event) { (_, _) -> ((value: [String : Any]?, status: SharedStateStatus)) in
            return (nil, .set)
        }
        
        // verify
        XCTAssertTrue(ready)
    }
    
    // MARK: getAllIdentifiers() tests
    
    /// Tests that when configuration and identity provide shared state that we include them in getAllIdentifiers
    func testGetAllIdentifiersHappy() {
        // setup
        let event = Event(name: "test event", type: .hub, source: .sharedState, data: nil)
        
        // test
        var mobileIdentities = MobileIdentities()
        let identifiers = mobileIdentities.getAllIdentifiers(event: event) { (extensionName, _) -> ((value: [String : Any]?, status: SharedStateStatus)) in
            if extensionName == ConfigurationConstants.EXTENSION_NAME {
                return (configurationSharedState, .set)
            } else if extensionName == IdentityConstants.EXTENSION_NAME {
                return (identitySharedState, .set)
            }
            
            return (nil, .set)
        }
        
        // verify
        let expected = "{\"users\":{\"userIDs\":[{\"namespace\":\"4\",\"value\":\"test-mid\",\"type\":\"namespaceId\"},{\"namespace\":\"type1\",\"value\":\"id1\",\"type\":\"integrationCode\"},{\"namespace\":\"type2\",\"value\":\"id2\",\"type\":\"integrationCode\"},{\"namespace\":\"DSID_20915\",\"value\":\"test-advertisingId\",\"type\":\"integrationCode\"},{\"namespace\":\"20920\",\"value\":\"test-pushid\",\"type\":\"integrationCode\"}]},\"companyContexts\":{\"namespace\":\"imsOrgID\",\"marketingCloudId\":\"test-orgid\"}}"
        XCTAssertEqual(expected, identifiers)
    }
    
    /// Tests that when configuration provides shared state that we include configuration identities in getAllIdentifiers
    func testGetAllIdentifiersOnlyConfiguration() {
        // setup
        let event = Event(name: "test event", type: .hub, source: .sharedState, data: nil)
        
        // test
        var mobileIdentities = MobileIdentities()
        let identifiers = mobileIdentities.getAllIdentifiers(event: event) { (extensionName, _) -> ((value: [String : Any]?, status: SharedStateStatus)) in
            if extensionName == ConfigurationConstants.EXTENSION_NAME {
                return (configurationSharedState, .set)
            }
            
            return (nil, .set)
        }
        
        // verify
        let expected = "{\"companyContexts\":{\"namespace\":\"imsOrgID\",\"marketingCloudId\":\"test-orgid\"}}"
        XCTAssertEqual(expected, identifiers)
    }
    
    /// Tests that when identity provides shared state that we include identity identities in getAllIdentifiers
    func testGetAllIdentifiersOnlyIdentity() {
        // setup
        let event = Event(name: "test event", type: .hub, source: .sharedState, data: nil)
        
        // test
        var mobileIdentities = MobileIdentities()
        let identifiers = mobileIdentities.getAllIdentifiers(event: event) { (extensionName, _) -> ((value: [String : Any]?, status: SharedStateStatus)) in
             if extensionName == IdentityConstants.EXTENSION_NAME {
                return (identitySharedState, .set)
            }
            
            return (nil, .set)
        }
        
        // verify
        let expected = "{\"users\":{\"userIDs\":[{\"namespace\":\"4\",\"value\":\"test-mid\",\"type\":\"namespaceId\"},{\"namespace\":\"type1\",\"value\":\"id1\",\"type\":\"integrationCode\"},{\"namespace\":\"type2\",\"value\":\"id2\",\"type\":\"integrationCode\"},{\"namespace\":\"DSID_20915\",\"value\":\"test-advertisingId\",\"type\":\"integrationCode\"},{\"namespace\":\"20920\",\"value\":\"test-pushid\",\"type\":\"integrationCode\"}]}}"
        XCTAssertEqual(expected, identifiers)
    }

    
}
