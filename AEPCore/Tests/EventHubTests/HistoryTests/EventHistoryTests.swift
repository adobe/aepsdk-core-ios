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
        mockEventHistoryDatabase = MockEventHistoryDatabase()
        eventHistory = EventHistory(storage: mockEventHistoryDatabase)
        
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

    func testGetEvents_MultipleRequests_EnforceOrder_UsesPreviousOldest() {
        // Given
        let expectation = expectation(description: "handler")

        // Two queued results; the first result's `oldestOccurrence` should be used
        // as the `from` date for the second request in enforce-order mode.
        let oldest1 = Date(timeIntervalSince1970: 100)
        let oldest2 = Date(timeIntervalSince1970: 200)
        let result1 = EventHistoryResult(count: 1, oldest: oldest1, newest: nil)
        let result2 = EventHistoryResult(count: 1, oldest: oldest2, newest: nil)
        mockEventHistoryDatabase.returnSelectResultsQueue = [result1, result2]

        // Original from/to dates.
        // In enforce-order mode, the second request's `from` should be overridden by `oldest1`.
        let from1 = Date(timeIntervalSince1970: 1)
        let to1 = Date(timeIntervalSince1970: 2)
        let from2 = Date(timeIntervalSince1970: 3)
        let to2 = Date(timeIntervalSince1970: 4)

        // Requests
        let request1 = EventHistoryRequest(mask: ["a": 1], from: from1, to: to1)
        let request2 = EventHistoryRequest(mask: ["b": 2], from: from2, to: to2)
        let requests = [request1, request2]

        // When
        eventHistory.getEvents(requests, enforceOrder: true) { results in
            // Then
            // Result array matches database order
            XCTAssertEqual([result1, result2], results)
            // Exactly one select per request, in order
            let expectedHashes = [request1.mask.fnv1a32(), request2.mask.fnv1a32()]
            XCTAssertEqual(expectedHashes, self.mockEventHistoryDatabase.paramHashesList)
            // `from` for second call is previous event's `oldestOccurrence` Date
            XCTAssertEqual([from1, oldest1], self.mockEventHistoryDatabase.paramFromList)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
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

    func testGetEvents_MultipleRequests_NoOrder_ReturnsResultsInSameOrder() {
        // Given two distinct queued results
        let expectedResults = [
            EventHistoryResult(count: 1, oldest: nil, newest: nil),
            EventHistoryResult(count: 1, oldest: nil, newest: nil)
        ]
        mockEventHistoryDatabase.returnSelectResultsQueue = expectedResults

        let request1 = EventHistoryRequest(mask: ["a":1], from: nil, to: nil)
        let request2 = EventHistoryRequest(mask: ["b":2], from: nil, to: nil)

        let expectation = expectation(description: "handler")

        // When
        eventHistory.getEvents([request1, request2], enforceOrder: false) { results in
            // Then
            // Should return one result per request, in the same order as the requests.
            XCTAssertEqual(expectedResults, results)
            // Should invoke select once per request, in the correct order.
            let expectedHashes = [request1.mask.fnv1a32(), request2.mask.fnv1a32()]
            XCTAssertEqual(expectedHashes, self.mockEventHistoryDatabase.paramHashesList)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
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
