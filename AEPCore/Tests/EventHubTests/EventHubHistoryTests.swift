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

class EventHubHistoryTests: XCTestCase {
    var eventHub: EventHub!

    override func setUp() {
        super.setUp()
        eventHub = EventHub()
        // Start each test with no history
        EventHub.shared.eventHistory = nil
    }

    func testGetHistoricalEvents_whenHistoryIsNil_callsHandlerWithEmpty() {
        let expectation = XCTestExpectation(description: "handler should be called even when history is nil")
        EventHub.shared.getHistoricalEvents([], enforceOrder: false) { results in
            XCTAssertTrue(results.isEmpty, "Expected an empty array when eventHistory is nil")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testGetHistoricalEvents_withSpy_delegatesToEventHistory() {
        let spy = EventHistorySpy()

        let stubbedResult = EventHistoryResult(count: 42,
                                             oldest: Date(timeIntervalSince1970: 1),
                                             newest: Date(timeIntervalSince1970: 2))
        spy.stubbedResults = [stubbedResult]

        EventHub.shared.eventHistory = spy

        let req = EventHistoryRequest(mask: ["a": "b"], from: Date(), to: Date())
        let expectation = XCTestExpectation(description: "handler called with spy results")

        EventHub.shared.getHistoricalEvents([req], enforceOrder: true) { results in
            XCTAssertTrue(spy.didCallGetEvents, "Expected EventHub to call through to eventHistory.getEvents")
            XCTAssertEqual([req], spy.receivedRequests, "Expected the same request array to be forwarded")
            XCTAssertEqual(true, spy.receivedEnforceOrder, "Expected the enforceOrder flag to be forwarded")
            XCTAssertEqual(spy.stubbedResults, results, "Expected the handler to receive spy.stubbedResults")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testRecordHistoricalEvent_whenHistoryIsNil_callsHandlerWithFalse() {
        let testEvent = Event(name: "x", type: "y", source: "z", data: nil, mask: nil)
        let expectation = XCTestExpectation(description: "handler should be called with false when history is nil")
        var callbackValue: Bool?

        EventHub.shared.recordHistoricalEvent(testEvent) { success in
            callbackValue = success
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(false, callbackValue, "Expected recordHistoricalEvent to callback false when history is nil")
    }

    func testRecordHistoricalEvent_withSpy_delegatesToEventHistory() {
        let spy = EventHistorySpy()
        EventHub.shared.eventHistory = spy

        let testEvent = Event(name: "x", type: "y", source: "z", data: nil, mask: nil)
        let expectation = XCTestExpectation(description: "handler should be called with true from spy")
        var callbackValue: Bool?

        EventHub.shared.recordHistoricalEvent(testEvent) { success in
            callbackValue = success
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(spy.didCallRecordEvent, "Expected EventHub to call through to eventHistory.recordEvent")
        XCTAssertEqual(testEvent, spy.recordedEvent, "Expected the same Event to be forwarded")
        XCTAssertEqual(true, callbackValue, "Expected handler to receive true from spy")
    }

}
