/*
 Copyright 2021 Adobe. All rights reserved.
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

class RulesEngineIntegrationTests: XCTestCase {
    var mockNetworkService = TestableNetworkService()
    let defaultSuccessResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])

    override func setUp() {
        NamedCollectionDataStore.clear()
        ServiceProvider.shared.reset()
        initExtensionsAndWait()
    }

    func initExtensionsAndWait() {
        EventHub.reset()
        mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService

        let initExpectation = XCTestExpectation(description: "init extensions")
        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions([]) {
            initExpectation.fulfill()
        }
        wait(for: [initExpectation], timeout: 1)
    }
    
    func testDispatchConsequence() {
        // Expected trigger event to match single dispatch consequence
        
        let configData = """
        {
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_dispatch_consequence")
        
        let parentEvent = Event(name: "Test Event Trigger",
                                type: "test.type.trigger",
                                source: "test.source.trigger",
                                data: ["xdm": "test data"])
        let expectation = XCTestExpectation(description: "validate dispatched events")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: "test.type.consequence",
                                         source: "test.source.consequence") { event in
            XCTAssertEqual("test.type.consequence", event.type)
            XCTAssertEqual("test.source.consequence", event.source)
            XCTAssertEqual("test data", event.data?["xdm"] as? String)
            XCTAssertEqual(parentEvent.id, event.parentID)
            expectation.fulfill()
        }
        
        MobileCore.dispatch(event: parentEvent)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testDispatchConsequence_eventTriggersTwoConsequences() {
        // Expected trigger event to match two dispatch consequences
        
        let configData = """
        {
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_dispatch_consequence")
        
        let expectation = XCTestExpectation(description: "validate dispatched events")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        let parentEvent = Event(name: "Test Event Trigger",
                                type: "test.type.trigger",
                                source: "test.source.trigger",
                                data: ["dispatch": "yes"])
        MobileCore.registerEventListener(type: "test.type.consequence",
                                         source: "test.source.consequence") { event in
            XCTAssertEqual("test.type.consequence", event.type)
            XCTAssertEqual("test.source.consequence", event.source)
            XCTAssertEqual("yes", event.data?["dispatch"] as? String)
            XCTAssertEqual(parentEvent.id, event.parentID)
            expectation.fulfill()
        }
        
        MobileCore.dispatch(event: parentEvent)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testDispatchConsequence_chainConsequence_doesNotLoop() {
        // Expected trigger event to match dispatch consequence 1
        // As max chain count is 1, expect dispatched consequence 1 event to not trigger any further dispatch consequences
        
        let configData = """
        {
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_dispatch_consequence")
        
        let expectation1 = XCTestExpectation(description: "validate dispatched consequence 1")
        expectation1.assertForOverFulfill = true
        MobileCore.registerEventListener(type: "test.type.consequence",
                                         source: "test.source.consequence") { event in
            expectation1.fulfill()
        }
        
        let expectation2 = XCTestExpectation(description: "validate dispatched consequence 2")
        expectation2.isInverted = true // with max chained consequences = 1, the second consequence is not expected
        MobileCore.registerEventListener(type: "test.type.consequence.2",
                                         source: "test.source.consequence.2") { event in
            expectation2.fulfill()
        }
        
        let expectation3 = XCTestExpectation(description: "validate dispatched consequence 3")
        expectation3.isInverted = true // with max chained consequences = 1, the third consequence is not expected
        MobileCore.registerEventListener(type: "test.type.consequence.3",
                                         source: "test.source.consequence.3") { event in
            expectation3.fulfill()
        }
        
        let event = Event(name: "Test Event Trigger",
                          type: "test.type.trigger",
                          source: "test.source.trigger",
                          data: ["chain": "yes"])
        MobileCore.dispatch(event: event)
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 3)
    }

    func mockRemoteConfigAndRules(for appId: String, with configData: Data?, localRulesName: String) {
        let configExpectation = XCTestExpectation(description: "read remote configuration")
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
