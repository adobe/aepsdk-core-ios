/*
 Copyright 2023 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
import AEPCoreMocks
@testable import AEPCore
@testable import AEPServices


class EventHistoryIntegrationTests: XCTestCase {
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
    
    func testEventHistoryWithoutEnforceOrder() {
        // hashed string will be "key:valuenumeric:552" - 1254850096
        let event2 = Event(name: "name", type: "type", source: "source", data: [
            "key": "value",
            "key2": "value2",
            "numeric": 552
        ], mask: [
            "key",
            "numeric"
        ])
                
        let event1 = event2.copyWithNewTimeStamp(event2.timestamp - 10)
        
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        
        Thread.sleep(forTimeInterval:0.5)
        
        let validReq = EventHistoryRequest(mask: ["key": "value", "numeric": 552])
        let invalidReq = EventHistoryRequest(mask: ["key": "value"])
        let reqInvalidTime = EventHistoryRequest(mask: ["key": "value", "numeric": 552], to: event1.timestamp + 5)

        let expectation = XCTestExpectation(description: "validate event history")
        EventHub.shared.getHistoricalEvents([validReq, invalidReq, reqInvalidTime], enforceOrder: false, handler: { res in
            XCTAssertEqual(res.count, 3)
            
            //validReq
            XCTAssertEqual(res[0].count, 2)
            XCTAssertEqual(res[0].oldestOccurrence?.millisecondsSince1970, event1.timestamp.millisecondsSince1970)
            XCTAssertEqual(res[0].newestOccurrence?.millisecondsSince1970, event2.timestamp.millisecondsSince1970)
            
            //invalidReq
            XCTAssertEqual(res[1].count, 0)
            XCTAssertEqual(res[1].oldestOccurrence, Date(timeIntervalSince1970: 0))
            XCTAssertEqual(res[1].newestOccurrence, Date(timeIntervalSince1970: 0))
            
            //reqInvalidTime
            XCTAssertEqual(res[2].count, 1)
            XCTAssertEqual(res[2].oldestOccurrence?.millisecondsSince1970, event1.timestamp.millisecondsSince1970)
            XCTAssertEqual(res[2].newestOccurrence?.millisecondsSince1970, event1.timestamp.millisecondsSince1970)
            
            expectation.fulfill()
            
        })

        wait(for: [expectation], timeout: 1)
    }
    
    func testEventHistoryWithEnforceOrder() {
        // hashed string will be "key:valuenumeric:552" - 1254850096
        let event2 = Event(name: "name", type: "type", source: "source", data: [
            "key": "value",
            "key2": "value2",
            "numeric": 552
        ], mask: [
            "key",
            "numeric"
        ])
                
        var event1 = Event(name: "name", type: "type", source: "source", data: [
            "key": "value",
        ], mask: [
            "key",
        ])
        event1 = event1.copyWithNewTimeStamp(event2.timestamp - 10)
        
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
                
        Thread.sleep(forTimeInterval:0.5)
        
        let reqEvent1 = EventHistoryRequest(mask: ["key": "value"])
        let reqEvent2 = EventHistoryRequest(mask: ["key": "value", "numeric": 552])
        
        let expectation = XCTestExpectation(description: "validate event history")
        EventHub.shared.getHistoricalEvents([reqEvent1, reqEvent2], enforceOrder: true, handler: { res in
            XCTAssertEqual(res.count, 2)
            
            //reqEvent1
            XCTAssertEqual(res[0].count, 1)
            
            //reqEvent2
            XCTAssertEqual(res[1].count, 1)
            
            expectation.fulfill()
        })
        
        let expectation2 = XCTestExpectation(description: "validate event history")
        EventHub.shared.getHistoricalEvents([reqEvent2, reqEvent1], enforceOrder: true, handler: { res in
            XCTAssertEqual(res.count, 2)
            
            //reqEvent2
            XCTAssertEqual(res[0].count, 1)
            
            //reqEvent1 - returns 0, out of order
            XCTAssertEqual(res[1].count, 0)
            
            expectation2.fulfill()
        })

        wait(for: [expectation, expectation2], timeout: 1)
    }
    
    func testRulesAreAppliedBeforePersistingEvents() {
        let configData = """
        {
          "global.privacy": "optedin",
          "rules.url" : "https://rules.com/rules.zip"
        }
        """.data(using: .utf8)
        mockRemoteConfigAndRules(for: "appid", with: configData, localRulesName: "rules_attach")
        // Wait for rules to load
        Thread.sleep(forTimeInterval:1)
        
        let event = Event(name: "name", type: "type", source: "source", data: [
            "key2": "value2",
            "numeric": 552
        ], mask: [
            "key",
            "numeric"
        ])
        // The rules engine will attach "key":"value" to event data.
        MobileCore.dispatch(event: event)
        
        Thread.sleep(forTimeInterval:0.5)
        
        let reqEvent1 = EventHistoryRequest(mask: ["key": "value", "numeric": 552])
        let expectation = XCTestExpectation(description: "validate event history")
        EventHub.shared.getHistoricalEvents([reqEvent1], enforceOrder: false, handler: { res in
            XCTAssertEqual(res.count, 1)
            
            //reqEvent1
            XCTAssertEqual(res[0].count, 1)
            
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 1)
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

private extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
