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

import AEPIdentity
import AEPLifecycle
import AEPSignal

@testable import AEPCore
@testable import AEPCoreMocks
@testable import AEPServices

class ConfigurationIntegrationTests: XCTestCase {
    var mockNetworkService = TestableNetworkService()
    override func setUp() {
        NamedCollectionDataStore.clear()
        ServiceProvider.shared.reset()
        resetTestEnv()
        initExtensionsAndWait()
    }

    override func tearDown() {
        let unregisterExpectation = XCTestExpectation(description: "unregister extensions")
        unregisterExpectation.expectedFulfillmentCount = 2
        MobileCore.unregisterExtension(Identity.self) {
            unregisterExpectation.fulfill()
        }

        MobileCore.unregisterExtension(Signal.self) {
            unregisterExpectation.fulfill()
        }
        wait(for: [unregisterExpectation], timeout: 2)
        EventHub.shared.shutdown()
    }

    func resetTestEnv(){
        EventHub.reset()
        mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
    }

    func initExtensionsAndWait() {
        let initExpectation = XCTestExpectation(description: "init extensions")
        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
            initExpectation.fulfill()
        }
        wait(for: [initExpectation], timeout: 2)
    }

    func testConfigLocalFile() {

        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig-OptedOut", ofType: "json")!
        MobileCore.configureWith(filePath: path)
        XCTAssertEqual(.optedOut, getPrivacyStatus())
    }

    func testConfigAppId() {
        let configData = """
        {
          "global.privacy": "optedin"
        }
        """.data(using: .utf8)
        mockRemoteConfig(for: "appid", with: configData)
        XCTAssertEqual(.optedIn, getPrivacyStatus())
    }

    func testSetPrivacy() {

        let configData = """
        {
          "global.privacy": "optedin"
        }
        """.data(using: .utf8)
        mockRemoteConfig(for: "appid", with: configData)
        MobileCore.setPrivacyStatus(.optedOut)
        XCTAssertEqual(.optedOut, getPrivacyStatus())

    }

    func testUpdateConfig() {

        let configData = """
        {
          "global.privacy": "optedin"
        }
        """.data(using: .utf8)
        mockRemoteConfig(for: "appid", with: configData)
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedout"])
        XCTAssertEqual(.optedOut, getPrivacyStatus())
    }

    func testEnvironmentAwaralbe() {

        let configData = """
        {
          "global.privacy": "optedin",
          "__dev__global.privacy": "unknown",
          "build.environment": "dev"
        }
        """.data(using: .utf8)
        mockRemoteConfig(for: "appid", with: configData)
        XCTAssertEqual(.unknown, getPrivacyStatus())

        MobileCore.updateConfigurationWith(configDict: ["build.environment": "prod"])
        XCTAssertEqual(.optedIn, getPrivacyStatus())
    }

    func testUpdateConfigInSubsequentLaunch() {

        let configData = """
        {
          "global.privacy": "optedin"
        }
        """.data(using: .utf8)
        mockRemoteConfig(for: "appid", with: configData)
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedout"])
        XCTAssertEqual(.optedOut, getPrivacyStatus())

        resetTestEnv()
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
        }
        mockRemoteConfig(for: "appid", with: configData)
        XCTAssertEqual(.optedOut, getPrivacyStatus())
    }

    func testClearUpdatedConfig() {
        let configData = """
        {
          "global.privacy": "optedin"
        }
        """.data(using: .utf8)
        mockRemoteConfig(for: "appid", with: configData)
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedout"])
        XCTAssertEqual(.optedOut, getPrivacyStatus())
        MobileCore.clearUpdatedConfiguration()
        XCTAssertEqual(.optedIn, getPrivacyStatus())
    }

    func testClearUpdatedConfigFromSetPrivacyStatus() {
        let configData = """
        {
          "global.privacy": "optedin"
        }
        """.data(using: .utf8)
        mockRemoteConfig(for: "appid", with: configData)
        MobileCore.setPrivacyStatus(.optedOut)
        XCTAssertEqual(.optedOut, getPrivacyStatus())
        MobileCore.clearUpdatedConfiguration()
        XCTAssertEqual(.optedIn, getPrivacyStatus())

    }

    func mockRemoteConfig(for appId: String, with data: Data?) {
        let initExpectation = XCTestExpectation(description: "load remote configuration")

        let response = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])

        mockNetworkService.mock { request in
            initExpectation.fulfill()
            XCTAssertEqual("https://assets.adobedtm.com/\(appId).json", request.url.absoluteString)
            return (data: data, response: response, error: nil)
        }
        MobileCore.configureWith(appId: appId)
        wait(for: [initExpectation], timeout: 2)

    }

    func getPrivacyStatus() -> PrivacyStatus? {
        var returnedPrivacyStatus: PrivacyStatus?
        let privacyExpectation = XCTestExpectation(description: "get privacy status")
        MobileCore.getPrivacyStatus { privacyStatus in
            returnedPrivacyStatus = privacyStatus
            privacyExpectation.fulfill()
        }
        wait(for: [privacyExpectation], timeout: 2)
        return returnedPrivacyStatus

    }
}
