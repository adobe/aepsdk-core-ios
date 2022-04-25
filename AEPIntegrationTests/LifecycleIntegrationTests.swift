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

class LifecycleIntegrationTests: XCTestCase {
    var mockNetworkService = TestableNetworkService()
    let defaultSuccessResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])

    override func setUp() {
        UserDefaults.clear()
        FileManager.default.clearCache()
        ServiceProvider.shared.reset()
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

    }

    func initExtensionsAndWait() {
        EventHub.reset()
        mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService

        let initExpectation = XCTestExpectation(description: "init extensions")
        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
            initExpectation.fulfill()
        }
        wait(for: [initExpectation], timeout: 1)
    }

    func testInstall() {
        // setup
        let configData = """
        {
          "lifecycle.sessionTimeout": 300,
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")

        let lifecycleExpectation = XCTestExpectation(description: "singal triggered by lifecycle event")
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.lifecycle.com") {
                lifecycleExpectation.fulfill()
                XCTAssertTrue(request.url.absoluteString.contains("installevent=InstallEvent"))
                return (data: nil, response: self.defaultSuccessResponse, error: nil)
            }
            return nil
        }

        MobileCore.lifecycleStart(additionalContextData: nil)
        wait(for: [lifecycleExpectation], timeout: 2)
    }

    func testLaunchEvent() {
        // setup
        let configData = """
        {
          "lifecycle.sessionTimeout": 1,
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")

        // test
        MobileCore.lifecycleStart(additionalContextData: nil)
        MobileCore.lifecyclePause()
        sleep(2)

        // restart
        initExtensionsAndWait()
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")
        let lifecycleExpectation = XCTestExpectation(description: "singal triggered by lifecycle event")
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.lifecycle.com") {
                lifecycleExpectation.fulfill()
                XCTAssertTrue(request.url.absoluteString.contains("installevent=&"))
                XCTAssertTrue(request.url.absoluteString.contains("launchevent=LaunchEvent"))
                return (data: nil, response: self.defaultSuccessResponse, error: nil)
            }
            return nil
        }

        MobileCore.lifecycleStart(additionalContextData: nil)
        wait(for: [lifecycleExpectation], timeout: 3)
    }

    func testCrash() {
        // setup
        let configData = """
        {
          "lifecycle.sessionTimeout": 1,
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")

        // test
        MobileCore.lifecycleStart(additionalContextData: nil)
        sleep(2)

        // restart
        initExtensionsAndWait()
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")
        let lifecycleExpectation = XCTestExpectation(description: "singal triggered by lifecycle event")
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.lifecycle.com") {
                lifecycleExpectation.fulfill()
                XCTAssertTrue(request.url.absoluteString.contains("installevent=&"))
                XCTAssertTrue(request.url.absoluteString.contains("launchevent=LaunchEvent"))
                XCTAssertTrue(request.url.absoluteString.contains("crashevent=CrashEvent"))
                return (data: nil, response: self.defaultSuccessResponse, error: nil)
            }
            return nil
        }

        MobileCore.lifecycleStart(additionalContextData: nil)
        wait(for: [lifecycleExpectation], timeout: 3)
    }

    func testAdditionalContextData() {
        // setup
        let configData = """
        {
          "lifecycle.sessionTimeout": 1,
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")

        // test
        let lifecycleExpectation = XCTestExpectation(description: "singal triggered by lifecycle event")
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.lifecycle.com") {
                lifecycleExpectation.fulfill()
                XCTAssertTrue(request.url.absoluteString.contains("key=value"))
                return (data: nil, response: self.defaultSuccessResponse, error: nil)
            }
            return nil
        }

        MobileCore.lifecycleStart(additionalContextData: ["key": "value"])
        wait(for: [lifecycleExpectation], timeout: 2)
    }

    func testSessionContinue() {
        // setup
        let configData = """
        {
          "lifecycle.sessionTimeout": 10,
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")

        // test
        MobileCore.lifecycleStart(additionalContextData: nil)
        MobileCore.lifecyclePause()
        sleep(2)

        // restart
        initExtensionsAndWait()
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_lifecycle")
        let lifecycleExpectation = XCTestExpectation(description: "no singal triggered by lifecycle event")
        lifecycleExpectation.isInverted = true
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.lifecycle.com") {
                lifecycleExpectation.fulfill()
                return (data: nil, response: self.defaultSuccessResponse, error: nil)
            }
            return nil
        }

        MobileCore.lifecycleStart(additionalContextData: nil)
        wait(for: [lifecycleExpectation], timeout: 2)
    }

    func mockRemoteConfigAndRules(for appId: String, with configData: Data?, localRulesName: String) {
        let configExpectation = XCTestExpectation(description: "read remote configruation")
        let rulesExpectation = XCTestExpectation(description: "read remote rules")

        let response = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])

        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://assets.adobedtm.com") {
                configExpectation.fulfill()
                return (data: configData, response: response, error: nil)
            }
            if request.url.absoluteString.starts(with: "https://rules.com/") {
                let filePath = Bundle(for: type(of: self)).url(forResource: localRulesName, withExtension: ".zip")
                let data = try? Data(contentsOf: filePath!)
                rulesExpectation.fulfill()
                return (data: data, response: response, error: nil)
            }
            return nil
        }
        MobileCore.configureWith(appId: appId)
        wait(for: [configExpectation, rulesExpectation], timeout: 2)

    }

}
