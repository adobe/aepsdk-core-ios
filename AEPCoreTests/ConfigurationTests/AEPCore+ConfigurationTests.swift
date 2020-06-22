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

class AEPCore_ConfigurationTests: XCTestCase {

    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(AEPConfiguration.self)
        registerMockExtension(MockExtension.self)
    }
    
    
    override func tearDown() {
        EventHub.reset()
    }
    
    private func registerMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { (error) in
            semaphore.signal()
        }

        semaphore.wait()
    }
    

    func testConfigureWithAppId() {
        // setup
        let expectation = XCTestExpectation(description: "Configure with app id dispatches a configuration request content with the app id")
        expectation.assertForOverFulfill = true
        let expectedAppId = "test-app-id"
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .requestContent) { (event) in
            if let _ = event.data, let appid = event.data![ConfigurationConstants.Keys.JSON_APP_ID] as? String {
                XCTAssertEqual(expectedAppId, appid)
                expectation.fulfill()
            }
        }
        
        // test
        AEPCore.configureWith(appId: expectedAppId)
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testConfigureWithFilePath() {
        // setup
        let expectation = XCTestExpectation(description: "Configure with file path dispatches a configuration request content with the file path")
        expectation.assertForOverFulfill = true
        let expectedFilePath = "test-file-path"
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .requestContent) { (event) in
            if let _ = event.data, let path = event.data![ConfigurationConstants.Keys.JSON_FILE_PATH] as? String {
                XCTAssertEqual(expectedFilePath, path)
                expectation.fulfill()
            }
        }
        
        // test
        AEPCore.configureWith(filePath: expectedFilePath)
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testUpdateConfiguration() {
        // setup
        let expectation = XCTestExpectation(description: "Update configuration dispatches configuration request content with the updated configuration")
        expectation.assertForOverFulfill = true
        let updateDict = ["testKey": "testVal"]
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .requestContent) { (event) in
            if let _ = event.data, let updateEventData = event.data![ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: String] {
                XCTAssertEqual(updateDict, updateEventData)
                expectation.fulfill()
            }
        }
        
        // test
        AEPCore.updateConfigurationWith(configDict: updateDict)
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testSetPrivacy() {
        // setup
        let expectation = XCTestExpectation(description: "Set privacy dispatches configuration request content with the privacy status")
        expectation.assertForOverFulfill = true
        let updateDict = [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .requestContent) { (event) in
            if let _ = event.data, let updateEventData = event.data![ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: String] {
                XCTAssertEqual(updateDict, updateEventData)
                expectation.fulfill()
            }
        }
        
        // test
        AEPCore.setPrivacy(status: PrivacyStatus.optedIn)
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testGetPrivacy() {
        let expectation = XCTestExpectation(description: "Get privacy status dispatches configuration request content with the correct data")
        expectation.assertForOverFulfill = true
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .configuration, source: .requestContent) { (event) in
            if let _ = event.data, let retrieveconfig = event.data![ConfigurationConstants.Keys.RETRIEVE_CONFIG] as? Bool {
                XCTAssertTrue(retrieveconfig)
                expectation.fulfill()
            }
        }
        
        // test
        AEPCore.getPrivacyStatus { (status) in}
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
}
