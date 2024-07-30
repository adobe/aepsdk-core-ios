//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices
import Foundation
import XCTest

/// Represents the result of a validation process, including whether the validation was successful and the count of leaf nodes encountered.
///
/// `ValidationResult` is used by the `validateActual` recursive methods to return the outcome of their validation
/// and to track the number of leaf nodes encountered during a depth-first traversal.
struct ValidationResult {
    /// A Boolean value indicating whether the validation was successful.
    var isValid: Bool

    /// The total number of leaf nodes encountered up to this point in the hierarchy, during a depth-first traversal.
    var elementCount: Int
}

/// A protocol that enables conversion of conforming types into `AnyCodable` format.
public protocol AnyCodableComparable {
    /// Converts the conforming type to an optional `AnyCodable` instance.
    ///
    /// - Returns: An optional `AnyCodable` instance representing the conforming type, or `nil` if the conversion fails.
    func toAnyCodable() -> AnyCodable?
}


extension Optional where Wrapped: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        switch self {
        case .some(let value):
            return value.toAnyCodable()
        case .none:
            return nil
        }
    }
}

extension Dictionary: AnyCodableComparable where Key == String, Value: Any {
    public func toAnyCodable() -> AnyCodable? {
        // Convert self to [String: Any?] - this is a no-op for [String: Any] and
        // correctly wraps the value in an optional for [String: Any?]
        let optionalValueDict = self.mapValues { $0 as Any? }
        return AnyCodable(AnyCodable.from(dictionary: optionalValueDict))
    }
}

extension String: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AnyCodable.self, from: data)
    }
}

extension AnyCodable: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        return self
    }
}

extension NetworkRequest: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        guard let payloadAsDictionary = try? JSONSerialization.jsonObject(with: self.connectPayload, options: []) as? [String: Any] else {
            return nil
        }
        return payloadAsDictionary.toAnyCodable()
    }
}

public protocol AnyCodableAsserts {
    /// Asserts exact equality between two `AnyCodableComparable` instances.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertEqual(expected: AnyCodableComparable?, actual: AnyCodableComparable?, file: StaticString, line: UInt)

    /// Performs JSON validation where only the values from the `expected` JSON are required.
    /// By default, the comparison logic uses the value type match option, only validating that both values are of the same type.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString, line: UInt)

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value type match option, only validating that both values are of the same type.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: [MultiPathConfig], file: StaticString, line: UInt)

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value type match option, only validating that both values are of the same type.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: MultiPathConfig..., file: StaticString, line: UInt)

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value exact match option, validating that both values are of the same type
    /// **and** have the same literal value.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString, line: UInt)

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value exact match option, validating that both values are of the same type
    /// **and** have the same literal value.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: [MultiPathConfig], file: StaticString, line: UInt)

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value exact match option, validating that both values are of the same type
    /// **and** have the same literal value.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: MultiPathConfig..., file: StaticString, line: UInt)
}

public extension AnyCodableAsserts where Self: XCTestCase {
    /// Asserts exact equality between two `AnyCodableComparable` instances.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertEqual(expected: AnyCodableComparable?, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        if expected == nil && actual == nil {
            return
        }
        guard let expected = expected, let actual = actual else {
            XCTFail(
                """
                \(expected == nil ? "Expected is nil" : "Actual is nil") and \(expected == nil ? "Actual" : "Expected") is non-nil.
                Expected: \(String(describing: expected))
                Actual: \(String(describing: actual))
                """,
                file: file,
                line: line)
            return
        }
        // Exact equality is just a special case of exact match
        assertExactMatch(expected: expected, actual: actual, pathOptions: CollectionEqualCount(paths: nil, isActive: true, scope: .subtree), file: file, line: line)
    }

    /// Performs JSON validation where only the values from the `expected` JSON are required.
    /// By default, the comparison logic uses the value type match option, only validating that both values are of the same type.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        let treeDefaults: [MultiPathConfig] = [
            AnyOrderMatch(paths: nil, isActive: false),
            CollectionEqualCount(paths: nil, isActive: false),
            KeyMustBeAbsent(paths: nil, isActive: false),
            ValueTypeMatch(paths: nil)
        ]

        validate(
            expected: expected,
            actual: actual,
            pathOptions: [],
            treeDefaults: treeDefaults,
            file: file,
            line: line)
    }

    // MARK: Type match

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value type match option, only validating that both values are of the same type.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: [MultiPathConfig], file: StaticString = #file, line: UInt = #line) {
        let treeDefaults: [MultiPathConfig] = [
            AnyOrderMatch(paths: nil, isActive: false),
            CollectionEqualCount(paths: nil, isActive: false),
            KeyMustBeAbsent(paths: nil, isActive: false),
            ValueTypeMatch(paths: nil)
        ]

        validate(
            expected: expected,
            actual: actual,
            pathOptions: pathOptions,
            treeDefaults: treeDefaults,
            file: file,
            line: line)
    }

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value type match option, only validating that both values are of the same type.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: MultiPathConfig..., file: StaticString = #file, line: UInt = #line) {
        assertTypeMatch(expected: expected, actual: actual, pathOptions: pathOptions, file: file, line: line)
    }

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value exact match option, validating that both values are of the same type
    /// **and** have the same literal value.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        let treeDefaults: [MultiPathConfig] = [
            AnyOrderMatch(paths: nil, isActive: false),
            CollectionEqualCount(paths: nil, isActive: false),
            KeyMustBeAbsent(paths: nil, isActive: false),
            ValueExactMatch(paths: nil)
        ]
        validate(
            expected: expected,
            actual: actual,
            pathOptions: [],
            treeDefaults: treeDefaults,
            file: file,
            line: line)
    }

    // MARK: Exact match

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value exact match option, validating that both values are of the same type
    /// **and** have the same literal value.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: [MultiPathConfig], file: StaticString = #file, line: UInt = #line) {
        let treeDefaults: [MultiPathConfig] = [
            AnyOrderMatch(paths: nil, isActive: false),
            CollectionEqualCount(paths: nil, isActive: false),
            KeyMustBeAbsent(paths: nil, isActive: false),
            ValueExactMatch(paths: nil)
        ]

        validate(
            expected: expected,
            actual: actual,
            pathOptions: pathOptions,
            treeDefaults: treeDefaults,
            file: file,
            line: line)
    }

    /// Performs JSON validation where only the values from the `expected` JSON are required by default.
    /// By default, the comparison logic uses the value exact match option, validating that both values are of the same type
    /// **and** have the same literal value.
    ///
    /// Both objects and arrays use extensible collections by default, meaning that only the elements in `expected` are
    /// validated.
    ///
    /// Path options allow for powerful customizations to the comparison logic; see structs conforming to ``MultiPathConfig``:
    /// - ``AnyOrderMatch``
    /// - ``CollectionEqualCount``
    /// - ``KeyMustBeAbsent``
    /// - ``ValueExactMatch``, ``ValueTypeMatch``
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Paths must begin from the top level of the expected JSON. Multiple paths and path options can be used at the same time.
    /// Path options are applied sequentially. If an option overrides an existing one, the overriding will occur in the order in which
    /// the path options are specified.
    ///
    /// Formats for object keys:
    /// - Standard keys - The key name itself: `"key1"`
    /// - Nested keys - Use dot notation: `"key3.key4"`.
    /// - Keys with dots in the name: Escape the dot notation with a backslash: `"key\.name"`.
    ///
    /// Formats for arrays:
    /// - Standard index - The index integer inside square brackets: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets in the name - Escape the brackets with backslashes: `key\[123\]`.
    ///
    /// Formats for wildcard object key and array index names:
    /// - Array wildcard - All children elements of the array: `[*]` (ex: `key1[*].key3`)
    /// - Object wildcard - All children elements of the object: `*` (ex: `key1.*.key3`)
    /// - Key whose name is asterisk - Escape the asterisk with backslash: `"\*"`
    /// - Note that wildcard path options also apply to any existing specific nodes at the same level.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - pathOptions: The path options to use in the validation process.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, pathOptions: MultiPathConfig..., file: StaticString = #file, line: UInt = #line) {
        assertExactMatch(expected: expected, actual: actual, pathOptions: pathOptions, file: file, line: line)
    }

    // swiftlint:disable function_parameter_count
    private func validate(
        expected: AnyCodableComparable,
        actual: AnyCodableComparable?,
        pathOptions: [MultiPathConfig],
        treeDefaults: [MultiPathConfig],
        file: StaticString,
        line: UInt) {
        guard let expected = expected.toAnyCodable() else {
            XCTFail("Expected is nil. If nil is expected, use XCTAssertNil instead.", file: file, line: line)
            return
        }
        let actual = actual?.toAnyCodable()

        let nodeTree = generateNodeTree(
            pathOptions: pathOptions,
            treeDefaults: treeDefaults,
            file: file,
            line: line)
        _ = validateActual(actual: actual, nodeTree: nodeTree, file: file, line: line)
        validateJSON(expected: expected, actual: actual, nodeTree: nodeTree, file: file, line: line)
    }
    // swiftlint:enable function_parameter_count

    // MARK: - AnyCodable validation helpers
    // swiftlint:disable function_body_length
    /// Performs a cutomizable validation between the given `expected` and `actual` values, using the configured options.
    /// In case of a validation failure **and** if `shouldAssert` is `true`, a test failure occurs.
    ///
    /// - Parameters:
    ///   - expected: The expected value to compare.
    ///   - actual: The actual value to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared. Defaults to an empty list.
    ///   - nodeTree: A tree of configuration objects used to control various validation settings.
    ///   - shouldAssert: Indicates if an assertion error should be thrown if `expected` and `actual` are not equal. Defaults to `true`.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: `true` if `expected` and `actual` are equal based on the settings in `nodeTree`, otherwise returns `false`.
    @discardableResult
    private func validateJSON(
        expected: AnyCodable?,
        actual: AnyCodable?,
        keyPath: [Any] = [],
        nodeTree: NodeConfig,
        shouldAssert: Bool = true,
        file: StaticString = #file,
        line: UInt = #line) -> Bool {
        if expected?.value == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(
                    """
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \(String(describing: expected))

                    Actual: \(String(describing: actual))

                    Key path: \(keyPathAsString(keyPath))
                    """,
                    file: file,
                    line: line)
            }
            return false
        }

        // swiftlint:disable no_fallthrough_only
        switch (expected, actual) {
        case let (expected, actual) where (expected.value is String && actual.value is String):
            fallthrough
        case let (expected, actual) where (expected.value is Bool && actual.value is Bool):
            fallthrough
        case let (expected, actual) where (expected.value is Int && actual.value is Int):
            fallthrough
        case let (expected, actual) where (expected.value is Double && actual.value is Double):
            if nodeTree.primitiveExactMatch.isActive {
                if shouldAssert {
                    XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath))", file: file, line: line)
                }
                return expected == actual
            } else {
                // Value type matching already passed by virtue of passing the where condition in the switch case
                return true
            }
        case let (expected, actual) where (expected.value is [String: AnyCodable] && actual.value is [String: AnyCodable]):
            return validateJSON(
                expected: expected.value as? [String: AnyCodable],
                actual: actual.value as? [String: AnyCodable],
                keyPath: keyPath,
                nodeTree: nodeTree,
                shouldAssert: shouldAssert,
                file: file,
                line: line)
        case let (expected, actual) where (expected.value is [AnyCodable] && actual.value is [AnyCodable]):
            return validateJSON(
                expected: expected.value as? [AnyCodable],
                actual: actual.value as? [AnyCodable],
                keyPath: keyPath,
                nodeTree: nodeTree,
                shouldAssert: shouldAssert,
                file: file,
                line: line)
        case let (expected, actual) where (expected.value is [Any?] && actual.value is [Any?]):
            return validateJSON(
                expected: AnyCodable.from(array: expected.value as? [Any?]),
                actual: AnyCodable.from(array: actual.value as? [Any?]),
                keyPath: keyPath,
                nodeTree: nodeTree,
                shouldAssert: shouldAssert,
                file: file,
                line: line)
        case let (expected, actual) where (expected.value is [String: Any?] && actual.value is [String: Any?]):
            return validateJSON(
                expected: AnyCodable.from(dictionary: expected.value as? [String: Any?]),
                actual: AnyCodable.from(dictionary: actual.value as? [String: Any?]),
                keyPath: keyPath,
                nodeTree: nodeTree,
                shouldAssert: shouldAssert,
                file: file,
                line: line)
        default:
            if shouldAssert {
                XCTFail(
                    """
                    Expected and Actual types do not match.

                    Expected: \(expected) (Type: \(type(of: expected)))

                    Actual: \(actual) (Type: \(type(of: actual)))

                    Key path: \(keyPathAsString(keyPath))
                    """,
                    file: file,
                    line: line)
            }
            return false
        // swiftlint:enable no_fallthrough_only
        }
    }

    /// Performs a cutomizable validation between the given `expected` and `actual` `AnyCodable`arrays, using the configured options.
    /// In case of a validation failure **and** if `shouldAssert` is `true`, a test failure occurs.
    ///
    /// - Parameters:
    ///   - expected: The expected array of `AnyCodable` to compare.
    ///   - actual: The actual array of `AnyCodable` to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared.
    ///   - nodeTree: A tree of configuration objects used to control various validation settings.
    ///   - shouldAssert: Indicates if an assertion error should be thrown if `expected` and `actual` are not equal.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: `true` if `expected` and `actual` are equal based on the settings in `nodeTree`, otherwise returns `false`.
    private func validateJSON(
        expected: [AnyCodable]?,
        actual: [AnyCodable]?,
        keyPath: [Any],
        nodeTree: NodeConfig,
        shouldAssert: Bool = true,
        file: StaticString = #file,
        line: UInt = #line) -> Bool {
        if expected == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(
                    """
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \(String(describing: expected))

                    Actual: \(String(describing: actual))

                    Key path: \(keyPathAsString(keyPath))
                    """,
                    file: file,
                    line: line)
            }
            return false
        }
        if nodeTree.collectionEqualCount.isActive ? (expected.count != actual.count) : (expected.count > actual.count) {
            if shouldAssert {
                XCTFail(
                    """
                    Expected JSON \(nodeTree.collectionEqualCount.isActive ? "count does not match" : "has more elements than") Actual JSON.

                    Expected count: \(expected.count)
                    Actual count: \(actual.count)

                    Expected: \(expected)

                    Actual: \(actual)

                    Key path: \(keyPathAsString(keyPath))
                    """,
                    file: file,
                    line: line)
            }
            return false
        }

        // Create a dictionary where:
        // key: the index in String format
        // value: the resolved option for if wildcard matching should be used for the index
        //   - see resolveOption for precedence
        var expectedIndexes = (0..<expected.count).reduce(into: [String: NodeConfig.Config]()) { result, index in
            let indexString = String(index)
            result[indexString] = NodeConfig.resolveOption(
                .anyOrderMatch,
                childName: indexString,
                parentNode: nodeTree)
        }
        let anyOrderIndexes = expectedIndexes.filter({ $0.value.isActive })
        anyOrderIndexes.forEach { key, _ in
            expectedIndexes.removeValue(forKey: key)
        }

        var availableAnyOrderActualIndexes = Set((0..<actual.count).map({ String($0) })).subtracting(expectedIndexes.keys)

        var validationResult = true

        // Validate non-any-order expected side indexes first, as these don't have
        // order flexibility
        for (index, _) in expectedIndexes {
            let intIndex = Int(index)! // swiftlint:disable:this force_unwrapping
            validationResult = validateJSON(
                expected: expected[intIndex],
                actual: actual[intIndex],
                keyPath: keyPath + [intIndex],
                nodeTree: nodeTree.getNextNode(for: index),
                shouldAssert: shouldAssert,
                file: file,
                line: line)
                && validationResult
        }

        for (index, _) in anyOrderIndexes {
            let intIndex = Int(index)! // swiftlint:disable:this force_unwrapping

            guard let actualIndex = availableAnyOrderActualIndexes.first(where: {
                validateJSON(
                    expected: expected[intIndex],
                    actual: actual[Int($0)!], // swiftlint:disable:this force_unwrapping
                    keyPath: keyPath + [intIndex],
                    nodeTree: nodeTree.getNextNode(for: index),
                    shouldAssert: false)
            }) else {
                // swiftlint:disable force_unwrapping
                if shouldAssert {
                    XCTFail(
                        """
                        Any order \(NodeConfig.resolveOption(.primitiveExactMatch, childName: index, parentNode: nodeTree).isActive ? "exact" : "type")
                        match found no matches on Actual side satisfying the Expected requirement.

                        Requirement: \(nodeTree)

                        Expected: \(expected[intIndex])

                        Actual (remaining unmatched elements): \(availableAnyOrderActualIndexes.map({ actual[Int($0)!] }))

                        Key path: \(keyPathAsString(keyPath))
                        """,
                        file: file,
                        line: line)
                }
                // swiftlint:enable force_unwrapping
                validationResult = false
                break
            }
            availableAnyOrderActualIndexes.remove(actualIndex)
        }
        return validationResult
    }

    /// Performs a cutomizable validation between the given `expected` and `actual` `AnyCodable`dictionaries, using the configured options.
    /// In case of a validation failure **and** if `shouldAssert` is `true`, a test failure occurs.
    ///
    /// - Parameters:
    ///   - expected: The expected dictionary of `AnyCodable` to compare.
    ///   - actual: The actual dictionary of `AnyCodable` to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared.
    ///   - nodeTree: A tree of configuration objects used to control various validation settings.
    ///   - shouldAssert: Indicates if an assertion error should be thrown if `expected` and `actual` are not equal.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: `true` if `expected` and `actual` are equal based on the settings in `nodeTree`, otherwise returns `false`.
    private func validateJSON(
        expected: [String: AnyCodable]?,
        actual: [String: AnyCodable]?,
        keyPath: [Any],
        nodeTree: NodeConfig,
        shouldAssert: Bool = true,
        file: StaticString = #file,
        line: UInt = #line) -> Bool {
        if expected == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(
                    """
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \(String(describing: expected))

                    Actual: \(String(describing: actual))

                    Key path: \(keyPathAsString(keyPath))
                    """,
                    file: file,
                    line: line)
            }
            return false
        }
        if nodeTree.collectionEqualCount.isActive ? (expected.count != actual.count) : (expected.count > actual.count) {
            if shouldAssert {
                XCTFail(
                    """
                    Expected JSON \(nodeTree.collectionEqualCount.isActive ? "count does not match" : "has more elements than") Actual JSON.

                    Expected count: \(expected.count)
                    Actual count: \(actual.count)

                    Expected: \(expected)

                    Actual: \(actual)

                    Key path: \(keyPathAsString(keyPath))
                    """,
                    file: file,
                    line: line)
            }
            return false
        }

        var validationResult = true

        for (key, value) in expected {
            validationResult = validateJSON(
                expected: value,
                actual: actual[key],
                keyPath: keyPath + [key],
                nodeTree: nodeTree.getNextNode(for: key),
                shouldAssert: shouldAssert,
                file: file,
                line: line)
                && validationResult
        }
        return validationResult
    }
    // swiftlint:enable function_body_length

    // MARK: - Actual JSON validation

    /// Validates the provided `actual` value against a specified `nodeTree` configuration.
    ///
    /// This method traverses a `NodeConfig` tree to validate the `actual` value according to the specified node configuration.
    /// It handles different types of values including dictionaries and arrays, and applies the relevant validation rules
    /// based on the configuration of each node in the tree.
    ///
    /// Note that this logic is meant to perform negative validation (for example, the absence of keys), and this means when `actual` nodes run out
    /// validation automatically passes. Positive validation should use `expected` + `validateJSON`
    ///
    /// - Parameters:
    ///   - actual: The value to be validated, wrapped in `AnyCodable`.
    ///   - keyPath: An array representing the current traversal path in the node tree. Starts as an empty array.
    ///   - nodeTree: The root of the `NodeConfig` tree against which the validation is performed.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: A `Bool` indicating whether the `actual` value is valid based on the `nodeTree` configuration.
    internal func validateActual(
        actual: AnyCodable?,
        keyPath: [Any] = [],
        nodeTree: NodeConfig,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ValidationResult {
        guard let actual = actual else {
            return ValidationResult(isValid: true, elementCount: 0)
        }

        switch actual.value {
        // Handle dictionaries
        case let dict as [String: AnyCodable]:
            return validateActual(
                actual: dict,
                keyPath: keyPath,
                nodeTree: nodeTree,
                file: file,
                line: line
            )
        case let dict as [String: Any?]:
            return validateActual(
                actual: AnyCodable.from(dictionary: dict),
                keyPath: keyPath,
                nodeTree: nodeTree,
                file: file,
                line: line
            )
        // Handle arrays
        case let array as [AnyCodable]:
            return validateActual(
                actual: array,
                keyPath: keyPath,
                nodeTree: nodeTree,
                file: file,
                line: line
            )
        case let array as [Any?]:
            return validateActual(
                actual: AnyCodable.from(array: array),
                keyPath: keyPath,
                nodeTree: nodeTree,
                file: file,
                line: line
            )
        default:
            // Check SingleNode and Subtree options set for ElementCount for this specific node.
            // If it hits this case, then the ElementCount assertion was set on a non-collection type element
            // and should emit a test failure.
            if nodeTree.options[.elementCount]?.elementCount != nil ||
               nodeTree.subtreeOptions[.elementCount]?.elementCount != nil {
                XCTFail(
                    """
                    Invalid ElementCount assertion on a non-collection element.
                    Remove ElementCount requirements from this key path in the test setup.

                    Key path: \(keyPathAsString(keyPath))
                    """,
                    file: file,
                    line: line
                )
                return ValidationResult(isValid: false, elementCount: 1)
            }
            return ValidationResult(isValid: true, elementCount: 1)
        }
    }

    /// Validates an array of `AnyCodable` values against the provided node configuration tree.
    ///
    /// This method iterates through each element in the given array of `AnyCodable` and performs validation
    /// based on the provided `NodeConfig`.
    ///
    /// - Parameters:
    ///   - actual: The array of `AnyCodable` values to be validated.
    ///   - keyPath: An array representing the current path in the node tree during the traversal.
    ///   - nodeTree: The current node in the `NodeConfig` tree against which the `actual` values are validated.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: A `Bool` indicating whether all elements in the `actual` array are valid according to the node tree configuration.
    private func validateActual(
        actual: [AnyCodable]?,
        keyPath: [Any],
        nodeTree: NodeConfig,
        file: StaticString,
        line: UInt
    ) -> ValidationResult {
        var validationResult = true
        var singleNodeElementCount = 0
        var subtreeElementCount = 0

        if let actual = actual {
            for (index, element) in actual.enumerated() {
                // ElementCount check
                let result = validateActual(
                    actual: element,
                    keyPath: keyPath + [index],
                    nodeTree: nodeTree.getNextNode(for: index),
                    file: file,
                    line: line
                )
                validationResult = result.isValid && validationResult

                switch element.value {
                case is [AnyCodable], is [String: AnyCodable]:
                    subtreeElementCount += result.elementCount
                default:
                    if NodeConfig.resolveOption(.elementCount, childName: "\(index)", parentNode: nodeTree).isActive {
                        singleNodeElementCount += result.elementCount
                    }
                }
            }
        }

        let totalElementCount = singleNodeElementCount + subtreeElementCount
        validationResult = validateElementCount(scope: .singleNode, keyPath: keyPath, node: nodeTree, elementCount: singleNodeElementCount) && validationResult
        validationResult = validateElementCount(scope: .subtree, keyPath: keyPath, node: nodeTree, elementCount: totalElementCount) && validationResult

        return ValidationResult(isValid: validationResult, elementCount: totalElementCount)
    }

    /// Validates a dictionary of `AnyCodable` values against the provided node configuration tree.
    ///
    /// This method iterates through each key-value pair in the given dictionary and performs validation
    /// based on the provided `NodeConfig`.
    ///
    /// - Parameters:
    ///   - actual: The dictionary of `AnyCodable` values to be validated.
    ///   - keyPath: An array representing the current path in the node tree during the traversal.
    ///   - nodeTree: The current node in the `NodeConfig` tree against which the `actual` values are validated.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: A `Bool` indicating whether all key-value pairs in the `actual` dictionary are valid according to the node tree configuration.
    private func validateActual(
        actual: [String: AnyCodable]?,
        keyPath: [Any],
        nodeTree: NodeConfig,
        file: StaticString,
        line: UInt
    ) -> ValidationResult {
        var validationResult = true
        var singleNodeElementCount = 0
        var subtreeElementCount = 0

        if let actual = actual {
            for (key, value) in actual {
                // MARK: KeyMustBeAbsent check
                // Check for keys that must be absent in the current node
                let resolvedKeyMustBeAbsent = NodeConfig.resolveOption(.keyMustBeAbsent, childName: key, parentNode: nodeTree)
                if resolvedKeyMustBeAbsent.isActive {
                    XCTFail(
                        """
                        Actual JSON must not have key with name: \(key)

                        Actual: \(actual)

                        Key path: \(keyPathAsString(keyPath + [key]))
                        """,
                        file: file,
                        line: line
                    )
                    validationResult = false
                }

                // ElementCount check
                let result = validateActual(
                    actual: value,
                    keyPath: keyPath + [key],
                    nodeTree: nodeTree.getNextNode(for: key),
                    file: file,
                    line: line
                )
                validationResult = result.isValid && validationResult

                switch value.value {
                case is [String: AnyCodable], is [AnyCodable]:
                    subtreeElementCount += result.elementCount
                default:
                    if NodeConfig.resolveOption(.elementCount, childName: key, parentNode: nodeTree).isActive {
                        singleNodeElementCount += result.elementCount
                    }
                }
            }
        }

        let totalElementCount = singleNodeElementCount + subtreeElementCount
        validationResult = validateElementCount(scope: .singleNode, keyPath: keyPath, node: nodeTree, elementCount: singleNodeElementCount) && validationResult
        validationResult = validateElementCount(scope: .subtree, keyPath: keyPath, node: nodeTree, elementCount: totalElementCount) && validationResult

        return ValidationResult(isValid: validationResult, elementCount: totalElementCount)
    }

    /**
     * Validates that the element count for a given scope is satisfied within the node configuration.
     * Used to validate [ElementCount] assertions.
     *
     * - Parameters:
     *   - scope: The scope of the element count check, either SingleNode or Subtree.
     *   - keyPath: The current path in the JSON hierarchy traversal. Used for test failure message info.
     *   - node: The current node in the NodeConfig tree against which the element count is validated.
     *   - elementCount: The actual count of elements to be validated.
     * - Returns: `true` if the element count is satisfied, `false` otherwise.
     */
    private func validateElementCount(scope: NodeConfig.Scope, keyPath: [Any], node: NodeConfig, elementCount: Int) -> Bool {
        var validationResult = true
        let config: NodeConfig.Config? = {
            switch scope {
            case .singleNode:
                return node.options[.elementCount]
            case .subtree:
                return node.subtreeOptions[.elementCount]
            }
        }()

        // Check if the element count is satisfied
        if let config = config, config.isActive, let expectedCount = config.elementCount {
            validationResult = (expectedCount == elementCount)
            assert(
                validationResult,
                """
                The \(scope == .subtree ? "subtree" : "single node") expected element count
                is not equal to the actual number of elements.

                Expected count: \(expectedCount)
                Actual count: \(elementCount)

                Key path: \(keyPathAsString(keyPath))
                """
            )
        }
        return validationResult
    }

    // MARK: - Test setup and output helpers

    /// Generates a tree structure from an array of path `String`s.
    ///
    /// This function processes each path in `paths`, extracts its individual components using `processPathComponents`, and
    /// constructs a nested dictionary structure. The constructed dictionary is then merged into the main tree. If the resulting tree
    /// is empty after processing all paths, this function returns `nil`.
    ///
    /// - Parameter paths: An array of path `String`s to be processed. Each path represents a nested structure to be transformed
    /// into a tree-like dictionary.
    ///
    /// - Returns: A tree-like dictionary structure representing the nested structure of the provided paths. Returns `nil` if the
    /// resulting tree is empty.
    private func generateNodeTree(pathOptions: [MultiPathConfig], treeDefaults: [MultiPathConfig], file: StaticString, line: UInt) -> NodeConfig {
        // 1. creates the first node using the incoming defaults
        // using the first node it passes the path to the node to create the child nodes and just loops through all the paths passing them

        var subtreeOptions: [NodeConfig.OptionKey: NodeConfig.Config] = [:]
        for treeDefault in treeDefaults {
            let key = treeDefault.optionKey
            subtreeOptions[key] = treeDefault.config
        }

        let rootNode = NodeConfig(name: nil, subtreeOptions: subtreeOptions)

        for pathConfig in pathOptions {
            NodeConfig.createOrUpdateNode(rootNode, with: pathConfig, file: file, line: line)
        }

        return rootNode
    }

    /// Converts a key path represented by an array of JSON object keys and array indexes into a human-readable `String` format.
    ///
    /// The key path is used to trace the recursive traversal of a nested JSON structure.
    /// For instance, the key path for the value "Hello" in the JSON `{ "a": { "b": [ "World", "Hello" ] } }`
    /// would be `["a", "b", 1]`.
    /// This method would convert it to the `String`: `"a.b[1]"`.
    ///
    /// Special considerations:
    /// 1. If a key in the JSON object contains a dot (`.`), it will be escaped with a backslash in the resulting `String`.
    /// 2. Empty keys in the JSON object will be represented as `""` in the resulting `String`.
    ///
    /// - Parameter keyPath: An array of keys or array indexes representing the path to a value in a nested JSON structure.
    ///
    /// - Returns: A human-readable `String` representation of the key path.
    private func keyPathAsString(_ keyPath: [Any]) -> String {
        var result = ""
        for item in keyPath {
            switch item {
            case let item as String:
                if !result.isEmpty {
                    result += "."
                }
                if item.contains(".") {
                    result += item.replacingOccurrences(of: ".", with: "\\.")
                } else if item.isEmpty {
                    result += "\"\""
                } else {
                    result += item
                }
            case let item as Int:
                result += "[" + String(item) + "]"
            default:
                break
            }
        }
        return result
    }
}
