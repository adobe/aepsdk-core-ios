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
@testable import AEPCoreMocks

class EventHistoryTests: XCTestCase {

    var eventHistory: EventHistory!
    var mockEventHistoryDatabase: MockEventHistoryDatabase!
    var mockEvent: Event!
    var expectedHash: UInt32!
    
    override func setUp() {
        eventHistory = EventHistory()
        mockEventHistoryDatabase = MockEventHistoryDatabase()
        eventHistory.db = mockEventHistoryDatabase
        
        // hashed string will be "key:valuenumeric:552" - 1254850096
        expectedHash = 1254850096
        mockEvent = Event(name: "name", type: "type", source: "source", data: [
            "key": "value",
            "key2": "value2",
            "numeric": 552
        ], mask: [
            "key",
            "numeric"
        ])
    }
    
    func testRecordEvent() throws {
        // setup
        let expectation = XCTestExpectation(description: "handler called")
        mockEventHistoryDatabase.returnInsert = true
        let handler: (Bool) -> Void = { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        
        // test
        eventHistory.recordEvent(mockEvent, handler: handler)
        wait(for: [expectation], timeout: 1)
        
        // verify
        XCTAssertEqual(expectedHash, mockEventHistoryDatabase.paramHash)
    }
    
    func testRecordEventNoHandler() throws {
        // setup
        let expectation = XCTestExpectation(description: "handler called")
        expectation.isInverted = true
        mockEventHistoryDatabase.returnInsert = true
        
        // test
        eventHistory.recordEvent(mockEvent)
        wait(for: [expectation], timeout: 1)
        
        // verify
        XCTAssertEqual(expectedHash, mockEventHistoryDatabase.paramHash)
    }
    
    func testRecordEventEmptyData() throws {
        // setup
        let expectation = XCTestExpectation(description: "handler called")
        let handler: (Bool) -> Void = { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        let eventWithNoData = Event(name: "name", type: "type", source: "source", data: nil, mask: ["key"])
        
        // test
        eventHistory.recordEvent(eventWithNoData, handler: handler)
        wait(for: [expectation], timeout: 1)
        
        // verify
        XCTAssertNil(mockEventHistoryDatabase.paramHash, "database insert method should not be called")
        
    }
    
    func testGetEventsEnforceOrder() throws {
        // setup
        let expectation = XCTestExpectation(description: "handler called")
        let mockCount = 552
        let mockOldestDate = Date(milliseconds: 12345)
        let mockNewestDate = Date(milliseconds: 23456)
        mockEventHistoryDatabase.returnSelect = EventHistoryResult(count: mockCount, oldest: mockOldestDate, newest: mockNewestDate)
        let handler: ([EventHistoryResult]) -> Void = { results in
            XCTAssertNotNil(results)
            XCTAssertEqual(1, results.count)
            XCTAssertEqual(mockCount, results.first?.count)
            XCTAssertEqual(mockOldestDate, results.first?.oldestOccurrence)
            XCTAssertEqual(mockNewestDate, results.first?.newestOccurrence)
            expectation.fulfill()
        }
        let requests = [EventHistoryRequest(mask: ["key": "value", "numeric": 552], from: mockOldestDate, to: mockNewestDate)]
        
        // test
        eventHistory.getEvents(requests, enforceOrder: true, handler: handler)
        wait(for: [expectation], timeout: 1)
        
        // verify
        XCTAssertEqual(expectedHash, mockEventHistoryDatabase.paramHash)
        XCTAssertEqual(mockOldestDate, mockEventHistoryDatabase.paramFrom)
        XCTAssertEqual(mockNewestDate, mockEventHistoryDatabase.paramTo)
    }
    
    func testGetEventsDoNotEnforceOrder() throws {
        // setup
        let expectation = XCTestExpectation(description: "handler called")
        let mockCount = 552
        let mockOldestDate = Date(milliseconds: 12345)
        let mockNewestDate = Date(milliseconds: 23456)
        mockEventHistoryDatabase.returnSelect = EventHistoryResult(count: mockCount, oldest: mockOldestDate, newest: mockNewestDate)
        let handler: ([EventHistoryResult]) -> Void = { results in
            XCTAssertNotNil(results)
            XCTAssertEqual(1, results.count)
            XCTAssertEqual(mockCount, results.first?.count)
            XCTAssertEqual(mockOldestDate, results.first?.oldestOccurrence)
            XCTAssertEqual(mockNewestDate, results.first?.newestOccurrence)
            expectation.fulfill()
        }
        let requests = [EventHistoryRequest(mask: ["key": "value", "numeric": 552], from: mockOldestDate, to: mockNewestDate)]
        
        // test
        eventHistory.getEvents(requests, enforceOrder: false, handler: handler)
        wait(for: [expectation], timeout: 1)
        
        // verify
        XCTAssertEqual(expectedHash, mockEventHistoryDatabase.paramHash)
        XCTAssertEqual(mockOldestDate, mockEventHistoryDatabase.paramFrom)
        XCTAssertEqual(mockNewestDate, mockEventHistoryDatabase.paramTo)
    }
    
    func testDeleteEvents() throws {
        // setup
        let expectation = XCTestExpectation(description: "handler called")
        mockEventHistoryDatabase.returnDelete = 234
        let handler: (Int) -> Void = { result in
            XCTAssertEqual(234, result)
            expectation.fulfill()
        }
        let mockOldestDate = Date(milliseconds: 12345)
        let mockNewestDate = Date(milliseconds: 23456)
        let requests = [EventHistoryRequest(mask: ["key": "value", "numeric": 552], from: mockOldestDate, to: mockNewestDate)]
        
        // test
        eventHistory.deleteEvents(requests, handler: handler)
        wait(for: [expectation], timeout: 1)
        
        // verify
        XCTAssertEqual(expectedHash, mockEventHistoryDatabase.paramHash)
        XCTAssertEqual(mockOldestDate, mockEventHistoryDatabase.paramFrom)
        XCTAssertEqual(mockNewestDate, mockEventHistoryDatabase.paramTo)
    }
    
    func testDeleteEventsNoHandler() throws {
        // setup
        let expectation = XCTestExpectation(description: "handler called")
        expectation.isInverted = true
        mockEventHistoryDatabase.returnDelete = 234
        let mockOldestDate = Date(milliseconds: 12345)
        let mockNewestDate = Date(milliseconds: 23456)
        let requests = [EventHistoryRequest(mask: ["key": "value", "numeric": 552], from: mockOldestDate, to: mockNewestDate)]
        
        // test
        eventHistory.deleteEvents(requests)
        wait(for: [expectation], timeout: 1)
        
        // verify
        XCTAssertEqual(expectedHash, mockEventHistoryDatabase.paramHash)
        XCTAssertEqual(mockOldestDate, mockEventHistoryDatabase.paramFrom)
        XCTAssertEqual(mockNewestDate, mockEventHistoryDatabase.paramTo)
    }
}
