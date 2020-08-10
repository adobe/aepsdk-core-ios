/// *
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
// */
//
// import XCTest
// @testable import AEPCore
// import AEPServices
//
// TODO: rewrite
// TODO: Move getSdkIdentities functional tests to Identity functional tests
///// Functional tests for the Configuration extension
// class ConfigurationFunctionalTests: XCTestCase {
//
//    override func setUp() {
//        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .error)
//        ServiceProvider.shared.systemInfoService = MockSystemInfoService()
//        ServiceProvider.shared.namedKeyValueService = MockDataStore()
//        MockExtension.reset()
//        EventHub.reset()
//        registerExtension(MockExtension.self)
//
//        EventHub.shared.start()
//        // Wait for first shared state from configuration to signal bootup has completed
//        registerConfigAndWaitForSharedState()
//    }
//
//    // helpers
//    private func registerExtension<T: Extension> (_ type: T.Type) {
//        let expectation = XCTestExpectation(description: "Extension should register")
//        EventHub.shared.registerExtension(type) { (error) in
//            XCTAssertNil(error)
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: 0.5)
//    }
//
//    private func registerConfigAndWaitForSharedState() {
//        let expectation = XCTestExpectation(description: "Configuration should share first shared state")
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { _ in expectation.fulfill() }
//        registerExtension(Configuration.self)
//
//        wait(for: [expectation], timeout: 0.5)
//    }
//
//    // MARK: updateConfigurationWith(dict) tests
//
//    /// Tests the happy path with for updating the config with a dict
//    func testUpdateConfigurationWithDict() {
//        // setup
//        let configUpdate = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
//
//        let configResponseExpectation = XCTestExpectation(description: "Update config dispatches a configuration response content event")
//        let sharedStateExpectation = XCTestExpectation(description: "Update config dispatches configuration shared state")
//
//        let extensionContainer = EventHub.shared.getExtensionContainer(MockExtension.self)
//        extensionContainer?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            XCTAssertNotNil(event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: Any])
//            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY]!, PrivacyStatus.optedOut.rawValue)
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.updateConfigurationWith(configDict: configUpdate)
//
//        // verify
//        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 2)
//    }
//
//
//    /// Tests the happy path with for updating the config with a dict
//    func testUpdateConfigurationWithDict_New() {
//        // setup
//        let runtime = TestableExtensionRuntime()
//        let configuration = Configuration.init(runtime: runtime)
//        configuration.onRegistered()
//        XCTAssertEqual(1, runtime.createdSharedStates.count)
//
//        // test
//        let configUpdate = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
//        let configUpdateEvent = Event(name: "Configuration Update", type: .configuration, source: .requestContent,
//                                 data: [ConfigurationConstants.Keys.UPDATE_CONFIG: configUpdate])
//        runtime.simulateComingEvent(event: configUpdateEvent)
//
//        // verify
//        XCTAssertEqual(1, runtime.dispatchedEvents.count)
//        XCTAssertEqual(2, runtime.createdSharedStates.count)
//
//        // verify response event
//        let dispatchedEvent = runtime.dispatchedEvents[0]
//         XCTAssertEqual(dispatchedEvent.type, EventType.configuration)
//        XCTAssertEqual(dispatchedEvent.source, EventSource.responseContent)
//        XCTAssertNotNil(dispatchedEvent.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: Any])
//
//        // verify share state update
//        let newSharedState = runtime.createdSharedStates[1]
//        XCTAssertEqual("optedout", newSharedState?["global.privacy"] as! String)
//
//    }
//
//
//    /// Tests the happy path with updating the config multiple times with a dict
//    func testUpdateConfigurationWithDictTwice() {
//        // setup
//        let configUpdate = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
//
//        let configResponseExpectation = XCTestExpectation(description: "Update config dispatches 2 configuration response content events")
//        configResponseExpectation.expectedFulfillmentCount = 2
//        let sharedStateExpectation = XCTestExpectation(description: "Update config dispatches 2 configuration shared states")
//        sharedStateExpectation.expectedFulfillmentCount = 2
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            XCTAssertNotNil(event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: Any])
//            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY], PrivacyStatus.optedIn.rawValue)
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.updateConfigurationWith(configDict: configUpdate)
//        MobileCore.updateConfigurationWith(configDict: configUpdate)
//
//        // verify
//        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 2)
//    }
//
//    /// Tests the case where the update dict is empty, and should not dispatch a configuration response content event
//    func testUpdateConfigurationWithEmptyDict() {
//        // setup
//        let configResponseExpectation = XCTestExpectation(description: "Update config does not dispatch a configuration response content event when update config is passed an empty dict")
//        configResponseExpectation.isInverted = true
//        let sharedStateExpectation = XCTestExpectation(description: "Update config with an empty config dispatches a configuration shared state")
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.updateConfigurationWith(configDict: [:])
//
//        // verify
//        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.25)
//    }
//
//    // MARK: setPrivacy(...) tests
//
//    /// Tests the happy path for updating the privacy status
//    func testSetPrivacyStatusSimple() {
//        // setup
//        let configResponseExpectation = XCTestExpectation(description: "Set privacy status dispatches a configuration response content event with updated config")
//        let sharedStateExpectation = XCTestExpectation(description: "Set privacy status dispatches configuration shared state")
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            guard let configUpdate = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as! [String: Any]? else {
//                XCTFail("Could not get update config dict")
//                return
//            }
//            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! String, PrivacyStatus.optedIn.rawValue)
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.setPrivacy(status: .optedIn)
//
//        // verify
//        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 2)
//    }
//
//    /// Tests that we can set the privacy status for the first time then update it a second time
//    func testSetPrivacyStatusTwice() {
//        // setup
//        let configResponseExpectation = XCTestExpectation(description: "Set privacy dispatches 2 configuration response content events")
//        configResponseExpectation.expectedFulfillmentCount = 2
//        let sharedStateResponseExpectation = XCTestExpectation(description: "Set privacy dispatches 2 shared states")
//        sharedStateResponseExpectation.expectedFulfillmentCount = 2
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            guard let configUpdate = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as! [String: Any]? else {
//                XCTFail("Could not get update config dict")
//                return
//            }
//            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! String, PrivacyStatus.optedIn.rawValue)
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateResponseExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.setPrivacy(status: .optedIn)
//        MobileCore.setPrivacy(status: .optedIn)
//
//        // verify
//        wait(for: [configResponseExpectation, sharedStateResponseExpectation], timeout: 1.0)
//    }
//
//    // MARK: getPrivacyStatus(...) tests
//
//    /// Ensures that when not privacy is set that we default to unknown
//    func testGetPrivacyStatusDefaultsToUnknown() {
//        // setup
//        let privacyExpectation = XCTestExpectation(description: "Get privacy status defaults to unknown")
//
//        // test
//        MobileCore.getPrivacyStatus { (privacyStatus) in
//            XCTAssertEqual(privacyStatus, PrivacyStatus.unknown)
//            privacyExpectation.fulfill()
//        }
//
//        // verify
//        wait(for: [privacyExpectation], timeout: 2)
//    }
//
//    /// Happy path for setting privacy to opt-in
//    func testGetPrivacyStatusSimpleOptIn() {
//        // setup
//        let privacyExpectation = XCTestExpectation(description: "Get privacy status returns opt-in")
//
//        // test
//        MobileCore.setPrivacy(status: .optedIn)
//        MobileCore.getPrivacyStatus { (privacyStatus) in
//            XCTAssertEqual(privacyStatus.rawValue, PrivacyStatus.optedIn.rawValue)
//            privacyExpectation.fulfill()
//        }
//
//        // verify
//        wait(for: [privacyExpectation], timeout: 2)
//    }
//
//    func testGetPrivacyStatusSimpleOptOut() {
//        // setup
//        let privacyExpectation = XCTestExpectation(description: "Get privacy status returns opt-out")
//
//        // test
//        MobileCore.setPrivacy(status: .optedOut)
//        MobileCore.getPrivacyStatus { (privacyStatus) in
//            XCTAssertEqual(privacyStatus, PrivacyStatus.optedOut)
//            privacyExpectation.fulfill()
//        }
//
//        // verify
//        wait(for: [privacyExpectation], timeout: 2)
//    }
//
//    /// Happy path for setting privacy to opt-in then opt-out
//    func testGetPrivacyStatusSimpleOptInThenOptOut() {
//        // setup
//        let optInExpectation = XCTestExpectation(description: "Get privacy status returns opt-in")
//        let optOutExpectation = XCTestExpectation(description: "Get privacy status returns opt-out")
//
//        // test
//        MobileCore.setPrivacy(status: .optedIn)
//        MobileCore.getPrivacyStatus { (privacyStatus) in
//            XCTAssertEqual(privacyStatus, PrivacyStatus.optedIn)
//            optInExpectation.fulfill()
//
//            MobileCore.setPrivacy(status: .optedOut)
//            MobileCore.getPrivacyStatus { (updatedPrivacyStatus) in
//                XCTAssertEqual(updatedPrivacyStatus, PrivacyStatus.optedOut)
//                optOutExpectation.fulfill()
//            }
//        }
//
//        // verify
//        wait(for: [optInExpectation, optOutExpectation], timeout: 2)
//    }
//
//    // MARK: Lifecycle response event tests
//
//    /// Tests that no configuration event is dispatched when a lifecycle response content event and no appId is stored in persistence
//    func testHandleLifecycleResponseEmptyAppId() {
//        // setup
//        let configRequestExpectation = XCTestExpectation(description: "Configuration should not dispatch an app id event if app id is empty")
//        configRequestExpectation.isInverted = true
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .requestContent) { (event) in
//            configRequestExpectation.fulfill()
//        }
//
//        let lifecycleEvent = Event(name: "Lifecycle response content", type: .lifecycle, source: .responseContent, data: nil)
//        EventHub.shared.dispatch(event: lifecycleEvent)
//
//        // verify
//        wait(for: [configRequestExpectation], timeout: 0.25)
//    }
//
//    // MARK: configureWith(filePath) tests
//
//    /// Tests the happy path when passing in a valid path to a bundled config
//    func testLoadBundledConfig() {
//        // setup
//        let expectedDictCount = 16
//        let configResponseExpectation = XCTestExpectation(description: "Configuration should dispatch response content event with new config")
//        let sharedStateExpectation = XCTestExpectation(description: "Configuration should update shared state")
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            XCTAssertEqual(event.data?.count, expectedDictCount)
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
//        MobileCore.configureWith(filePath: path)
//
//        // verify
//        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 2)
//    }
//
//    /// Tests the API call where the path to the config is invalid
//    func testLoadInvalidPathBundledConfig() {
//        // setup
//        let configResponseExpectation = XCTestExpectation(description: "Configuration should NOT dispatch response content event with new config when path to config is invalid")
//        let sharedStateExpectation = XCTestExpectation(description: "Configuration still should update shared state")
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.configureWith(filePath: "Invalid/Path/ADBMobileConfig.json")
//
//        // verify
//        wait(for: [sharedStateExpectation], timeout: 2)
//    }
//
//    /// Test that programmatic config is applied over the (failed) loaded json
//    func testLoadInvalidBundledConfigWithProgrammaticApplied() {
//        // setup
//        let configResponseExpectation = XCTestExpectation(description: "Configuration should dispatch response content event with new config")
//        let sharedStateExpectation = XCTestExpectation(description: "Configuration should update shared state")
//        let getPrivacyStatusExpectation = XCTestExpectation(description: "Get privacy status callback is invoked")
//        sharedStateExpectation.expectedFulfillmentCount = 2
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            configResponseExpectation.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.setPrivacy(status: .optedOut)
//        MobileCore.configureWith(filePath: "Invalid/Path/ADBMobileConfig.json")
//
//        // verify
//        MobileCore.getPrivacyStatus { (status) in
//            XCTAssertEqual(PrivacyStatus.optedOut, status)
//            getPrivacyStatusExpectation.fulfill()
//        }
//
//        wait(for: [configResponseExpectation, sharedStateExpectation, getPrivacyStatusExpectation], timeout: 2)
//    }
//
//    // MARK: configureWith(appId) tests
//
//    /// When network service returns a valid response configure with appId succeeds
//    func testConfigureWithAppId() {
//        // setup
//        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .success)
//        ServiceProvider.shared.networkService = mockNetworkService
//
//        let configResponseEvent = XCTestExpectation(description: "Downloading config should dispatch response content event with new config")
//        let sharedStateExpectation = XCTestExpectation(description: "Downloading config should update shared state")
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            XCTAssertEqual(event.data?.count, mockNetworkService.validResponseDictSize)
//            configResponseEvent.fulfill()
//        }
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
//            XCTAssertEqual(event.type, EventType.hub)
//            XCTAssertEqual(event.source, EventSource.sharedState)
//            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String)
//            sharedStateExpectation.fulfill()
//        }
//
//        // test
//        MobileCore.configureWith(appId: "valid-app-id")
//
//        // verify
//        wait(for: [configResponseEvent, sharedStateExpectation], timeout: 2.0)
//    }
//
//    /// Tests that we can re-try network requests, and it will succeed when the network comes back online
//    func testConfigureWithAppIdNetworkDownThenComesOnline() {
//        // setup
//        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .error)
//        ServiceProvider.shared.networkService = mockNetworkService
//
//        let configResponseEvent = XCTestExpectation(description: "Downloading config should dispatch response content event with new config")
//        configResponseEvent.expectedFulfillmentCount = 2
//
//        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: .configuration, source: .responseContent) { (event) in
//            XCTAssertEqual(event.type, EventType.configuration)
//            XCTAssertEqual(event.source, EventSource.responseContent)
//            XCTAssertEqual(event.data?.count, mockNetworkService.validResponseDictSize)
//            configResponseEvent.fulfill()
//        }
//
//        // test
//        MobileCore.configureWith(appId: "invalid-app-id")
//        sleep(5) // give some time for the first network request to fail
//        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .success) // setup a valid network response
//        MobileCore.configureWith(appId: "valid-app-id")
//
//        // verify
//        wait(for: [configResponseEvent], timeout: 2.0)
//    }
//
//    // MARK: getSdkIdentities() tests
//
//    /// Tests that when all shared states are available that all identities are populated
//    func testGetSdkIdentitiesSimple() {
//        // setup
//        let expectation = XCTestExpectation(description: "Get SDK Identities callback is invoked")
//        expectation.assertForOverFulfill = true
//        registerExtension(Identity.self)
//        EventHub.shared.createSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, data: [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org-id"], event: nil)
//        let identityData = [IdentityConstants.EventDataKeys.VISITOR_ID_MID: "test-mid", IdentityConstants.EventDataKeys.PUSH_IDENTIFIER: "test-push-id"]
//        EventHub.shared.createSharedState(extensionName: IdentityConstants.EXTENSION_NAME, data: identityData, event: nil)
//
//        let expected = "{\"users\":[{\"userIDs\":[{\"namespace\":\"4\",\"value\":\"test-mid\",\"type\":\"namespaceId\"},{\"namespace\":\"20920\",\"value\":\"test-push-id\",\"type\":\"integrationCode\"}]}],\"companyContexts\":[{\"namespace\":\"imsOrgID\",\"marketingCloudId\":\"test-org-id\"}]}"
//
//        // test
//        MobileCore.getSdkIdentities { (identities, error) in
//            XCTAssertEqual(expected, identities)
//            XCTAssertNil(error)
//            expectation.fulfill()
//        }
//
//        // verify
//        wait(for: [expectation], timeout: 1.0)
//    }
//
//    /// Tests that when only configuration has a shared state that it is only included in the returned identities
//    func testGetSdkIdentitiesOnlyConfiguration() {
//        // setup
//        let expectation = XCTestExpectation(description: "Get SDK Identities callback is invoked")
//        expectation.assertForOverFulfill = true
//        registerExtension(Identity.self)
//        EventHub.shared.createSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, data: [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org-id"], event: nil)
//
//        let expected = "{\"companyContexts\":[{\"namespace\":\"imsOrgID\",\"marketingCloudId\":\"test-org-id\"}]}"
//
//        // test
//        MobileCore.getSdkIdentities { (identities, error) in
//            XCTAssertEqual(expected, identities)
//            XCTAssertNil(error)
//            expectation.fulfill()
//        }
//
//        // verify
//        wait(for: [expectation], timeout: 1.0)
//    }
//
//    /// Tests that when only identity has a shared state that it is only included in the returned identities
//    func testGetSdkIdentitiesOnlyIdentity() {
//        // setup
//        let expectation = XCTestExpectation(description: "Get SDK Identities callback is invoked")
//        expectation.assertForOverFulfill = true
//        registerExtension(Identity.self)
//        let identityData = [IdentityConstants.EventDataKeys.VISITOR_ID_MID: "test-mid", IdentityConstants.EventDataKeys.PUSH_IDENTIFIER: "test-push-id"]
//        EventHub.shared.createSharedState(extensionName: IdentityConstants.EXTENSION_NAME, data: identityData, event: nil)
//
//        let expected = "{\"users\":[{\"userIDs\":[{\"namespace\":\"4\",\"value\":\"test-mid\",\"type\":\"namespaceId\"},{\"namespace\":\"20920\",\"value\":\"test-push-id\",\"type\":\"integrationCode\"}]}]}"
//
//        // test
//        MobileCore.getSdkIdentities { (identities, error) in
//            XCTAssertEqual(expected, identities)
//            XCTAssertNil(error)
//            expectation.fulfill()
//        }
//
//        // verify
//        wait(for: [expectation], timeout: 1.0)
//    }
//
//    /// Tests that when no identities are available that an empty json object is returned
//    func testGetSdkIdentitiesEmpty() {
//        // setup
//        let expectation = XCTestExpectation(description: "Get SDK Identities callback is invoked")
//        expectation.assertForOverFulfill = true
//        let expected = "{}"
//
//        // test
//        MobileCore.getSdkIdentities { (identities, error) in
//            XCTAssertEqual(expected, identities)
//            XCTAssertNil(error)
//            expectation.fulfill()
//        }
//
//        // verify
//        wait(for: [expectation], timeout: 1.0)
//    }
//
//    func testGetSdkIdentitiesPendingThenSet() {
//        // setup
//        let expectation = XCTestExpectation(description: "Get SDK Identities callback is invoked")
//        expectation.assertForOverFulfill = true
//        registerExtension(Identity.self)
//        let resolver = EventHub.shared.createPendingSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: nil)
//
//        let expected = "{\"companyContexts\":[{\"namespace\":\"imsOrgID\",\"marketingCloudId\":\"test-org-id\"}]}"
//
//        // test
//        MobileCore.getSdkIdentities { (identities, error) in
//            XCTAssertEqual(expected, identities)
//            XCTAssertNil(error)
//            expectation.fulfill()
//        }
//
//        resolver([ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org-id"])
//
//        // verify
//        wait(for: [expectation], timeout: 5.0)
//    }
// }
