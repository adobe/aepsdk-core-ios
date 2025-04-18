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

class Event_EventHistoryRequestTests: XCTestCase {
    func testToEventHistoryRequest_dataNilAndMaskNil_returnsEmptyMask() {
        let event = Event(name: "test", type: "type", source: "source", data: nil, mask: nil)

        let request = event.toEventHistoryRequest()

        XCTAssertTrue(request.mask.isEmpty)
        XCTAssertNil(request.fromDate)
        XCTAssertNil(request.toDate)
    }

    func testToEventHistoryRequest_dataNotNilAndMaskNil_returnsAllData() {
        let data: [String: Any] = [
            "stringKey": "value",
            "intKey": 42
        ]
        let event = Event(name: "test", type: "type", source: "source", data: data, mask: nil)

        let request = event.toEventHistoryRequest()

        XCTAssertEqual(request.mask.count, data.count)
        XCTAssertEqual(request.mask["stringKey"] as? String, "value")
        XCTAssertEqual(request.mask["intKey"] as? Int, 42)
    }

    func testToEventHistoryRequest_dataNotNilAndMaskEmpty_returnsEmptyMask() {
        let data: [String: Any] = [
            "a": 1,
            "b": 2
        ]
        let event = Event(name: "test", type: "type", source: "source", data: data, mask: [])

        let request = event.toEventHistoryRequest()

        XCTAssertTrue(request.mask.isEmpty)
    }

    func testToEventHistoryRequest_maskFiltersData() {
        let data: [String: Any] = [
            "keep": "yes",
            "drop": "no"
        ]
        let event = Event(name: "test", type: "type", source: "source", data: data, mask: ["keep"])

        let request = event.toEventHistoryRequest()

        XCTAssertEqual(request.mask.count, 1)
        XCTAssertEqual(request.mask["keep"] as? String, "yes")
        XCTAssertNil(request.mask["drop"])
    }

    func testToEventHistoryRequest_withFromAndTo_setsRange() {
        let fromDate = Date(timeIntervalSince1970: 0)
        let toDate = Date(timeIntervalSince1970: 1_000)

        let event = Event(name: "test", type: "type", source: "source", data: nil, mask: nil)

        let request = event.toEventHistoryRequest(from: fromDate, to: toDate)

        XCTAssertEqual(fromDate, request.fromDate)
        XCTAssertEqual(toDate, request.toDate)
    }
}

