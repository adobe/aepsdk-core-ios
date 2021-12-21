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
@testable import AEPIdentity
@testable import AEPCoreMocks

class IdentityAPITests: XCTestCase {

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
        let expectedUrl = URL(string: "https://www.adobe.com/")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            XCTAssertEqual(expectedUrl?.absoluteString, event.data?[IdentityConstants.EventDataKeys.BASE_URL] as? String)
            expectation.fulfill()
        }

        // test
        Identity.appendTo(url: expectedUrl) { (url, error) in }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that getIdentifiers dispatches an identity request identity event
    func testGetIdentifiers() {
        // setup
        let expectation = XCTestExpectation(description: "getIdentifiers should dispatch an event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            expectation.fulfill()
        }

        // test
        Identity.getIdentifiers { (identifiers, error) in }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testGetIdentifiers_returnsIdentifiers_whenIdentifiersInResponse() {
        // setup
        let expectation = XCTestExpectation(description: "getIdentifiers should dispatch an event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            var props = IdentityProperties()
            props.customerIds = [CustomIdentity(origin: "test-origin", type: "test-type", identifier: "test-id", authenticationState: .authenticated)]
            let response = event.createResponseEvent(name: "test-response", type: EventType.identity, source: EventSource.responseContent, data: props.toEventData())
            EventHub.shared.dispatch(event: response)
        }

        // test
        Identity.getIdentifiers { (identifiers, error) in
            XCTAssertNotNil(identifiers)
            XCTAssertEqual(1, identifiers?.count)
            let customId = identifiers?.first
            XCTAssertEqual("test-id", customId?.identifier)
            XCTAssertEqual("test-type", customId?.type)
            XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, customId?.authenticationState)
            XCTAssertEqual("test-origin", customId?.origin)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testGetIdentifiers_returnsEmptyList_whenNoIdentifiersInResponse() {
        // setup
        let expectation = XCTestExpectation(description: "getIdentifiers should dispatch an event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            var props = IdentityProperties()
            props.ecid = ECID()
            props.advertisingIdentifier = "adId"
            let response = event.createResponseEvent(name: "test-response", type: EventType.identity, source: EventSource.responseContent, data: props.toEventData())
            EventHub.shared.dispatch(event: response)
        }

        // test
        Identity.getIdentifiers { (identifiers, error) in
            XCTAssertNotNil(identifiers)
            XCTAssertEqual(true, identifiers?.isEmpty)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testGetIdentifiers_returnsEmptyList_whenResponseIdentifiersEmpty() {
        // setup
        let expectation = XCTestExpectation(description: "getIdentifiers should dispatch an event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            let eventData = [IdentityConstants.EventDataKeys.VISITOR_IDS_LIST: []]
            let response = event.createResponseEvent(name: "test-response", type: EventType.identity, source: EventSource.responseContent, data: eventData)
            EventHub.shared.dispatch(event: response)
        }

        // test
        Identity.getIdentifiers { (identifiers, error) in
            XCTAssertNotNil(identifiers)
            XCTAssertEqual(true, identifiers?.isEmpty)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testGetIdentifiers_returnsUnexpectedError_whenIdentifiersInResponseAreWrongFormat() {
        // setup
        let expectation = XCTestExpectation(description: "getIdentifiers should dispatch an event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            let eventData = [IdentityConstants.EventDataKeys.VISITOR_IDS_LIST: "Is String but expect Map"]
            let response = event.createResponseEvent(name: "test-response", type: EventType.identity, source: EventSource.responseContent, data: eventData)
            EventHub.shared.dispatch(event: response)
        }

        // test
        Identity.getIdentifiers { (identifiers, error) in
            XCTAssertNil(identifiers)
            XCTAssertNotNil(error)
            XCTAssertEqual(AEPError.unexpected, error as? AEPError)

            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that getExperienceCloudId dispatches an identity request identity event
    func testGetExperienceCloudId() {
        // setup
        let expectation = XCTestExpectation(description: "getExperienceCloudId should dispatch an event")
        expectation.assertForOverFulfill = true
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            expectation.fulfill()
        }

        // test
        Identity.getExperienceCloudId { (id, error) in }

        // verify
        wait(for: [expectation], timeout: 1)
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

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            self.assertSyncEvent(event: event, identifiers: expectedIds, authState: expectedAuthState)
            expectation.fulfill()
        }

        // test
        Identity.syncIdentifier(identifierType: expectedType, identifier: expectedId, authenticationState: expectedAuthState)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that sync identifiers dispatches an event with the correct identifiers and unknown auth state
    func testSyncIdentifiers() {
        // setup
        let expectation = XCTestExpectation(description: "syncIdentifier should dispatch an event")
        expectation.assertForOverFulfill = true

        let expectedIds = ["testType": "testId"]

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            self.assertSyncEvent(event: event, identifiers: expectedIds, authState: .unknown)
            expectation.fulfill()
        }

        // test
        Identity.syncIdentifiers(identifiers: expectedIds)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that sync identifiers dispatches an event with the correct identifiers and auth state
    func testSyncIdentifiersWithAuthState() {
        // setup
        let expectation = XCTestExpectation(description: "syncIdentifier should dispatch an event")
        expectation.assertForOverFulfill = true

        let expectedIds = ["testType": "testId"]
        let expectedAuthState = MobileVisitorAuthenticationState.loggedOut

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            self.assertSyncEvent(event: event, identifiers: expectedIds, authState: expectedAuthState)
            expectation.fulfill()
        }

        // test
        Identity.syncIdentifiers(identifiers: expectedIds, authenticationState: expectedAuthState)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that getUrlVariables dispatches an identity request identity event with correct data
    func testGetUrlVariables() {
        // setup
        let expectation = XCTestExpectation(description: "getUrlVariables should dispatch an event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.identity, source: EventSource.requestIdentity) { (event) in
            XCTAssertTrue(event.data?[IdentityConstants.EventDataKeys.URL_VARIABLES] as? Bool ?? false)
            expectation.fulfill()
        }

        // test
        Identity.getUrlVariables { (variables, error) in }

        // verify
        wait(for: [expectation], timeout: 1)
    }
}
