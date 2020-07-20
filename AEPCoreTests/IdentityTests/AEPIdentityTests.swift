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
@testable import AEPEventHub

class AEPIdentityTests: XCTestCase {

    var identity: AEPIdentity!
    var mockRuntime: TestableExtensionRuntime!
    
    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        identity = AEPIdentity(runtime: mockRuntime)
        identity.onRegistered()
    }
    
    /// Tests that when identity receives a identity request identity event with the base url that we dispatch a response event with the updated url
    func testIdentityRequestAppendUrlHappy() {
        // setup
        let appendUrlEvent = Event(name: "Test Append URL Event", type: .identity, source: .requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: "test-url"])
        mockRuntime.simulateSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: appendUrlEvent, data: (["testKey":"testVal"], .set))
        
        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: {$0.responseID == appendUrlEvent.id})
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data?[IdentityConstants.EventDataKeys.UPDATED_URL])
    }
    
    /// Tests that when identity receives a identity request identity event and no config is available that we do not dispatch a response event
    func testIdentityRequestAppendUrlNoConfig() {
        // setup
        let appendUrlEvent = Event(name: "Test Append URL Event", type: .identity, source: .requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: "test-url"])
        
        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: {$0.responseID == appendUrlEvent.id})
        XCTAssertNil(responseEvent)
    }
    
    /// Tests that when identity receives a identity request identity event with url variables that we dispatch a response event with the url variables
    func testIdentityRequestGetUrlVariablesHappy() {
        // setup
        let appendUrlEvent = Event(name: "Test Get URL Variables Event", type: .identity, source: .requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])
        mockRuntime.simulateSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: appendUrlEvent, data: (["testKey":"testVal"], .set))
        
        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: {$0.responseID == appendUrlEvent.id})
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data?[IdentityConstants.EventDataKeys.URL_VARIABLES])
    }
    
    /// Tests that when identity receives a identity request identity event and no config is available that we do not dispatch a response event
    func testIdentityRequestGetUrlVariablesEmptyConfig() {
        // setup
        let appendUrlEvent = Event(name: "Test Get URL Variables Event", type: .identity, source: .requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])
        
        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: {$0.responseID == appendUrlEvent.id})
        XCTAssertNil(responseEvent)
    }
    
    /// Tests that when identity receives a identity request identity event with empty event data that we dispatch a response event with the identifiers
    func testIdentityRequestIdentifiersHappy() {
        // setup
        let appendUrlEvent = Event(name: "Test Request Identifiers", type: .identity, source: .requestIdentity, data: nil)
        mockRuntime.simulateSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: appendUrlEvent, data: (["testKey":"testVal"], .set))
        
        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: {$0.responseID == appendUrlEvent.id})
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data)
    }
    
    /// Tests that when identity receives a identity request identity event with empty event data and no config that we dispatch a response event with the identifiers
    func testIdentityRequestIdentifiersNoConfig() {
        // setup
        let appendUrlEvent = Event(name: "Test Request Identifiers", type: .identity, source: .requestIdentity, data: nil)
        
        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: {$0.responseID == appendUrlEvent.id})
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data)
    }

}
