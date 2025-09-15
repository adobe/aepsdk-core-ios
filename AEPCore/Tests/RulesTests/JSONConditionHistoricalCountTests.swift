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

final class JSONConditionHistoricalCountTests: XCTestCase {
    private var condition: JSONCondition!
    private var mockRuntime: TestableExtensionRuntime!
    private var requests: [EventHistoryRequest]!

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
        requests = [EventHistoryRequest(mask: [:], from: nil, to: nil)]
    }

    // MARK: - Parameter-validation tests
    func testGetHistoricalEventCount_returnsZero_whenParametersNil() {
        XCTAssertEqual(0, condition.getHistoricalEventCount(parameters: nil))
    }

    func testGetHistoricalEventCount_returnsZero_whenTooFewParameters() {
        XCTAssertEqual(0, condition.getHistoricalEventCount(parameters: [mockRuntime!]))
        XCTAssertEqual(0, condition.getHistoricalEventCount(parameters: [requests!]))
    }

    func testGetHistoricalEventCount_returnsZero_onTypeMismatch() {
        let badParams: [Any] = [123, "bad", Date()]
        XCTAssertEqual(0, condition.getHistoricalEventCount(parameters: badParams))
    }

    // MARK: - Unsupported search-type guard
    func testGetHistoricalEventCount_returnsMinusOne_whenSearchTypeMostRecent() {
        let params: [Any] = [mockRuntime!, requests!, EventHistorySearchType.mostRecent]
        XCTAssertEqual(-1, condition.getHistoricalEventCount(parameters: params))
    }

    // MARK: - .any searchType
    func testGetHistoricalEventCount_any_returnsMinusOne_onDatabaseError() {
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: -1, oldest: nil, newest: nil)
        ]
        let params: [Any] = [mockRuntime!, requests!, EventHistorySearchType.any]
        XCTAssertEqual(-1, condition.getHistoricalEventCount(parameters: params))
    }

    func testGetHistoricalEventCount_any_accumulatesCounts() {
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 2, oldest: nil, newest: nil),
            EventHistoryResult(count: 3, oldest: nil, newest: nil)
        ]
        let params: [Any] = [mockRuntime!, requests!, EventHistorySearchType.any]
        XCTAssertEqual(5, condition.getHistoricalEventCount(parameters: params))
    }

    // MARK: - .ordered searchType
    func testGetHistoricalEventCount_ordered_returnsMinusOne_onDatabaseError() {
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: -1, oldest: nil, newest: nil)
        ]
        let params: [Any] = [mockRuntime!, requests!, EventHistorySearchType.ordered]
        XCTAssertEqual(-1, condition.getHistoricalEventCount(parameters: params))
    }

    func testGetHistoricalEventCount_ordered_returnsZero_whenAnyEventMissing() {
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 1, oldest: nil, newest: nil),
            EventHistoryResult(count: 0, oldest: nil, newest: nil)
        ]
        let params: [Any] = [mockRuntime!, requests!, EventHistorySearchType.ordered]
        XCTAssertEqual(0, condition.getHistoricalEventCount(parameters: params))
    }

    func testGetHistoricalEventCount_ordered_returnsOne_whenAllEventsPresent() {
        mockRuntime.mockEventHistoryResults = [
            EventHistoryResult(count: 5, oldest: nil, newest: nil),
            EventHistoryResult(count: 2, oldest: nil, newest: nil)
        ]
        let params: [Any] = [mockRuntime!, requests!, EventHistorySearchType.ordered]
        XCTAssertEqual(1, condition.getHistoricalEventCount(parameters: params))
    }
}
