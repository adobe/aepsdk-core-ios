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

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: update shared state tests

    /// Tests the happy path with for updating the config with a dict
    func testUpdateConfigurationWithDict() {
        // setup
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
        // test
        mockRuntime.simulateComingEvents(ConfigurationUpdateTests.createConfigUpdateEvent(configDict: [:]))

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
    }

    func testUpdateConfigurationPersistsReboot() {
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

    static func createConfigUpdateEvent(configDict: [String: Any]) -> Event {
        return Event(name: "Configure with file path", type: EventType.configuration, source: EventSource.requestContent,
                     data: ["config.update": configDict])
    }
}
