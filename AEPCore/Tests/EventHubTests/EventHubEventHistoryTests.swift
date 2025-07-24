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

@testable import AEPCore
@testable import AEPCoreMocks

class EventHubEventHistoryTests: XCTestCase {
    var eventHub: EventHub!
    var mockEventHistory: MockEventHistory!

    override func setUp() {
        super.setUp()
        mockEventHistory = MockEventHistory()
        eventHub = EventHub(eventHistory: mockEventHistory)
    }

    func testGetHistoricalEvents_whenHistoryIsNil_callsHandlerWithEmpty() {
        let expectation = XCTestExpectation(description: "handler should be called even when history is nil")
        eventHub.getHistoricalEvents([], enforceOrder: false) { results in
            XCTAssertTrue(results.isEmpty, "Expected an empty array when eventHistory is nil")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testGetHistoricalEvents_delegatesToEventHistory() {
        let mockResult = EventHistoryResult(count: 42,
                                             oldest: Date(timeIntervalSince1970: 1),
                                             newest: Date(timeIntervalSince1970: 2))
        mockEventHistory.mockGetEventsResult = [mockResult]

        let req = EventHistoryRequest(mask: ["a": "b"], from: Date(), to: Date())
        let expectation = XCTestExpectation(description: "handler called with mock results")

        eventHub.getHistoricalEvents([req], enforceOrder: true) { results in
            XCTAssertTrue(self.mockEventHistory.didCallGetEvents, "Expected EventHub to call through to eventHistory.getEvents")
            XCTAssertEqual([req], self.mockEventHistory.receivedRequests, "Expected the same request array to be forwarded")
            XCTAssertEqual(true, self.mockEventHistory.receivedEnforceOrder, "Expected the enforceOrder flag to be forwarded")
            XCTAssertEqual(self.mockEventHistory.mockGetEventsResult, results, "Expected the handler to receive mock.mockGetEventsResult")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testRecordHistoricalEvent_whenHistoryIsNil_callsHandlerWithFalse() {
        eventHub = EventHub(eventHistory: nil)
        let testEvent = Event(name: "test", type: "type", source: "source", data: nil, mask: nil)
        let expectation = XCTestExpectation(description: "handler should be called with false when history is nil")
        var callbackValue: Bool?

        eventHub.recordHistoricalEvent(testEvent) { success in
            callbackValue = success
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(false, callbackValue, "Expected recordHistoricalEvent to callback false when history is nil")
    }

    func testRecordHistoricalEvent_delegatesToEventHistory() {
        let testEvent = Event(name: "test", type: "type", source: "source", data: nil, mask: nil)
        let expectation = XCTestExpectation(description: "handler should be called with true from mock")
        var callbackValue: Bool?

        eventHub.recordHistoricalEvent(testEvent) { success in
            callbackValue = success
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(mockEventHistory.didCallRecordEvent, "Expected EventHub to call through to eventHistory.recordEvent")
        XCTAssertEqual(testEvent, mockEventHistory.recordedEvent, "Expected the same Event to be forwarded")
        XCTAssertEqual(true, callbackValue, "Expected handler to receive true from mock")
    }
}
