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

class AEPIdentityTests: XCTestCase {
    
    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }
    
    private func registerMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { (error) in
            semaphore.signal()
        }

        semaphore.wait()
    }
    
    private func assertSyncEvent(event: Event, identifiers: [String: String]?, authState: MobileVisitorAuthenticationState) {
        XCTAssertEqual(identifiers, event.data?[IdentityConstants.EventDataKeys.IDENTIFIERS] as? [String: String])
        XCTAssertEqual(authState, event.data?[IdentityConstants.EventDataKeys.AUTHENTICATION_STATE] as? MobileVisitorAuthenticationState)
        XCTAssertFalse(event.data?[IdentityConstants.EventDataKeys.FORCE_SYNC] as? Bool ?? true)
        XCTAssertTrue(event.data?[IdentityConstants.EventDataKeys.IS_SYNC_EVENT] as? Bool ?? false)
    }
    
    /// Tests that appendToUrl dispatches the correct event with the URL in data
    func testAppendToUrl() {
        // setup
        let expectation = XCTestExpectation(description: "appendToUrl should dispatch an event")
        expectation.assertForOverFulfill = true
        let expectedUrl = URL(string: "adobe.com")
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .identity, source: .requestIdentity) { (event) in
            XCTAssertEqual(expectedUrl?.absoluteString, event.data?[IdentityConstants.EventDataKeys.BASE_URL] as? String)
            expectation.fulfill()
        }
        
        // test
        AEPIdentity.appendTo(url: expectedUrl) { (url) in }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Tests that getIdentifiers dispatches an identity request identity event
    func testGetIdentifiers() {
        // setup
        let expectation = XCTestExpectation(description: "getIdentifiers should dispatch an event")
        expectation.assertForOverFulfill = true
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .identity, source: .requestIdentity) { (event) in
            expectation.fulfill()
        }
        
        // test
        AEPIdentity.getIdentifiers { (identifiers) in }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Tests that getExperienceCloudId dispatches an identity request identity event
    func testGetExperienceCloudId() {
        // setup
        let expectation = XCTestExpectation(description: "getExperienceCloudId should dispatch an event")
        expectation.assertForOverFulfill = true
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .identity, source: .requestIdentity) { (event) in
            expectation.fulfill()
        }
        
        // test
        AEPIdentity.getExperienceCloudId { (id) in }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Tests that sync identifier dispatches an event with the correct identifiers and auth state
    func testSyncIdentifier() {
        // setup
        let expectation = XCTestExpectation(description: "syncIdentifier should dispatch an event")
        expectation.assertForOverFulfill = true
        
        let expectedType = "testType"
        let expectedId = "testId"
        let expectedIds = [expectedType: expectedId]
        let expectedAuthState = MobileVisitorAuthenticationState.authenticated
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .identity, source: .requestIdentity) { (event) in
            self.assertSyncEvent(event: event, identifiers: expectedIds, authState: expectedAuthState)
            expectation.fulfill()
        }
        
        // test
        AEPIdentity.syncIdentifier(identifierType: expectedType, identifier: expectedId, authenticationState: expectedAuthState)
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Tests that sync identifiers dispatches an event with the correct identifiers and unknown auth state
    func testSyncIdentifiers() {
        // setup
        let expectation = XCTestExpectation(description: "syncIdentifier should dispatch an event")
        expectation.assertForOverFulfill = true
        
        let expectedIds = ["testType": "testId"]
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .identity, source: .requestIdentity) { (event) in
            self.assertSyncEvent(event: event, identifiers: expectedIds, authState: .unknown)
            expectation.fulfill()
        }
        
        // test
        AEPIdentity.syncIdentifiers(identifiers: expectedIds)
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Tests that sync identifiers dispatches an event with the correct identifiers and auth state
    func testSyncIdentifiersWithAuthState() {
        // setup
        let expectation = XCTestExpectation(description: "syncIdentifier should dispatch an event")
        expectation.assertForOverFulfill = true
        
        let expectedIds = ["testType": "testId"]
        let expectedAuthState = MobileVisitorAuthenticationState.loggedOut
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .identity, source: .requestIdentity) { (event) in
            self.assertSyncEvent(event: event, identifiers: expectedIds, authState: expectedAuthState)
            expectation.fulfill()
        }
        
        // test
        AEPIdentity.syncIdentifiers(identifiers: expectedIds, authenticationState: expectedAuthState)
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Tests that getUrlVariables dispatches an identity request identity event with correct data
    func testGetUrlVariables() {
        // setup
        let expectation = XCTestExpectation(description: "getUrlVariables should dispatch an event")
        expectation.assertForOverFulfill = true
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .identity, source: .requestIdentity) { (event) in
            XCTAssertTrue(event.data?[IdentityConstants.EventDataKeys.URL_VARIABLES] as? Bool ?? false)
            expectation.fulfill()
        }
        
        // test
        AEPIdentity.getUrlVariables { (variables) in }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
}
