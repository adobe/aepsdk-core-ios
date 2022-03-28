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

    override func tearDown() {
        identity.onUnregistered()
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

    /// Tests that when the event does not contain an org id that we do not update the last valid config
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

    /// Tests that when the event contains an AAM server then no opt out request is sent
    func testConfigurationResponseEventOptOutWhenAamServerIsConfigured() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let data = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId, IdentityConstants.Configuration.AAM_CONFIG_SERVER: "testServer.com"] as [String: Any]
        let event = Event(name: "Test Configuration response", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (data, .set))
        let _ = identity.readyForEvent(event)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify no network request is sent because there is an AAM server configured
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertFalse(mockNetworkService.connectAsyncCalled) // network request for opt-out hit shouldn't have been sent
        XCTAssertEqual(PrivacyStatus.optedOut, identity.state?.identityProperties.privacyStatus) // identity state should have updated to opt-out
        XCTAssertEqual(testOrgId, identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String) // last valid config should have been updated with the org id
    }

    /// Tests that when the event contains opt out hit sent == false then the Identity Extension sends an opt out request
    func testAudienceResponseEventOptOutHitSentIsFalse() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let configData = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId, IdentityConstants.Configuration.AAM_CONFIG_SERVER: "testServer.com"] as [String: Any]
        let audienceResponseEventData = [IdentityConstants.Audience.OPTED_OUT_HIT_SENT: false]
        let event = Event(name: "Test Audience response", type: EventType.audienceManager, source: EventSource.responseContent, data: audienceResponseEventData)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (configData, .set))
        let _ = identity.readyForEvent(event)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify network request is sent
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertTrue(mockNetworkService.connectAsyncCalled) // network request for opt-out hit should have been sent
    }

    /// Tests Identity Extension sends an opt out request to default demdex server when configuration experience.server has empty string value
    func testAudienceResponseEventOptOutHitSentIsFalse_ExperienceServerURLEmpty() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let configData = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId, IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: ""] as [String: Any]
        let audienceResponseEventData = [IdentityConstants.Audience.OPTED_OUT_HIT_SENT: false]
        let event = Event(name: "Test Audience response", type: EventType.audienceManager, source: EventSource.responseContent, data: audienceResponseEventData)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (configData, .set))
        let _ = identity.readyForEvent(event)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify network request is sent
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        let optOutHitHost = mockNetworkService.connectAsyncCalledWithNetworkRequest?.url.host ?? "" // network request for opt-out hit should have been sent
        XCTAssertTrue(optOutHitHost.contains("dpm.demdex.net"))
    }

    /// Tests Identity Extension sends an opt out request to default demdex server when configuration experience.server has invalid non-string value
    func testAudienceResponseEventOptOutHitSentIsFalse_ExperienceServerURLInvalid() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let configData = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId, IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: 100] as [String: Any]
        let audienceResponseEventData = [IdentityConstants.Audience.OPTED_OUT_HIT_SENT: false]
        let event = Event(name: "Test Audience response", type: EventType.audienceManager, source: EventSource.responseContent, data: audienceResponseEventData)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (configData, .set))
        let _ = identity.readyForEvent(event)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify network request is sent
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        let optOutHitHost = mockNetworkService.connectAsyncCalledWithNetworkRequest?.url.host ?? "" // network request for opt-out hit should have been sent
        XCTAssertTrue(optOutHitHost.contains("dpm.demdex.net"))
    }

    /// Tests Identity Extension sends an opt out request to default demdex server when configuration experience.server has proper non-empty string value
    func testAudienceResponseEventOptOutHitSentIsFalse_ExperienceServerValid() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let configData = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId, IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "example.com"] as [String: Any]
        let audienceResponseEventData = [IdentityConstants.Audience.OPTED_OUT_HIT_SENT: false]
        let event = Event(name: "Test Audience response", type: EventType.audienceManager, source: EventSource.responseContent, data: audienceResponseEventData)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (configData, .set))
        let _ = identity.readyForEvent(event)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify network request is sent
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        let optOutHitHost = mockNetworkService.connectAsyncCalledWithNetworkRequest?.url.host ?? "" // network request for opt-out hit should have been sent
        XCTAssertTrue(optOutHitHost.contains("example.com"))
    }

    /// Tests that when the event contains opt out hit sent == true then the Identity Extension does not send an opt out request
    func testAudienceResponseEventOptOutHitSentIsTrue() {
        // setup
        var props = IdentityProperties()
        props.ecid = ECID()
        props.saveToPersistence()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()

        let testOrgId = "testOrgId"
        let configData = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: testOrgId, IdentityConstants.Configuration.AAM_CONFIG_SERVER: "testServer.com"] as [String: Any]
        let audienceResponseEventData = [IdentityConstants.Audience.OPTED_OUT_HIT_SENT: true]
        let event = Event(name: "Test Audience response", type: EventType.audienceManager, source: EventSource.responseContent, data: audienceResponseEventData)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, data: (configData, .set))
        let _ = identity.readyForEvent(event)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify no network request is sent
        let mockNetworkService = ServiceProvider.shared.networkService as! MockNetworkServiceOverrider
        XCTAssertFalse(mockNetworkService.connectAsyncCalled) // network request for opt-out hit shouldn't have been sent
    }

    /// Tests that when receives a valid analytics event and response identity event source that we dispatch an Avid Sync event
    func testAnalyticsResponseIdentityHappy() {
        // setup
        let eventData = [IdentityConstants.Analytics.ANALYTICS_ID: "aid" ] as [String: Any]
        let event = Event(name: "Test Analytics Response Identity", type: EventType.analytics, source: EventSource.responseIdentity, data: eventData)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let actualEvent = mockRuntime.dispatchedEvents.first(where: { $0.source == EventSource.requestIdentity })
        XCTAssertNotNil(actualEvent)
        XCTAssertNotNil(actualEvent?.id)
        XCTAssertEqual(IdentityConstants.EventNames.AVID_SYNC_EVENT, actualEvent?.name)
        XCTAssertEqual(EventType.identity, actualEvent?.type)
        let identifierValue = [IdentityConstants.EventDataKeys.ANALYTICS_ID: "aid" ] as [String: String]
        XCTAssertEqual(identifierValue, actualEvent?.data?[IdentityConstants.EventDataKeys.IDENTIFIERS]as? [String: String] )
        XCTAssertEqual(false, actualEvent?.data?[IdentityConstants.EventDataKeys.FORCE_SYNC]as? Bool)
        XCTAssertEqual(true, actualEvent?.data?[IdentityConstants.EventDataKeys.IS_SYNC_EVENT]as? Bool)
        XCTAssertEqual(0, actualEvent?.data?[IdentityConstants.EventDataKeys.AUTHENTICATION_STATE]as? Int)
    }

    /// Tests Handle Analytics Response Identity with empty aid that we don't dispatch an event
    func testAnalyticsResponseIdentityWithEmptyAid() {
        // setup
        let eventData = [IdentityConstants.Analytics.ANALYTICS_ID: "" ] as [String: Any]
        let event = Event(name: "Test Analytics Response Identity", type: EventType.analytics, source: EventSource.responseIdentity, data: eventData)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let actualEvent = mockRuntime.dispatchedEvents.first(where: { $0.source == EventSource.requestIdentity })
        XCTAssertNil(actualEvent)
    }

    /// Tests Handle Analytics Response Identity with no aid key that we don't dispatch an event
    func testAnalyticsResponseIdentityWithNoAid() {
        // setup
        let eventData = ["key": "aid" ] as [String: Any]
        let event = Event(name: "Test Analytics Response Identity", type: EventType.analytics, source: EventSource.responseIdentity, data: eventData)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let actualEvent = mockRuntime.dispatchedEvents.first(where: { $0.source == EventSource.requestIdentity })
        XCTAssertNil(actualEvent)
    }

    /// Tests Handle Analytics Response Identity with no event data that we don't dispatch an event
    func testAnalyticsResponseIdentityWithNoEventData() {
        // setup
        let event = Event(name: "Test Analytics Response Identity", type: EventType.analytics, source: EventSource.responseIdentity, data: nil)

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        let actualEvent = mockRuntime.dispatchedEvents.first(where: { $0.source == EventSource.requestIdentity })
        XCTAssertNil(actualEvent)
    }

    func testReadyForEventBootupInvalidThenValidConfig() {
        // set initial config to invalid
        let firstEvent = Event(name: "test-event", type: "test-type", source: "test-source", data: nil)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: firstEvent, data: (["invalid": "config"], .set))

        // expect false, due to invalid config
        XCTAssertFalse(identity.readyForEvent(firstEvent))

        // update to valid config
        let secondEvent = Event(name: "test-event", type: "test-type", source: "test-source", data: nil)
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: secondEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))

        // expect true since identity has fast boot
        XCTAssertTrue(identity.readyForEvent(firstEvent))
    }

    // analytics shared state pending
    func testReadyForEventIdentifierRequestAppendToUrlWaitForAnalyticsSharedState() {

        let appendUrlEvent = Event(name: "Test Append URL Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: "test-url"])

        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: appendUrlEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))

        // verify
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: appendUrlEvent, data: ([IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"], .pending))

        XCTAssertFalse(identity.readyForEvent(appendUrlEvent)) // booting up
        XCTAssertFalse(identity.readyForEvent(appendUrlEvent))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: appendUrlEvent, data: ([IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"], .none))

        XCTAssertFalse(identity.readyForEvent(appendUrlEvent)) // booting up
        XCTAssertFalse(identity.readyForEvent(appendUrlEvent))
    }

    // analytics shared state available
    func testReadyForEventIdentifierRequestAppendToUrlWhenAnalyticsSharedStateIsSet() {

        let appendUrlEvent = Event(name: "Test Append URL Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: "test-url"])

        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: appendUrlEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: appendUrlEvent, data: ([IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"], .set))

        // verify
        XCTAssertTrue(identity.readyForEvent(appendUrlEvent)) // fast boot
    }

    // analytics shared state pending
    func testReadyForEventIdentifierRequestGetUrlVariablesForAnalyticsSharedState() {
        let getUrlVariablesEvent = Event(name: "Test Get URL Variables Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: getUrlVariablesEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: getUrlVariablesEvent, data: ([IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"], .pending))

        // verify
        XCTAssertFalse(identity.readyForEvent(getUrlVariablesEvent)) // booting up
        XCTAssertFalse(identity.readyForEvent(getUrlVariablesEvent))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: getUrlVariablesEvent, data: ([IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"], .none))

        XCTAssertFalse(identity.readyForEvent(getUrlVariablesEvent)) // booting up
        XCTAssertFalse(identity.readyForEvent(getUrlVariablesEvent))
    }

    // analytics shared state available
    func testReadyForEventIdentifierRequestGetUrlVariablesWhenAnalyticsSharedStateIsSet() {

        let getUrlVariablesEvent = Event(name: "Test Get URL Variables Event", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: getUrlVariablesEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: getUrlVariablesEvent, data: ([IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"], .set))

        // verify
        XCTAssertTrue(identity.readyForEvent(getUrlVariablesEvent)) // fast boot
    }

    func testReadyForEventGetEcidOnAppInstallWillWaitForConfigurationAndECIDToBeGenerated() {
        let getEcidEvent = Event(name: "Test Get ECID Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)

        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: getEcidEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))

        // verify
        XCTAssertTrue(identity.readyForEvent(getEcidEvent)) // fast boot
    }

    func testReadyForEventGetEcidOnWillWaitForConfigurationWhenEcidIsCached() {
        let getEcidEvent = Event(name: "Test Get ECID Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        // setup
        mockRuntime.simulateSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: getEcidEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue], .set))
        identity.state?.identityProperties.ecid = ECID()

        // verify
        XCTAssertTrue(identity.readyForEvent(getEcidEvent)) //skips booting since ECID is cached
    }
}
