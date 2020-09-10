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

class SignalIntegrationTests: XCTestCase {
    var mockNetworkService = TestableNetworkService()
    let defaultSucsessResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])

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
        wait(for: [initExpection], timeout: 1)
    }

    func testGetRequest() {
        // setup
        mockRemoteRules(with: "rules_signal")
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedin",
                                                        "rules.url": "https://rules.com/rules.zip"])

        let requestExpection = XCTestExpectation()
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.signal.com") {
                XCTAssertEqual("https://www.signal.com?name=testGetRequest", request.url.absoluteString)
                XCTAssertEqual(HttpMethod.get, request.httpMethod)
                requestExpection.fulfill()
                return (data: nil, respsonse: self.defaultSucsessResponse, error: nil)
            }
            return nil
        }

        let event = Event(name: "Test", type: "type", source: "source", data: ["name": "testGetRequest"])
        MobileCore.dispatch(event: event)
        wait(for: [requestExpection], timeout: 2)
    }

    func testPostRequest() {
        // setup
        mockRemoteRules(with: "rules_signal")
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedin",
                                                        "rules.url": "https://rules.com/rules.zip"])

        let requestExpection = XCTestExpectation()
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.signal.com") {
                XCTAssertEqual("https://www.signal.com?name=testPostRequest", request.url.absoluteString)
                XCTAssertEqual(HttpMethod.post, request.httpMethod)
                XCTAssertEqual("name=testPostRequest", request.connectPayload)
                XCTAssertEqual("zip", request.httpHeaders["Content-Type"])
                XCTAssertEqual(2, request.connectTimeout)
                XCTAssertEqual(2, request.readTimeout)
                requestExpection.fulfill()
                return (data: nil, respsonse: self.defaultSucsessResponse, error: nil)
            }
            return nil
        }

        let event = Event(name: "Test", type: "type", source: "source", data: ["name": "testPostRequest"])
        MobileCore.dispatch(event: event)
        wait(for: [requestExpection], timeout: 2)
    }

    func testOptedOut() {
        // setup
        mockRemoteRules(with: "rules_signal")
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedout",
                                                        "rules.url": "https://rules.com/rules.zip"])

        let requestExpection = XCTestExpectation()
        requestExpection.isInverted = true
        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://www.signal.com") {
                return (data: nil, respsonse: self.defaultSucsessResponse, error: nil)
            }
            return nil
        }

        let event1 = Event(name: "Test", type: "type", source: "source", data: ["name": "testPostRequest"])
        let event2 = Event(name: "Test", type: "type", source: "source", data: ["name": "testGetRequest"])
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        wait(for: [requestExpection], timeout: 2)
    }

    func mockRemoteRules(with localRulesName: String) {
        let response = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])

        mockNetworkService.mock { request in
            if request.url.absoluteString.starts(with: "https://rules.com/") {
                let filePath = Bundle(for: type(of: self)).url(forResource: localRulesName, withExtension: ".zip")
                let data = try? Data(contentsOf: filePath!)
                return (data: data, respsonse: response, error: nil)
            }
            return nil
        }

    }

}
