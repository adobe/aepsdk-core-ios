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
import AEPServices
@testable import AEPServicesMocks

class XCTestCase_JSONAssertsTests: XCTestCase {

    // MARK: - assertValueSubset (aka assertExactMatch)

    func testAssertValueSubset_PassesForExactSubset() {
        let expected = ["key": "value"]
        let actual = ["key": "value", "extra": "data"]
        
        // Should pass (no failure raised)
        assertExactMatch(expected: expected, actual: actual)
    }
    
    func testAssertValueSubset_FailsForValueMismatch() {
        let expected = ["key": "value"]
        let actual = ["key": "wrong"]
        
        XCTExpectFailure("Values mismatch should cause failure") {
            assertExactMatch(expected: expected, actual: actual)
        }
    }

    // MARK: - assertTypeSubset (aka assertTypeMatch)

    func testAssertTypeSubset_PassesForTypeMatch() {
        let expected = ["id": 123] // Int
        let actual: [String: Any] = ["id": 456, "extra": "data"] // Different Int value
        
        // Should pass because values are different but types match
        // If this used exact match default, it would fail
        assertTypeMatch(expected: expected, actual: actual)
    }
    
    func testAssertTypeSubset_PassesForStructureMatch() {
        let expected = ["list": [1]]
        let actual = ["list": [10, 20]]
        
        // Should pass: Array contains Ints
        assertTypeMatch(expected: expected, actual: actual)
    }
    
    func testAssertTypeSubset_FailsForTypeMismatch() {
        let expected = ["id": 123] // Int
        let actual = ["id": "string"] // String
        
        XCTExpectFailure("Type mismatch should cause failure") {
            assertTypeMatch(expected: expected, actual: actual)
        }
    }

    // MARK: - assertEqual (Deprecated Strict Equality)

    func testAssertEqual_PassesForStrictEquality() {
        let json = ["key": "value"]
        
        // Should pass
        assertEqual(expected: json, actual: json)
    }
    
    func testAssertEqual_FailsForSubset() {
        let expected = ["key": "value"]
        let actual = ["key": "value", "extra": "data"]
        
        XCTExpectFailure("Strict equality should fail if actual has extra keys (equalCount enforced)") {
            assertEqual(expected: expected, actual: actual)
        }
    }
}
