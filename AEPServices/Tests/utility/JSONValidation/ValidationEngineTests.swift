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

class ValidationEngineTests: XCTestCase {

    // MARK: - Primitive Tests

    /// Exact match succeeds when expected and actual primitives are equal.
    func testValidate_Primitives_ExactMatch() {
        // Given
        let config = NodeConfig(defaults: .init(exactMatch: true))

        // When
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable("test"), config: config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// Exact match fails when expected and actual primitives differ.
    func testValidate_Primitives_Mismatch() {
        // Given
        let config = NodeConfig(defaults: .init(exactMatch: true))

        // When
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable("fail"), config: config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.failures.first?.message, "Values do not match.")
    }

    /// Type match succeeds when primitives have the same type (even if values differ).
    func testValidate_Primitives_TypeMatch() {
        // Given
        let config = NodeConfig(defaults: .init(exactMatch: false))

        // When
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable("other"), config: config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// Type match fails when primitives have different types.
    func testValidate_Primitives_TypeMismatch() {
        // Given
        let config = NodeConfig(defaults: .init(exactMatch: false))

        // When
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable(123), config: config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("types do not match") ?? false)
    }

    // MARK: - Dictionary Tests

    /// Dictionary input works when both sides are represented as `[String: Any?]`.
    func testValidate_Dictionary_Input_StringAnyOptional() {
        // Given
        let expectedDict: [String: Any?] = ["a": 1, "b": nil]
        let actualDict: [String: Any?] = ["a": 1, "b": nil, "extra": 123]

        // When
        let result = ValidationEngine.validate(
            expected: AnyCodable(expectedDict),
            actual: AnyCodable(actualDict),
            config: NodeConfig()
        )

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// Dictionary input works when both sides are represented as `[String: AnyCodable]`.
    func testValidate_Dictionary_Input_StringAnyCodable() {
        // Given
        let expectedDict: [String: AnyCodable] = ["a": AnyCodable(1), "b": AnyCodable(nil)]
        let actualDict: [String: AnyCodable] = ["a": AnyCodable(1), "b": AnyCodable(nil), "extra": AnyCodable(123)]

        // When
        let result = ValidationEngine.validate(
            expected: AnyCodable(expectedDict),
            actual: AnyCodable(actualDict),
            config: NodeConfig()
        )

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// Dictionary input works when expected/actual dictionary representations differ (`[String: Any?]` vs `[String: AnyCodable]`).
    func testValidate_Dictionary_Input_MismatchedRepresentations_Passes() {
        // Given
        let expectedDict: [String: Any?] = ["a": 1]
        let actualDict: [String: AnyCodable] = ["a": AnyCodable(1)]

        // When
        let result = ValidationEngine.validate(
            expected: AnyCodable(expectedDict),
            actual: AnyCodable(actualDict),
            config: NodeConfig()
        )

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// By default, expected dictionaries are treated as a subset of actual (actual may contain extra keys).
    func testValidate_Dictionary_Subset() {
        // Given
        let expected = AnyCodable(["a": 1])
        let actual = AnyCodable(["a": 1, "b": 2])
        let config = NodeConfig() // Defaults: extensible (equalCount: false)

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// When `equalCount` is enabled, extra keys in actual cause validation to fail.
    func testValidate_Dictionary_EqualCount_Fail() {
        // Given
        let expected = AnyCodable(["a": 1])
        let actual = AnyCodable(["a": 1, "b": 2])
        var config = NodeConfig()
        config.equalCount = true

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("count does not match") ?? false)
    }

    /// Missing keys in actual fail at the missing key's path.
    func testValidate_Dictionary_MissingKey() {
        // Given
        let expected = AnyCodable(["a": 1, "c": 3])
        let actual = AnyCodable(["a": 1, "b": 2])

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: NodeConfig())

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.contains { $0.keyPath == "c" })
        XCTAssertTrue(result.failures.contains { $0.message.contains("Actual JSON is nil") })
    }

    // MARK: - Array Tests

    /// Array input works when both sides are represented as `[Any?]`.
    func testValidate_Array_Input_AnyOptional() {
        // Given
        let expectedArray: [Any?] = [1, nil, "a"]
        let actualArray: [Any?] = [1, nil, "a", "extra"]

        // When
        let result = ValidationEngine.validate(
            expected: AnyCodable(expectedArray),
            actual: AnyCodable(actualArray),
            config: NodeConfig()
        )

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// Array input works when both sides are represented as `[AnyCodable]`.
    func testValidate_Array_Input_AnyCodable() {
        // Given
        let expectedArray: [AnyCodable] = [AnyCodable(1), AnyCodable(nil), AnyCodable("a")]
        let actualArray: [AnyCodable] = [AnyCodable(1), AnyCodable(nil), AnyCodable("a"), AnyCodable("extra")]

        // When
        let result = ValidationEngine.validate(
            expected: AnyCodable(expectedArray),
            actual: AnyCodable(actualArray),
            config: NodeConfig()
        )

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// Array input works when expected/actual array representations differ (`[Any?]` vs `[AnyCodable]`).
    func testValidate_Array_Input_MismatchedRepresentations_Passes() {
        // Given
        let expectedArray: [Any?] = [1]
        let actualArray: [AnyCodable] = [AnyCodable(1)]

        // When
        let result = ValidationEngine.validate(
            expected: AnyCodable(expectedArray),
            actual: AnyCodable(actualArray),
            config: NodeConfig()
        )

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// By default, expected arrays are treated as a prefix of actual (actual may contain extra elements).
    func testValidate_Array_Ordered_Pass() {
        // Given
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([1, 2, 3]) // Extensible by default

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: NodeConfig())

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// Without `anyOrder`, arrays are compared positionally.
    func testValidate_Array_Ordered_FailOrder() {
        // Given
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([2, 1])

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: NodeConfig())

        // Then
        XCTAssertFalse(result.isValid)
    }

    /// Setting `anyOrder` on the parent node does not propagate to child indices.
    func testValidate_Array_AnyOrder_OnParent_DoesNotAffectElements() {
        // Given
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([2, 1])
        var config = NodeConfig()
        config.anyOrder = true

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.contains { $0.keyPath == "[0]" && $0.message == "Values do not match." })
        XCTAssertFalse(result.failures.contains { $0.message.contains("Any order") })
    }

    /// With `anyOrder`, expected elements can match any position in actual.
    func testValidate_Array_AnyOrder_Pass() {
        // Given
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([2, 1, 3])
        let config = NodeConfig(defaults: .init(anyOrder: true))

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    /// With `anyOrder`, validation fails if an expected element cannot be matched.
    func testValidate_Array_AnyOrder_FailMissing() {
        // Given
        let expected = AnyCodable([1, 2, 99])
        let actual = AnyCodable([2, 1, 3])
        let config = NodeConfig(defaults: .init(anyOrder: true))

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.contains { $0.message.contains("found no matches") })
    }

    /// `anyOrder` can be enabled per-index to mix fixed and flexible element matching.
    func testValidate_Array_MixedOrder() {
        // Given
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([1, 99, 2])

        var config = NodeConfig()
        var index1 = NodeConfig(name: "1")
        index1.anyOrder = true
        config.children["1"] = index1

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Special Constraints

    /// `keyMustBeAbsent` fails when the configured key exists in the actual JSON.
    func testValidate_KeyMustBeAbsent() {
        // Given
        let actual = AnyCodable(["a": 1, "b": 2])
        var config = NodeConfig()
        var nodeB = NodeConfig(name: "b")
        nodeB.keyMustBeAbsent = true
        config.children["b"] = nodeB

        // When
        let result = ValidationEngine.validate(expected: nil, actual: actual, config: config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("must not have key") ?? false)
    }

    /// `valueNotEqual` fails when expected and actual are equal.
    func testValidate_ValueNotEqual() {
        // Given
        let expected = AnyCodable("oldValue")
        let actual = AnyCodable("oldValue")
        var config = NodeConfig()
        config.valueNotEqual = true

        // When
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("Values must NOT be equal") ?? false)
    }
}

