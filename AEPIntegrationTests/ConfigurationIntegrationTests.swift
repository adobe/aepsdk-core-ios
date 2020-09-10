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
@testable import AEPServices
import AEPIdentity
import AEPLifecycle
import AEPSignal

class ConfigurationIntegrationTests: XCTestCase {
    var mockNetworkService = TestableNetworkService()
    override func setUp() {
        UserDefaults.clear()
        FileManager.default.clearCache()
        ServiceProvider.shared.reset()
        initExtensionsAndWait()
    }

    func initExtensionsAndWait() {
        EventHub.reset()
        mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService

        let initExpection = XCTestExpectation()
        MobileCore.setLogLevel(level: .trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
            initExpection.fulfill()
        }
        wait(for: [initExpection], timeout: 0.5)
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
        MobileCore.setPrivacy(status: .optedOut)
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

        initExtensionsAndWait()
        mockRemoteConfig(for: "appid", with: configData)
        XCTAssertEqual(.optedOut, getPrivacyStatus())
    }

    func mockRemoteConfig(for appId: String, with data: Data?) {
        let initExpection = XCTestExpectation()

        let response = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])

        mockNetworkService.mock { request in
            initExpection.fulfill()
            XCTAssertEqual("https://assets.adobedtm.com/\(appId).json", request.url.absoluteString)
            return (data: data, respsonse: response, error: nil)
        }
        MobileCore.configureWith(appId: appId)
        wait(for: [initExpection], timeout: 1)

    }

    func getPrivacyStatus() -> PrivacyStatus? {
        var returnedPrivacyStatus: PrivacyStatus?
        let privacyExpection = XCTestExpectation()
        MobileCore.getPrivacyStatus { privacyStatus in
            returnedPrivacyStatus = privacyStatus
            privacyExpection.fulfill()
        }
        wait(for: [privacyExpection], timeout: 2)
        return returnedPrivacyStatus

    }

}
