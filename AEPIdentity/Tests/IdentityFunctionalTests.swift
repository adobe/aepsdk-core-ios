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
@testable import AEPServices
import AEPServicesMocks

class IdentityFunctionalTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var identity: Identity!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        mockRuntime = TestableExtensionRuntime()
        identity = Identity(runtime: mockRuntime)
        identity.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    override func tearDown() {
        reset()
    }

    func reset() {
        ServiceProvider.shared.reset()
        identity.state?.hitQueue.clear()
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
        identity.state?.lastValidConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        let data = [IdentityConstants.EventDataKeys.IS_SYNC_EVENT: true]
        let event = Event(name: "Sync Event", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertTrue(mockRuntime.createdSharedStates.isEmpty)
    }

    func testSyncIdentifiersResolvesToLastSetConfig() {
        let data = [IdentityConstants.EventDataKeys.IS_SYNC_EVENT: true]
        let syncEvent = Event(name: "Sync Event", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        let lastValidConfigSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue, IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"]

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: syncEvent, data: (lastValidConfigSharedState, .set))

        // set configuration shared state to pending
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: nil, data: (nil, .pending))

        // test sync event
        XCTAssertTrue(identity.readyForEvent(syncEvent))
        mockRuntime.simulateComingEvent(event: syncEvent)

        //verify
        let sharedState = mockRuntime.createdSharedStates.last!
        XCTAssertNotNil(sharedState?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID])
        XCTAssertEqual("test-org-id", identity.state?.lastValidConfig[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String ?? "")

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

    /// Tests that appendToUrl dispatches the correct event with the URL in data will wait for Analytics shared state
    func testAppendToUrlWaitForAnalyticsSharedState() {
        // setup
        let expectedUrl = URL(string: "https://www.adobe.com/")
        let data = [IdentityConstants.EventDataKeys.BASE_URL: expectedUrl?.absoluteString ?? ""]
        let event = Event(name: "Append to URL", type: EventType.identity, source: EventSource.requestIdentity, data: data)

        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))
        let hubSharedState = [IdentityConstants.Hub.EXTENSIONS : [IdentityConstants.SharedStateKeys.ANALYTICS : ["friendlyName" : "Analytics", "version" : "3.0.0"]]]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.eventhub", event: event, data: (hubSharedState, .set))
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: event, data: (analyticsSharedState, .pending))

        // verify
        // identity is not ready for appendToURL event since Analytics shared state is pending
        XCTAssertFalse(identity.readyForEvent(event))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: event, data: (analyticsSharedState, .set))
        XCTAssertTrue(identity.readyForEvent(event))
        mockRuntime.simulateComingEvent(event: event)

        // response is dispatched once Analytics shared state is set
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)

        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        let updatedURL = dispatchedEvent?.data?[IdentityConstants.EventDataKeys.UPDATED_URL] as? String ?? ""
        XCTAssertTrue(updatedURL.contains("test-aid"));
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

    /// Tests that this event is NOT ignored when the current config is opted out
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
        XCTAssertFalse(mockRuntime.dispatchedEvents.isEmpty)
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

    /// Tests that appendToUrl dispatches the correct event with the URL in data will wait for Analytics shared state
    func testGetUrlVariablesWaitForAnalyticsSharedState() {
        // setup
        let event = Event(name: "Get URL variables", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))
        let hubSharedState = [IdentityConstants.Hub.EXTENSIONS : [IdentityConstants.SharedStateKeys.ANALYTICS : ["friendlyName" : "Analytics", "version" : "3.0.0"]]]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.eventhub", event: event, data: (hubSharedState, .set))
        let analyticsSharedState = [IdentityConstants.Analytics.ANALYTICS_ID: "test-aid"]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: event, data: (analyticsSharedState, .pending))

        // verify
        // identity is not ready for getURLVariables event since Analytics shared state is pending
        XCTAssertFalse(identity.readyForEvent(event))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.analytics", event: event, data: (analyticsSharedState, .set))
        XCTAssertTrue(identity.readyForEvent(event))
        mockRuntime.simulateComingEvent(event: event)

        // response is dispatched once Analytics shared state is set
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)

        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        XCTAssertNotNil(dispatchedEvent?.data?[IdentityConstants.EventDataKeys.URL_VARIABLES])
        let urlVariables = dispatchedEvent?.data?[IdentityConstants.EventDataKeys.URL_VARIABLES] as? String ?? ""
        XCTAssertTrue(urlVariables.contains("test-aid"));
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

    /// Tests that getUrlVariables does dispatch an event when the user is opted out
    func testGetUrlVariablesOptedOut() {
        // setup
        let event = Event(name: "Get URL variables", type: EventType.identity, source: EventSource.requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])

        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertFalse(mockRuntime.dispatchedEvents.isEmpty)
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

    /// Tests that processIdentifiers does dispatch an event when the user is opted out
    func testProcessIdentifiersOptedOut() {
        // setup
        let event = Event(name: "Get Identifiers", type: EventType.identity, source: EventSource.requestIdentity, data: nil)

        let configSharedState = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (configSharedState, .set))

        // test
        mockRuntime.simulateComingEvent(event: event)

        // verify
        XCTAssertFalse(mockRuntime.dispatchedEvents.isEmpty)
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

    // MARK: handleRequestReset(...) tests

    /// Tests that when Identity gets a reset request that it resets the persisted identifiers and does not dispatch a complete event
    func testHandleRequestReset() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org",
                                 IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "test-server",
                                 IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue] as [String: Any]
        identity.state?.lastValidConfig = configSharedState

        let previousEcid = ECID()
        identity.state?.identityProperties.ecid = previousEcid
        identity.state?.identityProperties.lastSync = Date()

        let resetEvent = Event(name: "test reset event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)

        // test
        mockRuntime.simulateComingEvent(event: resetEvent)

        // verify
        XCTAssertNotEqual(previousEcid.ecidString, identity.state?.identityProperties.ecid?.ecidString)
        let sharedState = mockRuntime.createdSharedStates.first!
        XCTAssertEqual(identity.state?.identityProperties.ecid?.ecidString, sharedState?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID] as? String)
        XCTAssertNotNil(sharedState?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID])
        XCTAssertNotNil(sharedState?[IdentityConstants.EventDataKeys.VISITOR_IDS_LAST_SYNC])
    }

    // Tests that getExperienceCloudId returns ECID as soon as possible

    /// forseSyncIdentifier needs valid configuration to be present to process
    func testGetECIDBeforeForceSyncWaitsForConfigurationSharedStateToResolve() {
        // setup
        let event = Event(name: "Test Get ECID Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (nil, .pending))

        // verify
        XCTAssertFalse(identity.readyForEvent(event))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (nil, .set))
        // forceSync will fail since we don't have valid configuration
        XCTAssertFalse(identity.readyForEvent(event))

        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"], .set))
        XCTAssertTrue(identity.readyForEvent(event))

        mockRuntime.simulateComingEvent(event: event)

        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        XCTAssertNotNil(dispatchedEvent?.data?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID])
        let ecid = dispatchedEvent?.data?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID] as? String ?? ""
        XCTAssertFalse(ecid.isEmpty)
    }

    /// forseSyncIdentifier needs valid configuration to be present to process
    func testGetECIDResolvesToLastSetConfig() {
        // setup
        let event = Event(name: "Test Get ECID Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        // mock valid config last set
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"], .set))

        // mock latest config pending
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (nil, .pending))

        // verify event is not blocked by pending config shared state
        XCTAssertTrue(identity.readyForEvent(event))

        mockRuntime.simulateComingEvent(event: event)

        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        XCTAssertNotNil(dispatchedEvent?.data?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID])
        let ecid = dispatchedEvent?.data?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID] as? String ?? ""
        XCTAssertFalse(ecid.isEmpty)
    }

    func testGetECIDAfterForceSyncDoesNotWaitForConfigurationSharedState() {
        // setup
        let syncEvent = Event(name: "Sync Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let getECIDEvent = Event(name: "Test Get ECID Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)

        // configuration shared state will allow forceSync to process
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: syncEvent, data: ([IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org-id"], .set))

        // trigger forceSync
        XCTAssertTrue(identity.readyForEvent(syncEvent))
        mockRuntime.simulateComingEvent(event: syncEvent)

        // set configuration shared state to pending
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: syncEvent, data: (nil, .pending))

        // test
        XCTAssertTrue(identity.readyForEvent(getECIDEvent))
        mockRuntime.simulateComingEvent(event: getECIDEvent)

        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.identity, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.responseIdentity, dispatchedEvent?.source)
        XCTAssertNotNil(dispatchedEvent?.data?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID])
        let ecid = dispatchedEvent?.data?[IdentityConstants.EventDataKeys.VISITOR_ID_ECID] as? String ?? ""
        XCTAssertFalse(ecid.isEmpty)
    }
    
    // MARK: dispatch AnalyticsForIdentityRequest Event tests
    
    // Test setting valid push token on launch dispatches event to Analytics with a.push.optin = True
    func testSetPushIdentifierValidTokenDispatchesAnalyticsForIdentityRequestEvent() {
        // Set valid config to allow sync to process
        identity.state?.lastValidConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
        
        let pushIdData = "test-push-id".data(using: .utf8)!
        let encodedPushId = "746573742D707573682D6964"
                
        let data = ["pushidentifier": encodedPushId]
        let event = Event(name: "Set Push Identifier", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)
        
        mockRuntime.simulateComingEvent(event: event)
        
        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.analytics, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
        XCTAssertEqual("Push", dispatchedEvent?.data?["action"] as? String)
        XCTAssertTrue((dispatchedEvent?.data?["trackinternal"] as? Bool) ?? false)
        let contextData = dispatchedEvent?.data?["contextdata"] as? [String: Any]
        XCTAssertEqual("True", contextData?["a.push.optin"] as? String)
    }
    
    // Test setting push token to nil on launch dispatches event to Analytics with a.push.optin = False
    func testSetPushIdentifierNilDispatchesAnalyticsForIdentityRequestEvent() {
        // Set valid config to allow sync to process
        identity.state?.lastValidConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
                
        let data = ["pushidentifier": ""]
        let event = Event(name: "Set Push Identifier", type: EventType.genericIdentity, source: EventSource.requestContent, data: data)
        
        mockRuntime.simulateComingEvent(event: event)
        
        let dispatchedEvent = mockRuntime.dispatchedEvents.first

        XCTAssertEqual(EventType.analytics, dispatchedEvent?.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent?.source)
        XCTAssertEqual("Push", dispatchedEvent?.data?["action"] as? String)
        XCTAssertTrue((dispatchedEvent?.data?["trackinternal"] as? Bool) ?? false)
        let contextData = dispatchedEvent?.data?["contextdata"] as? [String: Any]
        XCTAssertEqual("False", contextData?["a.push.optin"] as? String)
    }
    
    // Test calling resetIdentities will not trigger dispatch of Analytics event
    func testResetIdentifiersDoesNotDispatcheAnalyticsForIdentityRequestEvent() {
        identity.state?.identityProperties.ecid = ECID()
        XCTAssertNotNil(identity.state?.identityProperties.ecid)
        
        let event = Event(name: "Reset Identities",
                          type: EventType.genericIdentity,
                          source: EventSource.requestReset,
                          data: nil)
        
        mockRuntime.simulateComingEvent(event: event)
        
        XCTAssertTrue(mockRuntime.dispatchedEvents.isEmpty)
        XCTAssertNil(identity.state?.identityProperties.ecid)
    }
    
    // Test changing privacy to opt-out will not trigger dispatch of Analytics event
    func testPrivacyOptOutDoesNotDispatcheAnalyticsForIdentityRequestEvent() {
        identity.state?.identityProperties.ecid = ECID()
        XCTAssertNotNil(identity.state?.identityProperties.ecid)
        
        let event = Event(name: "Configuration Update Response", type: EventType.configuration, source: EventSource.responseContent,
                          data: ["global.privacy": PrivacyStatus.optedOut.rawValue])
        
        mockRuntime.simulateComingEvent(event: event)
        
        XCTAssertTrue(mockRuntime.dispatchedEvents.isEmpty)
        XCTAssertNil(identity.state?.identityProperties.ecid)
    }
}
