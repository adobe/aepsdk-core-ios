//
/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
import Foundation
@testable import AEPCore
import AEPCoreMocks

class DebugEventTests: XCTestCase, AnyCodableAsserts {
    private let TEST_EVENT_NAME = "testName"
    private let TEST_EVENT_TYPE = EventType.system
    private let TEST_EVENT_SOURCE = EventSource.debug
    private let TYPE_KEY = "eventType"
    private let SOURCE_KEY = "eventSource"
    private let NOT_DEBUG_DUMMY_DATA = ["testData": "testDataVal"]
    
    func testTypeNilWhenNotDebugEvent() {
        var event = Event(name: TEST_EVENT_NAME, type: EventType.hub, source: EventSource.requestContent, data: NOT_DEBUG_DUMMY_DATA)
        XCTAssertNil(event.debugEventType)
    }
    
    func testTypeNilWhenDataNil() {
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: nil)
        XCTAssertNil(event.debugEventType)
    }
    
    func testTypeNilWhenDebugNotMap() {
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [CoreConstants.Keys.DEBUG: "debug"])
        XCTAssertNil(event.debugEventType)
    }
    
    func testGetTypeWhenIsDebugEvent() {
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [CoreConstants.Keys.DEBUG: [TYPE_KEY: EventType.rulesEngine, SOURCE_KEY: EventSource.responseContent]])
        
        XCTAssertEqual(event.debugEventType, EventType.rulesEngine)
    }
    
    func testSourceNilWhenNotDebugEvent() {
        var event = Event(name: TEST_EVENT_NAME, type: EventType.hub, source: EventSource.requestContent, data: NOT_DEBUG_DUMMY_DATA)
        XCTAssertNil(event.debugEventSource)
    }
    
    func testSourceNilWhenDataNil() {
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: nil)
        XCTAssertNil(event.debugEventSource)
    }
    
    func testSourceNilWhenDebugNotMap() {
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [CoreConstants.Keys.DEBUG: "debug"])
        XCTAssertNil(event.debugEventSource)
    }
    
    func testGetSourceWhenIsDebugEvent() {
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [CoreConstants.Keys.DEBUG: [TYPE_KEY: EventType.rulesEngine, SOURCE_KEY: EventSource.responseContent]])
        
        XCTAssertEqual(event.debugEventSource, EventSource.responseContent)
    }
    
    func testGetDataNilWhenNotSystemEventType() {
        var event = Event(name: TEST_EVENT_NAME, type: EventType.hub, source: EventSource.debug, data: NOT_DEBUG_DUMMY_DATA)
        XCTAssertNil(event.debugEventData)
    }
    
    func testGetDataNilWhenNotDebugSource() {
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: EventSource.responseContent, data: NOT_DEBUG_DUMMY_DATA)
        XCTAssertNil(event.debugEventData)
    }
    
    func testGetDataWhenDebug() {
        var debugData = [CoreConstants.Keys.DEBUG: [TYPE_KEY: EventType.rulesEngine, SOURCE_KEY: EventSource.responseContent], "triggeredConsequence": ["id": "1234", "type": "schema"]]
        var event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: debugData)
        
        assertEqual(expected: debugData, actual: event.debugEventData)
    }
    
    
}

