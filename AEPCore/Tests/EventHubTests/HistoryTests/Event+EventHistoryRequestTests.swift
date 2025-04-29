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

    func testToEventHistoryRequest_dataNotNilAndMaskNil_returnsAllDataWithFlattenedKeys() {
        let data: [String: Any] = [
            "stringKey": "value",
            "intKey": 42,
            "doubleKey": 3.14,
            "boolKey": true,
            "nullKey": NSNull(),
            "arrayKey": ["stringInArray", 123, 4.56, false, NSNull()],
            "dictionaryKey": [
                "nestedString": "nestedValue",
                "nestedInt": 100,
                "nestedDouble": 9.81,
                "nestedBool": false,
                "nestedNull": NSNull()
            ]
        ]
        let event = Event(name: "test", type: "type", source: "source", data: data, mask: nil)

        let request = event.toEventHistoryRequest()

        // 6 top-level keys + 5 flattened inner dictionary keys
        XCTAssertEqual(11, request.mask.count)

        // Primitive top-level types
        XCTAssertEqual("value", request.mask["stringKey"] as? String)
        XCTAssertEqual(42, request.mask["intKey"] as? Int)
        XCTAssertEqual(3.14, request.mask["doubleKey"] as? Double)
        XCTAssertEqual(true, request.mask["boolKey"] as? Bool)

        // Null at top level
        XCTAssertEqual(NSNull(), request.mask["nullKey"] as? NSNull)

        // Array
        let arrayValue = request.mask["arrayKey"] as? [Any]
        XCTAssertNotNil(arrayValue)
        XCTAssertEqual(5, arrayValue?.count)
        XCTAssertEqual("stringInArray", arrayValue?[0] as? String)
        XCTAssertEqual(123, arrayValue?[1] as? Int)
        XCTAssertEqual(4.56, arrayValue?[2] as? Double)
        XCTAssertEqual(false, arrayValue?[3] as? Bool)
        XCTAssertTrue(arrayValue?[4] is NSNull)

        // Flattened nested dictionary keys
        XCTAssertEqual("nestedValue", request.mask["dictionaryKey.nestedString"] as? String)
        XCTAssertEqual(100, request.mask["dictionaryKey.nestedInt"] as? Int)
        XCTAssertEqual(9.81, request.mask["dictionaryKey.nestedDouble"] as? Double)
        XCTAssertEqual(false, request.mask["dictionaryKey.nestedBool"] as? Bool)
        XCTAssertEqual(NSNull(), request.mask["dictionaryKey.nestedNull"] as? NSNull)
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
            "drop": "no",
            "dictionaryKey": [
                "dropNestedString": "nestedValue",
                "keepNestedInt": 100,
            ]
        ]
        let event = Event(name: "test", type: "type", source: "source", data: data, mask: ["keep", "dictionaryKey.keepNestedInt"])

        let request = event.toEventHistoryRequest()

        XCTAssertEqual(2, request.mask.count)
        XCTAssertEqual("yes", request.mask["keep"] as? String)
        XCTAssertEqual(100, request.mask["dictionaryKey.keepNestedInt"] as? Int)
        XCTAssertNil(request.mask["drop"])
        XCTAssertNil(request.mask["dictionaryKey.dropNestedString"])
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
