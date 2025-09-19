/*
 Copyright 2025 Adobe. All rights reserved.
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

final class JSONConditionMostRecentTests: XCTestCase {
    var condition: JSONCondition!
    var mockRuntime: TestableExtensionRuntime!
    var requests: [EventHistoryRequest]!

    override func setUp() {
        super.setUp()
        let json = """
        {
          "type": "historical",
          "definition": {}
        }
        """.data(using: .utf8)!
        condition = try! JSONDecoder().decode(JSONCondition.self, from: json)
        mockRuntime = TestableExtensionRuntime()
        // Note: These tests only verify that request parameters are constructed and passed correctly;
        // the actual behavior of EventHistoryRequest -> EventHistoryResult via EventHistory.getEvents
        // is already covered in EventHistoryTests.
        requests = [EventHistoryRequest(mask: [:], from: nil, to: nil)]
    }

    func testGetMostRecentHistoricalEvent_returnsMinusOne_whenParametersNil() {
        // When: No parameters are passed
        let result = condition.getMostRecentHistoricalEvent(parameters: nil)

        // Then: Return -1 for invalid input
        XCTAssertEqual(-1, result)
    }

    func testGetMostRecentHistoricalEvent_returnsMinusOne_whenTooFewParameters() {
        // When: Missing either the runtime or requests
        XCTAssertEqual(-1, condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!]))
        XCTAssertEqual(-1, condition.getMostRecentHistoricalEvent(parameters: requests!))
    }

    func testGetMostRecentHistoricalEvent_returnsMinusOne_onTypeMismatch() {
        // When: Parameters are the wrong types
        let badParams: [Any] = [123, "not a runtime"]

        // Then: Return -1
        XCTAssertEqual(-1, condition.getMostRecentHistoricalEvent(parameters: badParams))
    }

    func testGetMostRecentHistoricalEvent_returnsMinusOne_onDatabaseError() {
        // Given: A database error (count == -1)
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: -1, oldest: nil, newest: nil)
        ]

        // When
        let result = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, requests!])

        // Then: Return -1 on database error
        XCTAssertEqual(-1, result)
    }

    func testGetMostRecentHistoricalEvent_returnsMinusOne_whenEmptyRequests() {
        // When: No requests are provided
        let result = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, []])

        // Then: Return -1
        XCTAssertEqual(-1, result)
    }

    func testGetMostRecentHistoricalEvent_returnsMinusOne_whenNoOccurrences() {
        // Given: All results are missing `newestOccurrence`
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 0, oldest: nil, newest: nil),
            EventHistoryResult(count: 1, oldest: nil, newest: nil)
        ]

        // When
        let result = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, requests!])

        // Then: Return -1 when no usable dates
        XCTAssertEqual(-1, result)
    }

    func testGetMostRecentHistoricalEvent_returnsZero_forSingleEvent() {
        // Given: A single result with a valid timestamp
        let now = Date()
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 1, oldest: nil, newest: now)
        ]

        // When
        let result = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, requests!])

        // Then: Return index 0
        XCTAssertEqual(0, result)
    }

    func testGetMostRecentHistoricalEvent_returnsIndexOfMostRecentEvent() {
        // Given: Two results, the second is newer
        let older = Date().addingTimeInterval(-1)
        let newer = Date()
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 1, oldest: nil, newest: older),
            EventHistoryResult(count: 1, oldest: nil, newest: newer)
        ]

        // When
        let result = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, requests!])

        // Then: Return index 1
        XCTAssertEqual(1, result)
    }

    func testGetMostRecentHistoricalEvent_picksByDate_whenLowerCount() {
        // Given: The newest date is not the one with the highest count
        let now = Date()
        let past1 = now.addingTimeInterval(-1)
        let past2 = now.addingTimeInterval(-2)
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 999, oldest: nil, newest: past1),
            EventHistoryResult(count: 1,   oldest: nil, newest: past2),
            EventHistoryResult(count: 10,  oldest: nil, newest: now)
        ]

        // When
        let index = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, requests!])

        // Then: Return index 2 based on newest date, not highest count
        XCTAssertEqual(2, index)
    }

    func testGetMostRecentHistoricalEvent_returnsCorrectIndex_whenOutOfOrder() {
        // Given: Three results, newest is in the middle
        let oldest = Date().addingTimeInterval(-2)
        let middle = Date().addingTimeInterval(-1)
        let newest = Date()
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 1, oldest: nil, newest: oldest),
            EventHistoryResult(count: 1, oldest: nil, newest: newest),
            EventHistoryResult(count: 1, oldest: nil, newest: middle)
        ]

        // When
        let index = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, requests!])

        // Then: Return index 1
        XCTAssertEqual(1, index)
    }

    func testGetMostRecentHistoricalEvent_returnsFirstIndex_whenDuplicateTimestamps() {
        // Given: Two identical timestamps
        let date = Date()
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 1, oldest: nil, newest: date),
            EventHistoryResult(count: 1, oldest: nil, newest: date)
        ]

        let request = EventHistoryRequest(mask: [:], from: nil, to: nil)

        // When
        let result = condition.getMostRecentHistoricalEvent(parameters: [mockRuntime!, [request, request]])

        // Then: Return the first match (index 0)
        XCTAssertEqual(0, result)
    }
}
