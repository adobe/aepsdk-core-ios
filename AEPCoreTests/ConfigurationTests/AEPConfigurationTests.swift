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

class AEPConfigurationTests: XCTestCase {
    var eventHub = EventHub.shared
    var dataStore = NamedKeyValueStore(name: ConfigurationConstants.DATA_STORE_NAME)
    
    override func setUp() {
        EventHub.reset()
        eventHub = EventHub.shared
        dataStore.removeAll()
        registerExtension(MockExtension.self)
        
        // Wait for bootup shared state from configuration
        let semaphore = DispatchSemaphore(value: 0)
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { _ in semaphore.signal() }
        registerExtension(AEPConfiguration.self)
        eventHub.start()
        semaphore.wait()
    }
    
    // helpers
    // TODO: Move into shared event hub test helpers
    private func registerExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        eventHub.registerExtension(type) { (error) in
            XCTAssertNil(error)
            semaphore.signal()
        }

        semaphore.wait()
    }
    
    // MARK: updateConfigurationWith(dict)
    func testUpdateConfigurationWithDict() {
        // setup
        let configUpdate = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]

        let configResponseExpectation = XCTestExpectation(description: "Update config dispatches a configuration response content event")
        configResponseExpectation.assertForOverFulfill = true
        let sharedStateExpectation = XCTestExpectation(description: "Update config dispatches configuration shared state")
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            XCTAssertEqual(event.type, EventType.configuration)
            XCTAssertEqual(event.source, EventSource.responseContent)
            guard let configUpdate = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: Any] else {
                XCTFail("Could not get update config dict")
                return
            }
            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! String, PrivacyStatus.optedOut.rawValue)
            configResponseExpectation.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.updateConfigurationWith(configDict: configUpdate)
        
        // verify
        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.5)
    }
    
    func testUpdateConfigurationWithDictTwice() {
        // setup
        let configUpdate = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]

        let configResponseExpectation = XCTestExpectation(description: "Update config dispatches 2 configuration response content events")
        configResponseExpectation.expectedFulfillmentCount = 2
        configResponseExpectation.assertForOverFulfill = true
        let sharedStateExpectation = XCTestExpectation(description: "Update config dispatches 2 configuration shared states")
        sharedStateExpectation.expectedFulfillmentCount = 2
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            XCTAssertEqual(event.type, EventType.configuration)
            XCTAssertEqual(event.source, EventSource.responseContent)
            guard let configUpdate = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as! [String: Any]? else {
                XCTFail("Could not get update config dict")
                return
            }
            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! String, PrivacyStatus.optedIn.rawValue)
            configResponseExpectation.fulfill()
        }

        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.updateConfigurationWith(configDict: configUpdate)
        AEPCore.updateConfigurationWith(configDict: configUpdate)
        
        // verify
        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.5)
    }
    
    func testUpdateConfigurationWithEmptyDict() {
        // setup
        let configResponseExpectation = XCTestExpectation(description: "Update config does not dispatch a configuration response content event when update config is passed an empty dict")
        configResponseExpectation.isInverted = true
        let sharedStateExpectation = XCTestExpectation(description: "Update config with an empty config dispatches a configuration shared state")
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            configResponseExpectation.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.updateConfigurationWith(configDict: [:])
        
        // verify
        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.5)
    }
    
    func testSetPrivacyStatusSimple() {
        // setup
        let configResponseExpectation = XCTestExpectation(description: "Set privacy status dispatches a configuration response content event with updated config")
        configResponseExpectation.assertForOverFulfill = true
        let sharedStateExpectation = XCTestExpectation(description: "Set privacy status dispatches configuration shared state")
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            XCTAssertEqual(event.type, EventType.configuration)
            XCTAssertEqual(event.source, EventSource.responseContent)
            guard let configUpdate = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as! [String: Any]? else {
                XCTFail("Could not get update config dict")
                return
            }
            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! String, PrivacyStatus.optedIn.rawValue)
            configResponseExpectation.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.setPrivacy(status: .optedIn)
        
        // verify
        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.5)
    }
    
    func testSetPrivacyStatusTwice() {
        // setup
        let configResponseExpectation = XCTestExpectation(description: "Set privacy dispatches 2 configuration response content events")
        configResponseExpectation.expectedFulfillmentCount = 2
        configResponseExpectation.assertForOverFulfill = true
        let sharedStateResponseExpectation = XCTestExpectation(description: "Set privacy dispatches 2 shared states")
        sharedStateResponseExpectation.expectedFulfillmentCount = 2
        sharedStateResponseExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            XCTAssertEqual(event.type, EventType.configuration)
            XCTAssertEqual(event.source, EventSource.responseContent)
            guard let configUpdate = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as! [String: Any]? else {
                XCTFail("Could not get update config dict")
                return
            }
            XCTAssertEqual(configUpdate[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! String, PrivacyStatus.optedIn.rawValue)
            configResponseExpectation.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateResponseExpectation.fulfill()
        }
        
        // test
        AEPCore.setPrivacy(status: .optedIn)
        AEPCore.setPrivacy(status: .optedIn)
        
        // verify
        wait(for: [configResponseExpectation, sharedStateResponseExpectation], timeout: 1.0)
    }
    
    func testGetPrivacyStatusDefaultsToUnknown() {
        // setup
        let privacyExpectation = XCTestExpectation(description: "Get privacy status defaults to unknown")
        privacyExpectation.assertForOverFulfill = true
        
        // test
        AEPCore.getPrivacyStatus { (privacyStatus) in
            XCTAssertEqual(privacyStatus, PrivacyStatus.unknown)
            privacyExpectation.fulfill()
        }
        
        // verify
        wait(for: [privacyExpectation], timeout: 0.5)
    }
    
    func testGetPrivacyStatusSimpleOptIn() {
        // setup
        let privacyExpectation = XCTestExpectation(description: "Get privacy status returns opt-in")
        privacyExpectation.assertForOverFulfill = true
        
        // test
        AEPCore.setPrivacy(status: .optedIn)
        AEPCore.getPrivacyStatus { (privacyStatus) in
            XCTAssertEqual(privacyStatus.rawValue, PrivacyStatus.optedIn.rawValue)
            privacyExpectation.fulfill()
        }
        
        // verify
        wait(for: [privacyExpectation], timeout: 0.5)
    }
    
    func testGetPrivacyStatusSimpleOptOut() {
        // setup
        let privacyExpectation = XCTestExpectation(description: "Get privacy status returns opt-out")
        privacyExpectation.assertForOverFulfill = true
        
        // test
        AEPCore.setPrivacy(status: .optedOut)
        AEPCore.getPrivacyStatus { (privacyStatus) in
            XCTAssertEqual(privacyStatus, PrivacyStatus.optedOut)
            privacyExpectation.fulfill()
        }
        
        // verify
        wait(for: [privacyExpectation], timeout: 0.5)
    }
    
    func testGetPrivacyStatusSimpleOptInThenOptOut() {
        // setup
        let optInExpectation = XCTestExpectation(description: "Get privacy status returns opt-in")
        optInExpectation.assertForOverFulfill = true
        
        let optOutExpectation = XCTestExpectation(description: "Get privacy status returns opt-out")
        optOutExpectation.assertForOverFulfill = true
        
        // test
        AEPCore.setPrivacy(status: .optedIn)
        AEPCore.getPrivacyStatus { (privacyStatus) in
            XCTAssertEqual(privacyStatus, PrivacyStatus.optedIn)
            optInExpectation.fulfill()
            
            AEPCore.setPrivacy(status: .optedOut)
            AEPCore.getPrivacyStatus { (updatedPrivacyStatus) in
                XCTAssertEqual(updatedPrivacyStatus, PrivacyStatus.optedOut)
                optOutExpectation.fulfill()
            }
        }
        
        // verify
        wait(for: [optInExpectation, optOutExpectation], timeout: 0.5)
    }
    
    func testProgrammaticConfigPersisted() {
        // setup
        let configUpdate = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]

        let sharedStateExpectation = XCTestExpectation(description: "Update config saves to user defaults and dispatches two shared states (1 bootup, 1 from API call)")
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.updateConfigurationWith(configDict: configUpdate)
        
        // verify
        wait(for: [sharedStateExpectation], timeout: 5.0)
        let persistedConfig = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG, fallback: [String: AnyCodable]()) // ensure programmatic config is saved to data store
        XCTAssertEqual(persistedConfig?[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY]?.stringValue, PrivacyStatus.optedOut.rawValue)
    }
    
    func testProgrammaticConfigPersistedComplex() {
        // setup
        let configUpdate: [String: Any] = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
                                            "target.clientCode": "yourclientcode",
                                            "target.timeout": 5,
                                            "audience.server": "omniture.demdex.net",
                                            "audience.timeout": 5,
                                            "analytics.rsids": "mobilersidsample",
                                            "analytics.server": "obumobile1.sc.omtrdc.net",
                                            "analytics.aamForwardingEnabled": false,
                                            "analytics.offlineEnabled": true,
                                            "analytics.batchLimit": 0,
                                            "analytics.backdatePreviousSessionInfo": false,
                                            "global.privacy": "optedin",
                                            "lifecycle.sessionTimeout": 300,
                                            "rules.url": "https://link.to.rules/test.zip"]

        let sharedStateExpectation = XCTestExpectation(description: "Update config saves to user defaults with complex update config and shares state")
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.updateConfigurationWith(configDict: configUpdate)
        
        // verify
        wait(for: [sharedStateExpectation], timeout: 0.5)
        let persistedConfig = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG, fallback: [String: AnyCodable]()) // ensure programmatic config is saved to data store
        XCTAssertEqual(14, persistedConfig?.count)
    }
    
    func testHandleLifecycleResponseEmptyAppId() {
        // setup
        let configRequestExpectation = XCTestExpectation(description: "Configuration should not dispatch an app id event if app id is empty")
        configRequestExpectation.isInverted = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .requestContent) { (event) in
            configRequestExpectation.fulfill()
        }
        
        let lifecycleEvent = Event(name: "Lifecycle response content", type: .lifecycle, source: .responseContent, data: nil)
        eventHub.dispatch(event: lifecycleEvent)
        
        // verify
        wait(for: [configRequestExpectation], timeout: 0.5)
    }
    
    func testHandleLifecycleResponseNonEmptyAppId() {
        // setup
        let configRequestExpectation = XCTestExpectation(description: "Configuration should dispatch an app id event if app id is stored in local store")
        configRequestExpectation.assertForOverFulfill = true
        let testAppId = "test-app-id"
        dataStore.set(key: ConfigurationConstants.Keys.PERSISTED_APPID, value: testAppId) // set appId in persistence
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .requestContent) { (event) in
            XCTAssertEqual(true, event.data?[ConfigurationConstants.Keys.IS_INTERNAL_EVENT] as! Bool)
            XCTAssertEqual(testAppId, event.data?[ConfigurationConstants.Keys.JSON_APP_ID] as! String)
            configRequestExpectation.fulfill()
        }
        
        let lifecycleEvent = Event(name: "Lifecycle response content", type: .lifecycle, source: .responseContent, data: nil)
        eventHub.dispatch(event: lifecycleEvent)
        
        // verify
        wait(for: [configRequestExpectation], timeout: 0.5)
    }
    
    // TODO: Add test when app id is loaded from manifest

    func testLoadBundledConfig() {
        // setup
        let expectedDictCount = 16
        let configResponseExpectation = XCTestExpectation(description: "Configuration should dispatch response content event with new config")
        configResponseExpectation.assertForOverFulfill = true
        let sharedStateExpectation = XCTestExpectation(description: "Configuration should update shared state")
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            XCTAssertEqual(event.type, EventType.configuration)
            XCTAssertEqual(event.source, EventSource.responseContent)
            XCTAssertEqual(event.data?.count, expectedDictCount)
            configResponseExpectation.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
        AEPCore.configureWith(filePath: path)
        
        // verify
        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.5)
        
        let configSharedState = eventHub.getSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: nil)?.value
        XCTAssertEqual(expectedDictCount, configSharedState?.count)
        let sharedPrivacyStatus = configSharedState?[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! AnyCodable
        XCTAssertEqual(PrivacyStatus.optedIn.rawValue, sharedPrivacyStatus.stringValue)
    }
    
    func testLoadInvalidPathBundledConfig() {
        // setup
        let configResponseExpectation = XCTestExpectation(description: "Configuration should NOT dispatch response content event with new config when path to config is invalid")
        configResponseExpectation.isInverted = true
        let sharedStateExpectation = XCTestExpectation(description: "Configuration still should update shared state")
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            configResponseExpectation.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.configureWith(filePath: "Invalid/Path/ADBMobileConfig.json")
        
        // verify
        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.5)
    }
    
    /// Test that programmatic config is applied over the (failed) loaded json
    func testLoadInvalidBundledConfigWithProgrammaticApplied() {
        // setup
        let configResponseExpectation = XCTestExpectation(description: "Configuration should dispatch response content event with new config")
        configResponseExpectation.assertForOverFulfill = true
        let sharedStateExpectation = XCTestExpectation(description: "Configuration should update shared state")
        sharedStateExpectation.expectedFulfillmentCount = 2
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            XCTAssertEqual(event.type, EventType.configuration)
            XCTAssertEqual(event.source, EventSource.responseContent)
            configResponseExpectation.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.setPrivacy(status: .optedOut)
        AEPCore.configureWith(filePath: "Invalid/Path/ADBMobileConfig.json")
        
        // verify
        wait(for: [configResponseExpectation, sharedStateExpectation], timeout: 0.5)
        
        let configSharedState = eventHub.getSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: nil)?.value
        let sharedPrivacyStatus = configSharedState?[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! String
        XCTAssertEqual(PrivacyStatus.optedOut.rawValue, sharedPrivacyStatus)
    }
    
    func testConfigureWithAppId() {
        // setup
        let expectedDictCount = 16
        let configResponseEvent = XCTestExpectation(description: "Downloading config should dispatch response content event with new config")
        configResponseEvent.assertForOverFulfill = true
        let sharedStateExpectation = XCTestExpectation(description: "Downloading config should update shared state")
        sharedStateExpectation.assertForOverFulfill = true
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .responseContent) { (event) in
            XCTAssertEqual(event.type, EventType.configuration)
            XCTAssertEqual(event.source, EventSource.responseContent)
            XCTAssertEqual(event.data?.count, expectedDictCount)
            configResponseEvent.fulfill()
        }
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.type, EventType.hub)
            XCTAssertEqual(event.source, EventSource.sharedState)
            XCTAssertEqual(ConfigurationConstants.EXTENSION_NAME, event.data?[EventHubConstants.Keys.Configuration.EVENT_STATE_OWNER] as! String)
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.configureWith(appId: "launch-EN1a68f9bc5b3c475b8c232adc3f8011fb")
        
        // verify
        wait(for: [configResponseEvent, sharedStateExpectation], timeout: 2.0)
        
        let configSharedState = eventHub.getSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, event: nil)?.value
        XCTAssertEqual(expectedDictCount, configSharedState?.count)
        let sharedPrivacyStatus = configSharedState?[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as! AnyCodable
        XCTAssertEqual(PrivacyStatus.optedIn.rawValue, sharedPrivacyStatus.stringValue)
    }
    
    // IS_INTERNAL_EVENT setAppId with different appID than persisted should not make a network call
    func testProcessConfigureWithAppIdInternalEventWithDifferentAppIdInPersistence() {
        // setup
        let sharedStateExpectation = XCTestExpectation(description: "IS_INTERNAL_EVENT with different appID than persisted should not make a network call")
        dataStore.set(key: ConfigurationConstants.Keys.PERSISTED_APPID, value: "persisted-app-id") // set appId in persistence
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            sharedStateExpectation.fulfill()
        }
        
        // test
        let data: [String: Any] = [ConfigurationConstants.Keys.JSON_APP_ID: "old-app-id",
                                   ConfigurationConstants.Keys.IS_INTERNAL_EVENT: true]
        let event = Event(name: "Configuration Request Event", type: .configuration, source: .requestContent, data: data)
        eventHub.dispatch(event: event)
        
        // verify
        wait(for: [sharedStateExpectation], timeout: 0.5)
        XCTAssertEqual(dataStore.getString(key: ConfigurationConstants.Keys.PERSISTED_APPID, fallback: nil), "persisted-app-id")
    }
    
    // IS_INTERNAL_EVENT with same appId as persisted should make a network call
    func testProcessConfigureWithAppIdInternalEventWithSameAppIdInPersistence() {
        // setup
        let sharedStateExpectation = XCTestExpectation(description: "IS_INTERNAL_EVENT with same appId as persisted should make a network call")
        dataStore.set(key: ConfigurationConstants.Keys.PERSISTED_APPID, value: "persisted-app-id") // set appId in persistence
        
        eventHub.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            sharedStateExpectation.fulfill()
        }
        
        // test
        let data: [String: Any] = [ConfigurationConstants.Keys.JSON_APP_ID: "old-app-id",
                                   ConfigurationConstants.Keys.IS_INTERNAL_EVENT: true]
        let event = Event(name: "Configuration Request Event", type: .configuration, source: .requestContent, data: data)
        eventHub.dispatch(event: event)
        
        // verify
        wait(for: [sharedStateExpectation], timeout: 0.5)
        XCTAssertEqual(dataStore.getString(key: ConfigurationConstants.Keys.PERSISTED_APPID, fallback: nil), "persisted-app-id")
    }

}
