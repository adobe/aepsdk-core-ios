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
import AEPCoreMocks
import AEPServices
import AEPServicesMocks
import XCTest

/// Functional tests for the Configuration extension
class ConfigurationUpdateTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var configuration: Configuration!
    let mockDataStore = NamedCollectionDataStore(name: ConfigurationConstants.DATA_STORE_NAME)
    private let mockAppid = "mockAppid"
    private let mockConfig: [String: AnyCodable] = ["global.privacy": "optedin",
                                                    "lifecycle.sessionTimeout": 300,
                                                    "rules.url": "https://link.to.rules/test.zip",
                                                    "analytics.server": "default"]

    func setUpForUpdate() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    func setupWithCachedConfig() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        // Make sure initial config is cached
        mockDataStore.set(key: ConfigurationConstants.DataStoreKeys.PERSISTED_APPID, value: mockAppid)
        let cacheKey = "\(ConfigurationConstants.DataStoreKeys.CONFIG_CACHE_PREFIX)\(mockAppid)"
        mockDataStore.setObject(key: cacheKey, value: CachedConfiguration(cacheable: mockConfig, lastModified: "test-last-modified", eTag: "test-etag"))
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    override func tearDown() {
        UserDefaults.clear()
    }

    // MARK: update shared state tests

    /// Tests the happy path with for updating the config with a dict
    func testUpdateConfigurationWithDict() {
        // setup
        setUpForUpdate()
        let configUpdate = ["global.privacy": PrivacyStatus.optedOut.rawValue]

        // test
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: configUpdate))

        // test
        MobileCore.updateConfigurationWith(configDict: configUpdate)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)

        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(dispatchedEvent.type, EventType.configuration)
        XCTAssertEqual(dispatchedEvent.source, EventSource.responseContent)
        XCTAssertEqual("optedout", dispatchedEvent.data?["global.privacy"] as? String)

        let sharedState = mockRuntime.createdSharedStates[0]
        XCTAssertEqual("optedout", sharedState?["global.privacy"] as? String)
    }

    /// Tests the happy path with updating the config multiple times with a same dict
    func testUpdateConfigurationWithDictTwice() {
        // setup
        setUpForUpdate()
        let configUpdate = ["global.privacy": "optedin"]

        // test
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: configUpdate))
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: configUpdate))

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
    }

    /// Tests the happy path with updating the config multiple times with a new value
    func testUpdateConfigurationWithDictTwiceWithNewValue() {
        setUpForUpdate()
        // test
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedin"]))
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedout"]))

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)

        XCTAssertEqual("optedin", mockRuntime.dispatchedEvents[0].data?["global.privacy"] as? String)
        XCTAssertEqual("optedout", mockRuntime.dispatchedEvents[1].data?["global.privacy"] as? String)

        XCTAssertEqual("optedin", mockRuntime.createdSharedStates[0]?["global.privacy"] as? String)
        XCTAssertEqual("optedout", mockRuntime.createdSharedStates[1]?["global.privacy"] as? String)
    }

    /// Tests the happy path with updating the config multiple times with new keys
    func testUpdateConfigurationWithDictWithNewKeys() {
        setUpForUpdate()
        // test
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedin"]))
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["analytics.server": "server"]))

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents[0].data?.count)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents[1].data?.count)
        XCTAssertEqual("server", mockRuntime.dispatchedEvents[1].data?["analytics.server"] as? String)

        XCTAssertEqual(1, mockRuntime.createdSharedStates[0]?.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates[1]?.count)
        XCTAssertEqual("server", mockRuntime.createdSharedStates[1]?["analytics.server"] as? String)
    }

    /// Tests the case where the update dict is empty, and should not dispatch a configuration response content event
    func testUpdateConfigurationWithEmptyDict() {
        setUpForUpdate()
        // test
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: [:]))

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
    }

    func testUpdateConfigurationPersistsReboot() {
        setUpForUpdate()
        // test
        let updateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedOut"])
        mockRuntime.simulateComingEvents(updateEvent)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)

        XCTAssertEqual("optedOut", mockRuntime.dispatchedEvents[0].data?["global.privacy"] as? String)

        XCTAssertEqual("optedOut", mockRuntime.createdSharedStates[0]?["global.privacy"] as? String)

        // reboot
        mockRuntime = TestableExtensionRuntime()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)

        let sharedState = mockRuntime.createdSharedStates[0]
        XCTAssertEqual("optedOut", sharedState?["global.privacy"] as? String)
    }

    // Tests that reverting config after some updates will revert any changes to config made in updates
    func testRevertUpdateConfigWithCachedConfigNoReboot() {
        setupWithCachedConfig()

        // First update the config with a new value for an existing key
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["analytics.server": "update1"]))
        // Now update the existing key, and add a new value
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["analytics.server": "update2", "newKey": "newValue"]))
        // Revert the changes
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createRevertUpdateEvent())
        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(3, mockRuntime.createdSharedStates.count)

        XCTAssertEqual(4, mockRuntime.dispatchedEvents[0].data?.count)
        XCTAssertEqual(5, mockRuntime.dispatchedEvents[1].data?.count)
        XCTAssertEqual(4, mockRuntime.dispatchedEvents[2].data?.count)

        XCTAssertEqual("update1", mockRuntime.dispatchedEvents[0].data?["analytics.server"] as? String)
        XCTAssertEqual("update2", mockRuntime.dispatchedEvents[1].data?["analytics.server"] as? String)
        XCTAssertEqual("newValue", mockRuntime.dispatchedEvents[1].data?["newKey"] as? String)
        XCTAssertEqual("default", mockRuntime.dispatchedEvents[2].data?["analytics.server"] as? String)
        // Make sure key added via update is gone
        XCTAssertNil(mockRuntime.dispatchedEvents[2].data?["newKey"] as? String)


        XCTAssertEqual(4, mockRuntime.createdSharedStates[0]?.count)
        XCTAssertEqual(5, mockRuntime.createdSharedStates[1]?.count)
        XCTAssertEqual(4, mockRuntime.createdSharedStates[2]?.count)
        XCTAssertEqual("update1", mockRuntime.createdSharedStates[0]?["analytics.server"] as? String)
        XCTAssertEqual("update2", mockRuntime.createdSharedStates[1]?["analytics.server"] as? String)
        XCTAssertEqual("newValue", mockRuntime.createdSharedStates[1]?["newKey"] as? String)
        XCTAssertEqual("default", mockRuntime.createdSharedStates[2]?["analytics.server"] as? String)
    }

    // Tests that reverting config after some updates will revert any changes to config made in updates and persists after reboot
    func testRevertUpdateConfigWithCachedConfigPersistsReboot() {
        setupWithCachedConfig()

        // First update the config with a new value for an existing key
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["analytics.server": "update1"]))
        // Now update the existing key, and add a new value
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["analytics.server": "update2", "newKey": "newValue"]))
        // Revert the changes
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createRevertUpdateEvent())
        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(3, mockRuntime.createdSharedStates.count)

        XCTAssertEqual(4, mockRuntime.dispatchedEvents[0].data?.count)
        XCTAssertEqual(5, mockRuntime.dispatchedEvents[1].data?.count)
        XCTAssertEqual(4, mockRuntime.dispatchedEvents[2].data?.count)

        XCTAssertEqual("update1", mockRuntime.dispatchedEvents[0].data?["analytics.server"] as? String)
        XCTAssertEqual("update2", mockRuntime.dispatchedEvents[1].data?["analytics.server"] as? String)
        XCTAssertEqual("newValue", mockRuntime.dispatchedEvents[1].data?["newKey"] as? String)
        XCTAssertEqual("default", mockRuntime.dispatchedEvents[2].data?["analytics.server"] as? String)
        // Make sure key added via update is gone
        XCTAssertNil(mockRuntime.dispatchedEvents[2].data?["newKey"] as? String)


        XCTAssertEqual(4, mockRuntime.createdSharedStates[0]?.count)
        XCTAssertEqual(5, mockRuntime.createdSharedStates[1]?.count)
        XCTAssertEqual(4, mockRuntime.createdSharedStates[2]?.count)
        XCTAssertEqual("update1", mockRuntime.createdSharedStates[0]?["analytics.server"] as? String)
        XCTAssertEqual("update2", mockRuntime.createdSharedStates[1]?["analytics.server"] as? String)
        XCTAssertEqual("newValue", mockRuntime.createdSharedStates[1]?["newKey"] as? String)
        XCTAssertEqual("default", mockRuntime.createdSharedStates[2]?["analytics.server"] as? String)

        // Simulate reboot
        mockRuntime = TestableExtensionRuntime()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)

        let sharedState = mockRuntime.createdSharedStates[0]
        let event = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual("default", event.data?["analytics.server"] as? String)
        XCTAssertNil(event.data?["newKey"])
        XCTAssertEqual("default", sharedState?["analytics.server"] as? String)
        XCTAssertNil(sharedState?["newKey"])
    }

    // Tests that updating config, reverting the update and then updating again will not have keys from first update
    func testUpdateRevertUpdateConfig() {
        setupWithCachedConfig()

        // First update the config with a new value for an existing key
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["analytics.server": "update1", "shouldNotExist": "afterRevert"]))
        // Revert the changes
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createRevertUpdateEvent())
        // Now update the existing key, and add a new value
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["analytics.server": "update2", "newKey": "newValue"]))

        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(3, mockRuntime.createdSharedStates.count)

        XCTAssertEqual(5, mockRuntime.dispatchedEvents[0].data?.count)
        XCTAssertEqual(4, mockRuntime.dispatchedEvents[1].data?.count)
        XCTAssertEqual(5, mockRuntime.dispatchedEvents[2].data?.count)

        XCTAssertEqual("update1", mockRuntime.dispatchedEvents[0].data?["analytics.server"] as? String)
        XCTAssertEqual("afterRevert", mockRuntime.dispatchedEvents[0].data?["shouldNotExist"] as? String)
        XCTAssertEqual("default", mockRuntime.dispatchedEvents[1].data?["analytics.server"] as? String)
        XCTAssertNil(mockRuntime.dispatchedEvents[1].data?["shouldNotExist"] as? String)
        XCTAssertEqual("update2", mockRuntime.dispatchedEvents[2].data?["analytics.server"] as? String)
        XCTAssertEqual("newValue", mockRuntime.dispatchedEvents[2].data?["newKey"] as? String)
        XCTAssertNil(mockRuntime.dispatchedEvents[2].data?["shouldNotExist"] as? String)


        XCTAssertEqual(5, mockRuntime.createdSharedStates[0]?.count)
        XCTAssertEqual(4, mockRuntime.createdSharedStates[1]?.count)
        XCTAssertEqual(5, mockRuntime.createdSharedStates[2]?.count)

        XCTAssertEqual("update1", mockRuntime.createdSharedStates[0]?["analytics.server"] as? String)
        XCTAssertEqual("afterRevert", mockRuntime.createdSharedStates[0]?["shouldNotExist"] as? String)
        XCTAssertEqual("default", mockRuntime.createdSharedStates[1]?["analytics.server"] as? String)
        XCTAssertNil(mockRuntime.createdSharedStates[1]?["shouldNotExist"] as? String)
        XCTAssertEqual("update2", mockRuntime.createdSharedStates[2]?["analytics.server"] as? String)
        XCTAssertEqual("newValue", mockRuntime.createdSharedStates[2]?["newKey"] as? String)
        XCTAssertNil(mockRuntime.createdSharedStates[2]?["shouldNotExist"] as? String)
    }

    static func createConfigUpdateEvent(configDict: [String: Any]) -> Event {
        return Event(name: "Configure with file path", type: EventType.configuration, source: EventSource.requestContent,
                     data: ["config.update": configDict])
    }

    static func createRevertUpdateEvent() -> Event {
        return Event(name: CoreConstants.EventNames.CLEAR_UPDATED_CONFIGURATION, type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.CLEAR_UPDATED_CONFIG: true])
    }
}
