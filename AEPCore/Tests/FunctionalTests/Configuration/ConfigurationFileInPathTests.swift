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
import XCTest
import AEPCoreMocks
import AEPServices
import AEPServicesMocks
import XCTest

class ConfigurationFileInPathTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var configuration: Configuration!

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    /// Tests the happy path when passing in a valid path to a bundled config
    func testLoadBundledConfig() {
        // setup
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)

        // test
        mockRuntime.simulateComingEvents(filePathEvent)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)

        XCTAssertEqual(16, mockRuntime.firstEvent?.data?.count)
        XCTAssertEqual(16, mockRuntime.firstSharedState?.count)
    }

    /// Tests the happy path when passing in a valid path to a bundled config and then updated the config
    func testLoadBundledConfigAndUpdate() {
        // setup
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)
        let configUpdateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedOut"])

        // test
        mockRuntime.simulateComingEvents(filePathEvent, configUpdateEvent)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
        XCTAssertEqual(EventType.configuration, mockRuntime.secondEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.secondEvent?.source)

        XCTAssertEqual("optedin", mockRuntime.dispatchedEvents[0].data?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.dispatchedEvents[1].data?["global.privacy"] as? String)

        XCTAssertEqual("optedin", mockRuntime.createdSharedStates[0]?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.createdSharedStates[1]?["global.privacy"] as? String)
    }

    /// Tests the happy path when updating config and then using a filepath after still uses updated config data
    func testUpdateSupercedesFilePath() {
        // setup
        let configUpdateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedOut"])
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)
        let filePathEvent2 = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)
        // test
        mockRuntime.simulateComingEvents(filePathEvent, configUpdateEvent, filePathEvent2)

        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(3, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
        XCTAssertEqual(EventType.configuration, mockRuntime.secondEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.secondEvent?.source)
        XCTAssertEqual(EventType.configuration, mockRuntime.thirdEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.thirdEvent?.source)

        XCTAssertEqual("optedin", mockRuntime.dispatchedEvents[0].data?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.dispatchedEvents[1].data?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.dispatchedEvents[2].data?["global.privacy"] as? String)

        XCTAssertEqual("optedin", mockRuntime.createdSharedStates[0]?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.createdSharedStates[1]?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.createdSharedStates[2]?["global.privacy"] as? String)
    }

    func testUpdateConfigurationWithEnvAwareConfig() {
        // setup
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)

        // test
        mockRuntime.simulateComingEvents(filePathEvent)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)

        XCTAssertEqual("prodmobile5adobe.store.sprint.demo", mockRuntime.dispatchedEvents[0].data?["analytics.rsids"] as? String)
        XCTAssertEqual("prodmobile5adobe.store.sprint.demo", mockRuntime.createdSharedStates[0]?["analytics.rsids"] as? String)
    }

    /// Tests the API call where the path to the config is invalid
    func testLoadInvalidPathBundledConfig() {
        // setup
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: "Invalid/Path/ADBMobileConfig.json")

        // test
        mockRuntime.simulateComingEvents(filePathEvent)

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count, "Configuration still should update shared state")

        XCTAssertEqual(0, mockRuntime.firstSharedState?.count)
    }

    /// Test that programmatic config is applied over the (failed) loaded json
    func testLoadInvalidBundledConfigWithProgrammaticApplied() {
        // setup
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: "Invalid/Path/ADBMobileConfig.json")
        let configUpdateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedOut"])

        // test
        mockRuntime.simulateComingEvents(filePathEvent, configUpdateEvent)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)

        XCTAssertEqual(1, mockRuntime.firstEvent?.data?.count)

        XCTAssertEqual(0, mockRuntime.firstSharedState?.count)
        XCTAssertEqual(1, mockRuntime.secondSharedState?.count)

        XCTAssertEqual("optedOut", mockRuntime.dispatchedEvents[0].data?["global.privacy"] as? String)
        XCTAssertNil(mockRuntime.createdSharedStates[0]?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.createdSharedStates[1]?["global.privacy"] as? String)
    }

    func testLoadBundledConfigDoesNotPersistReboot() {
        // setup
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)

        // test
        mockRuntime.simulateComingEvents(filePathEvent)

        setUp()

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(0, mockRuntime.createdSharedStates.count)
    }

    func testFilePathThenUpdateConfigurationPersistsReboot() {
        // test
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
        let filePathEvent = ConfigurationFileInPathTests.createConfigFilePathEvent(filePath: path)
        let updateEvent = ConfigurationUpdateTests.createConfigUpdateEvent(configDict: ["global.privacy": "optedOut"])
        mockRuntime.simulateComingEvents(filePathEvent, updateEvent)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
        XCTAssertEqual(EventType.configuration, mockRuntime.secondEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.secondEvent?.source)

        XCTAssertEqual("optedin", mockRuntime.dispatchedEvents[0].data?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.dispatchedEvents[1].data?["global.privacy"] as? String)

        XCTAssertEqual("optedin", mockRuntime.createdSharedStates[0]?["global.privacy"] as? String)
        XCTAssertEqual("optedOut", mockRuntime.createdSharedStates[1]?["global.privacy"] as? String)

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

    static func createConfigFilePathEvent(filePath: String) -> Event {
        return Event(name: "Configure with file path", type: EventType.configuration, source: EventSource.requestContent,
                     data: ["config.filePath": filePath])
    }
}
