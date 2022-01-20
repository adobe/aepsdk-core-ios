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
@testable import AEPCoreMocks
import XCTest

class MobileCore_ConfigurationTests: XCTestCase {
    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(Configuration.self)
        registerMockExtension(MockExtension.self)
    }

    override func tearDown() {
        EventHub.reset()
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }

        semaphore.wait()
    }

    /// Tests that a configuration request content event is dispatched with the appId
    func testConfigureWithAppId() {
        // setup
        let expectation = XCTestExpectation(description: "Configure with app id dispatches a configuration request content with the app id")
        expectation.assertForOverFulfill = true
        let expectedAppId = "test-app-id"

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let appid = event.data![ConfigurationConstants.Keys.JSON_APP_ID] as? String {
                XCTAssertEqual(expectedAppId, appid)
                expectation.fulfill()
            }
        }

        // test
        MobileCore.configureWith(appId: expectedAppId)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testConfigureWithFilePath() {
        // setup
        let expectation = XCTestExpectation(description: "Configure with file path dispatches a configuration request content with the file path")
        expectation.assertForOverFulfill = true
        let expectedFilePath = "test-file-path"

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let path = event.data![ConfigurationConstants.Keys.JSON_FILE_PATH] as? String {
                XCTAssertEqual(expectedFilePath, path)
                expectation.fulfill()
            }
        }

        // test
        MobileCore.configureWith(filePath: expectedFilePath)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that a configuration request content event is dispatched with the updated dict
    func testUpdateConfiguration() {
        // setup
        let expectation = XCTestExpectation(description: "Update configuration dispatches configuration request content with the updated configuration")
        expectation.assertForOverFulfill = true
        let updateDict = ["testKey": "testVal"]

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let updateEventData = event.data![ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: String] {
                XCTAssertEqual(updateDict, updateEventData)
                expectation.fulfill()
            }
        }

        // test
        MobileCore.updateConfigurationWith(configDict: updateDict)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that a configuration request content event is dispatched with the true value for a revert
    func testClearUpdateConfiguration() {
        let expect = expectation(description: "Revert updated configuration dispatches configuration request content with True")

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent, listener: { event in
            if let _ = event.data, let revert = event.data![ConfigurationConstants.Keys.CLEAR_UPDATED_CONFIG] as? Bool {
                XCTAssertTrue(revert)
                expect.fulfill()
            }
        })

        MobileCore.clearUpdatedConfiguration()

        wait(for: [expect], timeout: 1)

    }

    /// Tests that set privacy status dispatches a configuration request content event with the new privacy status
    func testSetPrivacy() {
        // setup
        let expectation = XCTestExpectation(description: "Set privacy dispatches configuration request content with the privacy status")
        expectation.assertForOverFulfill = true
        let updateDict = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let updateEventData = event.data![ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: String] {
                XCTAssertEqual(updateDict, updateEventData)
                expectation.fulfill()
            }
        }

        // test
        MobileCore.setPrivacyStatus(.optedIn)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that get privacy status dispatches an event of configuration request content with the correct retrieve config data
    func testGetPrivacy() {
        let expectation = XCTestExpectation(description: "Get privacy status dispatches configuration request content with the correct data")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let retrieveConfig = event.data![ConfigurationConstants.Keys.RETRIEVE_CONFIG] as? Bool {
                XCTAssertTrue(retrieveConfig)
                expectation.fulfill()
            }
        }

        // test
        MobileCore.getPrivacyStatus { _ in }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that getSdkIdentities dispatches a configuration request identity event
    func testGetSdkIdentities() {
        let expectation = XCTestExpectation(description: "getSdkIdentities dispatches a configuration request identity event")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestIdentity) { _ in
            expectation.fulfill()
        }

        // test
        MobileCore.getSdkIdentities { _, _ in }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that resetIdentities dispatches an generic identity event
    func testResetIdentities() {
        // setup
        let expectation = XCTestExpectation(description: "resetIdentities should dispatch an event")
        expectation.assertForOverFulfill = true
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericIdentity, source: EventSource.requestReset) { _ in
            expectation.fulfill()
        }

        // test
        MobileCore.resetIdentities()

        // verify
        wait(for: [expectation], timeout: 1)
    }
}
