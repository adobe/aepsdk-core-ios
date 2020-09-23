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

@testable import AEPCore
@testable import AEPIdentity
import AEPServices
import AEPServicesMocks
import XCTest

class IdentityTests: XCTestCase {
    var identity: Identity!
    var mockRuntime: TestableExtensionRuntime!

    override func setUp() {
        ServiceProvider.shared.networkService = MockNetworkServiceOverrider()
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        mockRuntime = TestableExtensionRuntime()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()
    }

    /// Tests that when identity receives a identity request identity event with the base url that we dispatch a response event with the updated url
    func testIdentityRequestAppendUrlHappy() {
        // setup
        let appendUrlEvent = Event(name: "Test Append URL Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: "test-url"])
        mockRuntime.simulateSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: appendUrlEvent, data: (["testKey": "testVal"], .set))

        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: { $0.responseID == appendUrlEvent.id })
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data?[IdentityConstants.EventDataKeys.UPDATED_URL])
    }

    /// Tests that when identity receives a identity request identity event and no config is available that we do not dispatch a response event
    func testIdentityRequestAppendUrlNoConfig() {
        // setup
        let appendUrlEvent = Event(name: "Test Append URL Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: "test-url"])

        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: { $0.responseID == appendUrlEvent.id })
        XCTAssertNil(responseEvent)
    }

    /// Tests that when identity receives a identity request identity event with url variables that we dispatch a response event with the url variables
    func testIdentityRequestGetUrlVariablesHappy() {
        // setup
        let appendUrlEvent = Event(name: "Test Get URL Variables Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])
        mockRuntime.simulateSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: appendUrlEvent, data: (["testKey": "testVal"], .set))

        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: { $0.responseID == appendUrlEvent.id })
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data?[IdentityConstants.EventDataKeys.URL_VARIABLES])
    }

    /// Tests that when identity receives a identity request identity event and no config is available that we do not dispatch a response event
    func testIdentityRequestGetUrlVariablesEmptyConfig() {
        // setup
        let appendUrlEvent = Event(name: "Test Get URL Variables Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: { $0.responseID == appendUrlEvent.id })
        XCTAssertNil(responseEvent)
    }

    /// Tests that when identity receives a identity request identity event with empty event data that we dispatch a response event with the identifiers
    func testIdentityRequestIdentifiersHappy() {
        // setup
        let appendUrlEvent = Event(name: "Test Request Identifiers", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        mockRuntime.simulateSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: appendUrlEvent, data: (["testKey": "testVal"], .set))

        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: { $0.responseID == appendUrlEvent.id })
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data)
    }

    /// Tests that when identity receives a identity request identity event with empty event data and no config that we dispatch a response event with the identifiers
    func testIdentityRequestIdentifiersNoConfig() {
        // setup
        let appendUrlEvent = Event(name: "Test Request Identifiers", type: EventType.identity, source: EventSource.requestIdentity, data: nil)

        // test
        mockRuntime.simulateComingEvent(event: appendUrlEvent)

        // verify
        let responseEvent = mockRuntime.dispatchedEvents.first(where: { $0.responseID == appendUrlEvent.id })
        XCTAssertNotNil(responseEvent)
        XCTAssertNotNil(responseEvent?.data)
    }

    /// Tests that when a configuration request content event contains opt-out that we send the opt out hit and update privacy status
    func testConfigurationResponseEventOptOut() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let data = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId] as [String: Any]
        let event = Event(name: "Test Configuration response", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (data, .set))
        let _ = identity.readyForEvent(event)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertTrue(mockNetworkService.connectAsyncCalled) // network request for opt-out hit should have been sent
        XCTAssertEqual(PrivacyStatus.optedOut, identity.state?.identityProperties.privacyStatus) // identity state should have updated to opt-out
        XCTAssertEqual(testOrgId, identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String) // last valid config should have been updated with the org id
    }

    /// Tests that when a configuration request content event contains opt-out but missing orgId that we do not send a network request
    func testConfigurationResponseEventOptOutMissingOrgId() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let data = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue] as [String: Any]
        let event = Event(name: "Test Configuration response", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (data, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertFalse(mockNetworkService.connectAsyncCalled) // network request for opt-out hit should have NOT been sent
        XCTAssertEqual(PrivacyStatus.optedOut, identity.state?.identityProperties.privacyStatus) // identity state should have updated to opt-out
    }

    /// Tests that when a configuration request content event contains opt-in that we do not send the opt out hit
    func testConfigurationResponseEventOptIn() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let data = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId] as [String: Any]
        let event = Event(name: "Test Configuration response", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (data, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertFalse(mockNetworkService.connectAsyncCalled) // network request for opt-out hit should have NOT been sent
        XCTAssertEqual(PrivacyStatus.optedIn, identity.state?.identityProperties.privacyStatus) // identity state should have updated to opt-in
        XCTAssertEqual(testOrgId, identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String) // last valid config should have been updated with the org id
    }

    /// Tests that when a configuration request content event contains unknown privacy status that we do not send the opt out hit
    func testConfigurationResponseEventUnknown() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let data = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.unknown.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId] as [String: Any]
        let event = Event(name: "Test Configuration response", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (data, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertFalse(mockNetworkService.connectAsyncCalled) // network request for opt-out hit should have NOT been sent
        XCTAssertEqual(PrivacyStatus.unknown, identity.state?.identityProperties.privacyStatus) // identity state should have remained unknown
        XCTAssertEqual(testOrgId, identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String) // last valid config should have been updated with the org id
    }

    /// Tests that when no privacy status is in the configuration event that we do not update the privacy status
    func testConfigurationResponseEventNoPrivacyStatus() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.privacyStatus = .optedIn
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let data = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId] as [String: Any]
        let event = Event(name: "Test Configuration response", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (data, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertFalse(mockNetworkService.connectAsyncCalled) // network request for opt-out hit should have NOT been sent
        XCTAssertEqual(testOrgId, identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String) // last valid config should have been updated with the org id
    }

    /// Tests that when the the event does not contain an org id that we do not update the last valid config
    func testConfigurationResponseEventNoOrgId() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let data = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.unknown.rawValue] as [String: Any]
        let event = Event(name: "Test Configuration response", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (data, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertFalse(mockNetworkService.connectAsyncCalled) // network request for opt-out hit should have NOT been sent
        XCTAssertEqual(PrivacyStatus.unknown, identity.state?.identityProperties.privacyStatus) // identity state should have remained unknown
        XCTAssertNil(identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String) // last valid config should have NOT been updated with the org id
    }
}
