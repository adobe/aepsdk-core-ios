/*
 Copyright 2020 Adobe. All rights reserved.
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

class EventDataFlattenerTests: XCTestCase {
    // MARK: - Dictionary root tests
    func testFlatDictionaryRemainsUnchanged() {
        let actual: [String: Any] = [
            "a": 1,
            "b": true
        ]
        let expected: [String: Any] = [
            "a": 1,
            "b": true
        ]
        XCTAssertEqualDictionaries(expected, actual.flattening())
    }

    func testDictionaryWithPrimitives() {
        let actual: [String: Any] = [
            "int": 1,
            "bool": false,
            "double": 1.23,
            "string": "a",
            "null": NSNull()
        ]
        let expected: [String: Any] = [
            "int": 1,
            "bool": false,
            "double": 1.23,
            "string": "a",
            "null": NSNull()
        ]
        XCTAssertEqualDictionaries(expected, actual.flattening())
    }

    func testNestedDictionaryIsFlattened() {
        let actual: [String: Any] = [
            "a": [
                "b": [
                    "c": 42
                ]
            ]
        ]
        let expected: [String: Any] = ["a.b.c": 42]
        XCTAssertEqualDictionaries(expected, actual.flattening())
    }

    func testDictionaryWithArrayOfPrimitives() {
        let actual: [String: Any] = ["nums": [1, true, 1.23, "a", NSNull()]]
        let expected: [String: Any] = [
            "nums.0": 1,
            "nums.1": true,
            "nums.2": 1.23,
            "nums.3": "a",
            "nums.4": NSNull()
        ]
        XCTAssertEqualDictionaries(expected, actual.flattening())
    }

    func testDictionaryWithArrayOfDictionaries() {
        let actual: [String: Any] = [
            "arr": [
                ["x": 1],
                ["y": 2]
            ]
        ]
        let expected: [String: Any] = [
            "arr.0.x": 1,
            "arr.1.y": 2
        ]
        XCTAssertEqualDictionaries(expected, actual.flattening())
    }

    func testMixedNestedStructures() {
        let actual: [String: Any] = [
            "dict": [
                "arr": [
                    ["dict0": 0],
                    [
                        "dict1": 1,
                        "innerArr": ["a", "b"]
                    ]
                ],
                "bool": false
            ]
        ]
        let expected: [String: Any] = [
            "dict.arr.0.dict0": 0,
            "dict.arr.1.dict1": 1,
            "dict.arr.1.innerArr.0": "a",
            "dict.arr.1.innerArr.1": "b",
            "dict.bool": false
        ]
        XCTAssertEqualDictionaries(expected, actual.flattening())
    }

    func testDictionaryNumericalKeys() {
        let actual: [String: Any] = [
            "0": [0],
            "arr": [1]
        ]

        let expected: [String: Any] = [
            "0.0": 0,
            "arr.0": 1
        ]
        XCTAssertEqualDictionaries(expected, actual.flattening())
    }

    func testDictionaryWithDotInKeyIsNotEscaped() {
        let actual: [String: Any] = [
            "a.b": ["c": 1],
            "a": ["b": 2]
        ]
        let flattenedDictionary = actual.flattening()

        // Two distinct flattened paths must exist
        XCTAssertEqual(flattenedDictionary["a.b.c"] as? Int, 1)
        XCTAssertEqual(flattenedDictionary["a.b"] as? Int, 2)
        XCTAssertEqual(flattenedDictionary.count, 2)
    }

    func testSameKeyPathFromDifferentShapes() {
        let dottedKey: [String: Any] = ["a.b": 1]
        let nestedKey: [String: Any] = ["a": ["b": 1]]

        XCTAssertEqualDictionaries(dottedKey.flattening(), nestedKey.flattening())
    }

    func testEmptyDictionaryReturnsEmpty() {
        let actual: [String: Any] = [:]
        XCTAssertTrue(actual.flattening().isEmpty)
    }

    // MARK: - Array root tests
    func testArrayRootOfPrimitives() {
        let input: [Any] = [10, "a", true, 1.23, NSNull()]
        let expected: [String: Any] = [
            "0": 10,
            "1": "a",
            "2": true,
            "3": 1.23,
            "4": NSNull()
        ]
        XCTAssertEqualDictionaries(expected, input.flattening())
    }

    func testArrayRootOfMixedObjects() {
        let input: [Any] = [
            ["a": 1],
            ["b": [2, 3]]
        ]
        let expected: [String: Any] = [
            "0.a": 1,
            "1.b.0": 2,
            "1.b.1": 3
        ]
        XCTAssertEqualDictionaries(expected, input.flattening())
    }

    func testNestedArrayInArray() {
        let input: [Any] = [
            [
                ["x": "y"]
            ]
        ]
        let expected = ["0.0.x": "y"] as [String: Any]
        XCTAssertEqualDictionaries(expected, input.flattening())
    }

    func testEmptyArrayReturnsEmpty() {
        let input: [Any] = []
        XCTAssertTrue(input.flattening().isEmpty)
    }

    func testKeyCollisionForArrayAndDictionaryKeys() {
        let valueArr: [String: Any] = [
            "a": [
                [ // Array value
                    "b": [
                        "c": "d"
                    ]
                ]
            ]
        ]
        let valueDict: [String: Any] = [
            "a": [
                "0": [ // Dictionary key using int value that is a valid array index
                    "b": [
                        "c": "d"
                    ]
                ]
            ]
        ]
        XCTAssertEqualDictionaries(valueArr.flattening(), valueDict.flattening())
    }

    private func XCTAssertEqualDictionaries(
        _ expression1: [String: Any],
        _ expression2: [String: Any],
        file: StaticString = #file,
        line: UInt = #line)
    {
        let dict1 = NSDictionary(dictionary: expression1)
        let dict2 = NSDictionary(dictionary: expression2)
        XCTAssertTrue(dict1.isEqual(to: dict2 as! [AnyHashable: Any]), file: file, line: line)
    }
}
