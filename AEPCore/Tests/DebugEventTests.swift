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

@testable import AEPCore
import AEPCoreMocks

class DebugEventTests: XCTestCase, AnyCodableAsserts {
    private let TEST_EVENT_NAME = "testName"
    private let TEST_EVENT_TYPE = EventType.system
    private let TEST_EVENT_SOURCE = EventSource.debug
    private let DEBUG_KEY = "debug"
    private let TYPE_KEY = "eventType"
    private let SOURCE_KEY = "eventSource"
    private let NOT_DEBUG_DUMMY_DATA = ["testData": "testDataVal"]
    
    func testTypeNilWhenNotDebugEvent() {
        let event = Event(name: TEST_EVENT_NAME, type: EventType.hub, source: EventSource.requestContent, data: NOT_DEBUG_DUMMY_DATA)
        XCTAssertNil(event.debugEventType)
    }
    
    func testTypeNilWhenDataNil() {
        let event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: nil)
        XCTAssertNil(event.debugEventType)
    }
    
    func testTypeNilWhenDebugNotMap() {
        let event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [DEBUG_KEY: "debug"])
        XCTAssertNil(event.debugEventType)
    }
    
    func testGetTypeWhenIsDebugEvent() {
        let event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [DEBUG_KEY: [TYPE_KEY: EventType.rulesEngine, SOURCE_KEY: EventSource.responseContent]])
        
        XCTAssertEqual(event.debugEventType, EventType.rulesEngine)
    }
    
    func testSourceNilWhenNotDebugEvent() {
        let event = Event(name: TEST_EVENT_NAME, type: EventType.hub, source: EventSource.requestContent, data: NOT_DEBUG_DUMMY_DATA)
        XCTAssertNil(event.debugEventSource)
    }
    
    func testSourceNilWhenDataNil() {
        let event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: nil)
        XCTAssertNil(event.debugEventSource)
    }
    
    func testSourceNilWhenDebugNotMap() {
        let event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [DEBUG_KEY: "debug"])
        XCTAssertNil(event.debugEventSource)
    }
    
    func testGetSourceWhenIsDebugEvent() {
        let event = Event(name: TEST_EVENT_NAME, type: TEST_EVENT_TYPE, source: TEST_EVENT_SOURCE, data: [DEBUG_KEY: [TYPE_KEY: EventType.rulesEngine, SOURCE_KEY: EventSource.responseContent]])
        
        XCTAssertEqual(event.debugEventSource, EventSource.responseContent)
    }
}

