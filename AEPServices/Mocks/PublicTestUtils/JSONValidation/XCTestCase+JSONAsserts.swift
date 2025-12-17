/*
 Copyright 2023 Adobe. All rights reserved.
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

public extension XCTestCase {
    
    /// Asserts exact equality between two `AnyCodableComparable` instances.
    ///
    /// Both type and value must match exactly, and collections must have the same count.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    @available(*, deprecated, message: "Use assertJSON(expected:actual:).equalCount(scope: .subtree).validate() instead")
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
        // Exact equality is exact match with equal count enforced on the entire tree
        assertJSON(expected: expected, actual: actual, file: file, line: line)
            .equalCount(scope: .subtree)
            .validate()
    }

    /// Performs JSON validation where only the types from the `expected` JSON are required.
    ///
    /// Values must have the same type but their literal values can differ.
    /// Both objects and arrays use extensible collections by default.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    @available(*, deprecated, message: "Use assertJSON(expected:actual:).typeMatch(scope: .subtree).validate() instead")
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        assertJSON(expected: expected, actual: actual, file: file, line: line)
            .typeMatch(scope: .subtree)
            .validate()
    }

    /// Performs JSON validation where only the values from the `expected` JSON are required.
    ///
    /// Values must have the same type AND the same literal value.
    /// Both objects and arrays use extensible collections by default.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    @available(*, deprecated, message: "Use assertJSON(expected:actual:).validate() instead")
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        // exactMatch is the default, so no additional options needed
        assertJSON(expected: expected, actual: actual, file: file, line: line)
            .validate()
    }
}
