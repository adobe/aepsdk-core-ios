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
import AEPCore
@testable import AEPIdentity
import AEPCoreMocks
import AEPServices
import AEPServicesMocks

class IdentityFunctionalTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var identity: Identity!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: syncIdentifiers(...) tests

    /// Tests that a sync event dispatches a shared state update
    func testSyncIdentifiersSyncEvent() {
        // setup
        identity.state?.lastValidConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
        let data = [IdentityConstants.EventDataKeys.IS_SYNC_EVENT: true]
        let event = Event(name: "Sync Event", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let sharedState = mockRuntime.createdSharedStates.last!
        XCTAssertNotNil(sharedState?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID])
    }

    /// Tests that a generic event dispatches a shared state update
    func testSyncIdentifiersGenericIdentity() {
        // setup
        identity.state?.lastValidConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
        let event = Event(name: "Generic Identity", type: EventType.genericIdentity, source: EventSource.requestContent, data: nil)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let sharedState = mockRuntime.createdSharedStates.last!
        XCTAssertNotNil(sharedState?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID])
    }

    /// Tests that when opted out that we do not make a shared state update
    func testSyncIdentifiersSyncEventOptedOut() {
        // setup
        identity.state?.lastValidConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
        let data = [IdentityConstants.EventDataKeys.IS_SYNC_EVENT: true]
        let event = Event(name: "Sync Event", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertTrue(mockRuntime.createdSharedStates.isEmpty)
    }

    // MARK: processAppendToUrl(...) tests

    /// Tests that appendToUrl dispatches the correct event with the URL in data
    func testAppendToUrl() {
        // setup
        let expectedUrl = URL(string: "https://www.adobe.com/")
        let data = [IdentityConstants.EventDataKeys.BASE_URL: expectedUrl?.absoluteString ?? ""]
        let event = Event(name: "Append to URL", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        XCTAssertNotNil(dispatchedEvent?.data?[IdentityConstants.EventDataKeys.UPDATED_URL])
    }

    /// Tests that appendToUrl does not dispatch an event when no valid config is present
    func testAppendToUrlNoValidConfig() {
        // setup
        let expectedUrl = URL(string: "https://www.adobe.com/")
        let data = [IdentityConstants.EventDataKeys.BASE_URL: expectedUrl?.absoluteString ?? ""]
        let event = Event(name: "Append to URL", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertTrue(mockRuntime.dispatchedEvents.isEmpty)
    }

    /// Tests that this event is ignored when the current config is opted out
    func testAppendToUrlOptedOut() {
        // setup
        let expectedUrl = URL(string: "https://www.adobe.com/")
        let data = [IdentityConstants.EventDataKeys.BASE_URL: expectedUrl?.absoluteString ?? ""]
        let event = Event(name: "Append to URL", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertTrue(mockRuntime.dispatchedEvents.isEmpty)
    }

    // MARK: processGetUrlVariables(...) tests

    /// Tests that getUrlVariables dispatches an event with the url variables
    func testGetUrlVariables() {
        // setup
        let event = Event(name: "Get URL variables", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        XCTAssertNotNil(dispatchedEvent?.data?[IdentityConstants.EventDataKeys.URL_VARIABLES])
    }

    /// Tests that getUrlVariables does not dispatch an event when no valid config is present
    func testGetUrlVariablesNoValidConfig() {
        // setup
        let event = Event(name: "Get URL variables", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertTrue(mockRuntime.dispatchedEvents.isEmpty)
    }

    /// Tests that getUrlVariables does not dispatch an event when the user is opted out
    func testGetUrlVariablesOptedOut() {
        // setup
        let event = Event(name: "Get URL variables", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertTrue(mockRuntime.dispatchedEvents.isEmpty)
    }

    // MARK: processIdentifiersRequest(...) tests

    /// Tests that processIdentifiers dispatches an event
    func testProcessIdentifiers() {
        // setup
        let event = Event(name: "Get Identifiers", type: EventType.identity, source: EventSource.requestIdentity, data: nil)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
    }

    /// Tests that processIdentifiers does not dispatch an event when the user is opted out
    func testProcessIdentifiersOptedOut() {
        // setup
        let event = Event(name: "Get Identifiers", type: EventType.identity, source: EventSource.requestIdentity, data: nil)

        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertTrue(mockRuntime.dispatchedEvents.isEmpty)
    }

    // MARK: receiveConfigurationIdentity(...) tests

    /// Tests that an event of type configuration and source request identity cause an event to be dispatched with the SDK identities
    func testReceiveConfigurationIdentity() {
        // setup
        let event = Event(name: "GetSdkIdentities", type: EventType.configuration, source: EventSource.requestIdentity, data: nil)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.configuration, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        XCTAssertNotNil(dispatchedEvent?.data?[IdentityConstants.Configuration.ALL_IDENTIFIERS])
    }

    /// Tests that an event of type configuration and source request identity is ignored when the config privacy is opted out
    func testReceiveConfigurationIdentityOptedOut() {
        // setup
        let event = Event(name: "GetSdkIdentities", type: EventType.configuration, source: EventSource.requestIdentity, data: nil)
        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertNotNil(mockRuntime.dispatchedEvents.first) // empty event should have been dispatched
        XCTAssertNil(mockRuntime.dispatchedEvents.first?.data) // data should be nil
    }

    // MARK: handleConfigurationResponse(...) tests

    /// Tests that when Identity gets a configuration response event that the privacy and orig id are updated
    func testHandleConfigurationResponse() {
        // setup
        let newConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "new-org-id", "test-key": "test-val"]
        let event = Event(name: "Config Response Event", type: EventType.configuration, source: EventSource.responseContent, data: newConfig)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertEqual(PrivacyStatus.optedIn.rawValue, identity.state?.lastValidConfig[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? String)
        XCTAssertEqual("new-org-id", identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String)
        XCTAssertEqual("test-val", identity.state?.lastValidConfig["test-key"] as? String)
    }
}
