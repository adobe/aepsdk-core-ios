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

import AEPCoreMocks

@testable import AEPCore
@testable import AEPServices
@testable import AEPSignal

@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
class EventPlusSignalTests: XCTestCase {
    var signal: Signal!
    
    // before each
    override func setUp() {
        signal = Signal(runtime: TestableExtensionRuntime())
        signal.onRegistered()
    }
    
    /// validate for correctness when consequenceType is postback
    func testPostbackConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.POSTBACK)
        
        // verify
        XCTAssertTrue(event.isPostback)
        XCTAssertFalse(event.isCollectPii)
        XCTAssertFalse(event.isOpenUrl)
    }
    
    /// validate for correctness when consequenceType is open url
    func testOpenUrlConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.OPEN_URL)
        
        // verify
        XCTAssertFalse(event.isPostback)
        XCTAssertFalse(event.isCollectPii)
        XCTAssertTrue(event.isOpenUrl)
    }
    
    /// validate for correctness when consequenceType is collectPii
    func testCollectPiiConsequenceType() throws {
        // setup
        let event = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.PII)
        
        // verify
        XCTAssertFalse(event.isPostback)
        XCTAssertTrue(event.isCollectPii)
        XCTAssertFalse(event.isOpenUrl)
    }
    
    /// validate correctness for postback/pii details payload
    func testPostbackPiiPayload() throws {
        // setup
        let event = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.POSTBACK)
        
        // verify
        XCTAssertTrue(event.isPostback)
        XCTAssertEqual("application/json", event.contentType!)
        XCTAssertEqual("https://www.postback.com", event.templateUrl!)
        XCTAssertEqual("{\"key\":\"value\"}", event.templateBody!)
        XCTAssertEqual(4, event.timeout!)
    }
    
    /// validate correctness for openurl payload
    func testOpenUrlPayload() throws {
        // setup
        let event = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.OPEN_URL)
        
        // verify
        XCTAssertTrue(event.isOpenUrl)
        XCTAssertEqual("https://www.testingopenurl.com", event.urlToOpen!)
    }
    
    /// validate no consequence type found
    func testNoConsequenceType() throws {
        // setup
        let triggeredConsequence: [String : Any] = [
            SignalConstants.EventDataKeys.ID : UUID().uuidString,
            SignalConstants.EventDataKeys.DETAIL : [:]
        ]
        let event = Event(name: "Test Rules Engine response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: triggeredConsequence)
        
        // verify
        XCTAssertFalse(event.isPostback)
        XCTAssertFalse(event.isCollectPii)
        XCTAssertFalse(event.isOpenUrl)
    }
    
    /// validate no details in triggered consequence
    func testNoDetails() throws {
        // setup
        let triggeredConsequence: [String : Any] = [
            SignalConstants.EventDataKeys.DETAIL : [:]
        ]
        let event = Event(name: "Test Rules Engine response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: triggeredConsequence)
        
        // verify
        XCTAssertNil(event.contentType)
        XCTAssertNil(event.templateUrl)
        XCTAssertNil(event.templateBody)
        XCTAssertNil(event.timeout)
        XCTAssertNil(event.urlToOpen)
    }
        
    // MARK: - Helpers
    /// Gets an event to use for simulating a rules consequence
    ///
    /// - Parameter privacy: value to set for privacy status in the returned event
    /// - Returns: an Event suitable for use with `TestableExtensionRuntime.simulateSharedState`
    func getRulesResponseEvent(type: String) -> Event {
        // details are the same for postback and pii, different for open url
        let details = type == SignalConstants.ConsequenceTypes.OPEN_URL ? [
            SignalConstants.EventDataKeys.URL : "https://www.testingopenurl.com"
        ] :
            [
                SignalConstants.EventDataKeys.CONTENT_TYPE : "application/json",
                SignalConstants.EventDataKeys.TEMPLATE_URL : "https://www.postback.com",
                SignalConstants.EventDataKeys.TEMPLATE_BODY : "{\"key\":\"value\"}",
                SignalConstants.EventDataKeys.TIMEOUT : 4
            ]
        
        let triggeredConsequence = [
            SignalConstants.EventDataKeys.TRIGGERED_CONSEQUENCE : [
                SignalConstants.EventDataKeys.ID : UUID().uuidString,
                SignalConstants.EventDataKeys.TYPE : type,
                SignalConstants.EventDataKeys.DETAIL : details
            ]
        ]
        let rulesEvent = Event(name: "Test Rules Engine response",
                               type: EventType.rulesEngine,
                               source: EventSource.responseContent,
                               data: triggeredConsequence)
        return rulesEvent
    }
    
    /// Helper to update the nested detail dictionary in a consequence event's event data
    func updateDetailDict(dict: [String : Any], withValue: Any?, forKey: String) -> [String : Any] {
        var returnDict = dict
        guard var consequence = dict[SignalConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] as? [String : Any] else {
            return returnDict
        }
        guard var detail = consequence[SignalConstants.EventDataKeys.DETAIL] as? [String : Any] else {
            return returnDict
        }
        
        detail[forKey] = withValue
        consequence[SignalConstants.EventDataKeys.DETAIL] = detail
        returnDict[SignalConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] = consequence
        
        return returnDict
    }
}
