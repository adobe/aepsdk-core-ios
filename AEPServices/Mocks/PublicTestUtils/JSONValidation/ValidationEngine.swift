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

import AEPServices
import Foundation

/// Represents a single validation failure with details about what went wrong.
public struct ValidationFailure: CustomStringConvertible {
    /// The key path where the failure occurred (e.g., "users[0].name").
    public let keyPath: String
    
    /// A human-readable message describing the failure.
    public let message: String
    
    /// The expected value (if applicable).
    public let expected: String?
    
    /// The actual value (if applicable).
    public let actual: String?
    
    public init(keyPath: String, message: String, expected: String? = nil, actual: String? = nil) {
        self.keyPath = keyPath
        self.message = message
        self.expected = expected
        self.actual = actual
    }
    
    public var description: String {
        var result = message
        if let expected = expected {
            result += "\n\nExpected: \(expected)"
        }
        if let actual = actual {
            result += "\n\nActual: \(actual)"
        }
        if !keyPath.isEmpty {
            result += "\n\nKey path: \(keyPath)"
        }
        return result
    }
}

// MARK: - ValidationResult

/// The result of a JSON validation operation.
public struct ValidationResult {
    /// Whether the validation passed.
    public let isValid: Bool
    
    /// The list of validation failures (empty if valid).
    public let failures: [ValidationFailure]
    
    /// Creates a successful validation result.
    public static let success = ValidationResult(isValid: true, failures: [])
    
    /// Creates a failed validation result with the given failures.
    public static func failure(_ failures: [ValidationFailure]) -> ValidationResult {
        return ValidationResult(isValid: false, failures: failures)
    }
    
    /// Creates a failed validation result with a single failure.
    public static func failure(_ failure: ValidationFailure) -> ValidationResult {
        return ValidationResult(isValid: false, failures: [failure])
    }
    
    /// Combines this result with another, aggregating any failures.
    public func combined(with other: ValidationResult) -> ValidationResult {
        if isValid && other.isValid {
            return .success
        }
        return ValidationResult(isValid: false, failures: failures + other.failures)
    }
}

// MARK: - ValidationEngine

/// A pure validation engine for comparing JSON structures.
///
/// This engine contains no XCTest dependencies and returns structured results
/// that can be used by test assertion helpers or other consumers.
enum ValidationEngine {
    
    // MARK: - Public API
    
    /// Validates that `actual` matches `expected` according to the given configuration.
    ///
    /// - Parameters:
    ///   - expected: The expected JSON value.
    ///   - actual: The actual JSON value to validate.
    ///   - config: The node configuration controlling validation behavior.
    /// - Returns: A `ValidationResult` indicating success or failure with details.
    static func validate(
        expected: AnyCodable?,
        actual: AnyCodable?,
        config: NodeConfig
    ) -> ValidationResult {
        // First validate "actual-only" constraints (like keyMustBeAbsent)
        let actualResult = validateActualConstraints(actual: actual, config: config)
        
        // Then validate expected vs actual
        let comparisonResult = validateComparison(expected: expected, actual: actual, keyPath: [], config: config)
        
        return actualResult.combined(with: comparisonResult)
    }
    
    // MARK: - Comparison Validation
    
    private static func validateComparison(
        expected: AnyCodable?,
        actual: AnyCodable?,
        keyPath: [Any],
        config: NodeConfig
    ) -> ValidationResult {
        // Nil expected means no requirement
        if expected?.value == nil {
            return .success
        }
        
        guard let expected = expected, let actual = actual else {
            return .failure(ValidationFailure(
                keyPath: keyPathAsString(keyPath),
                message: "Expected JSON is non-nil but Actual JSON is nil.",
                expected: String(describing: expected),
                actual: String(describing: actual)
            ))
        }
        
        // Handle different types
        switch (expected.value, actual.value) {
        case (let e as String, let a as String):
            return validatePrimitive(expected: e, actual: a, keyPath: keyPath, config: config)
        case (let e as Bool, let a as Bool):
            return validatePrimitive(expected: e, actual: a, keyPath: keyPath, config: config)
        case (let e as Int, let a as Int):
            return validatePrimitive(expected: e, actual: a, keyPath: keyPath, config: config)
        case (let e as Double, let a as Double):
            return validatePrimitive(expected: e, actual: a, keyPath: keyPath, config: config)
        case (let e as [String: AnyCodable], let a as [String: AnyCodable]):
            return validateDictionary(expected: e, actual: a, keyPath: keyPath, config: config)
        case (let e as [AnyCodable], let a as [AnyCodable]):
            return validateArray(expected: e, actual: a, keyPath: keyPath, config: config)
        case (let e as [String: Any?], let a as [String: Any?]):
            return validateDictionary(
                expected: AnyCodable.from(dictionary: e),
                actual: AnyCodable.from(dictionary: a),
                keyPath: keyPath,
                config: config
            )
        case (let e as [Any?], let a as [Any?]):
            return validateArray(
                expected: AnyCodable.from(array: e),
                actual: AnyCodable.from(array: a),
                keyPath: keyPath,
                config: config
            )
        default:
            return .failure(ValidationFailure(
                keyPath: keyPathAsString(keyPath),
                message: "Expected and Actual types do not match.",
                expected: "\(expected) (Type: \(type(of: expected.value)))",
                actual: "\(actual) (Type: \(type(of: actual.value)))"
            ))
        }
    }
    
    private static func validatePrimitive<T: Equatable>(
        expected: T,
        actual: T,
        keyPath: [Any],
        config: NodeConfig
    ) -> ValidationResult {
        // Check for valueNotEqual constraint (inverse matching)
        if config.isValueNotEqual {
            if expected == actual {
                return .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath),
                    message: "Values must NOT be equal, but they are.",
                    expected: "not \(String(describing: expected))",
                    actual: String(describing: actual)
                ))
            } else {
                // Values are different - this is what we want
                return .success
            }
        }
        
        // Normal matching logic
        if config.isExactMatch {
            if expected == actual {
                return .success
            } else {
                return .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath),
                    message: "Values do not match.",
                    expected: String(describing: expected),
                    actual: String(describing: actual)
                ))
            }
        } else {
            // Type match only - types already match if we got here
            return .success
        }
    }
    
    private static func validateDictionary(
        expected: [String: AnyCodable]?,
        actual: [String: AnyCodable]?,
        keyPath: [Any],
        config: NodeConfig
    ) -> ValidationResult {
        guard let expected = expected else { return .success }
        guard let actual = actual else {
            return .failure(ValidationFailure(
                keyPath: keyPathAsString(keyPath),
                message: "Expected JSON is non-nil but Actual JSON is nil.",
                expected: String(describing: expected),
                actual: "nil"
            ))
        }
        
        // Check count constraints
        if config.isEqualCount {
            if expected.count != actual.count {
                return .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath),
                    message: "Expected JSON count does not match Actual JSON.",
                    expected: "count: \(expected.count) - \(expected)",
                    actual: "count: \(actual.count) - \(actual)"
                ))
            }
        } else if expected.count > actual.count {
            return .failure(ValidationFailure(
                keyPath: keyPathAsString(keyPath),
                message: "Expected JSON has more elements than Actual JSON.",
                expected: "count: \(expected.count) - \(expected)",
                actual: "count: \(actual.count) - \(actual)"
            ))
        }
        
        // Validate each expected key
        var result = ValidationResult.success
        for (key, value) in expected {
            // Use generic resolver to get child config
            let childConfig = config.resolvedChild(named: key)
            let childResult = validateComparison(
                expected: value,
                actual: actual[key],
                keyPath: keyPath + [key],
                config: childConfig
            )
            result = result.combined(with: childResult)
        }
        
        return result
    }
    
    private static func validateArray(
        expected: [AnyCodable]?,
        actual: [AnyCodable]?,
        keyPath: [Any],
        config: NodeConfig
    ) -> ValidationResult {
        guard let expected = expected else { return .success }
        guard let actual = actual else {
            return .failure(ValidationFailure(
                keyPath: keyPathAsString(keyPath),
                message: "Expected JSON is non-nil but Actual JSON is nil.",
                expected: String(describing: expected),
                actual: "nil"
            ))
        }
        
        // Check count constraints
        if config.isEqualCount {
            if expected.count != actual.count {
                return .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath),
                    message: "Expected JSON count does not match Actual JSON.",
                    expected: "count: \(expected.count) - \(expected)",
                    actual: "count: \(actual.count) - \(actual)"
                ))
            }
        } else if expected.count > actual.count {
            return .failure(ValidationFailure(
                keyPath: keyPathAsString(keyPath),
                message: "Expected JSON has more elements than Actual JSON.",
                expected: "count: \(expected.count) - \(expected)",
                actual: "count: \(actual.count) - \(actual)"
            ))
        }
        
        // Separate indexes into any-order and fixed-order groups
        var fixedOrderIndexes: [Int] = []
        var anyOrderIndexes: [Int] = []
        
        for index in 0..<expected.count {
            // Use generic resolver to check if this child uses any-order
            let childConfig = config.resolvedChild(at: index)
            if childConfig.isAnyOrder {
                anyOrderIndexes.append(index)
            } else {
                fixedOrderIndexes.append(index)
            }
        }
        
        var result = ValidationResult.success
        var availableActualIndexes = Set(0..<actual.count).subtracting(fixedOrderIndexes)
        
        // Validate fixed-order indexes first
        for index in fixedOrderIndexes {
            let childConfig = config.resolvedChild(at: index)
            let childResult = validateComparison(
                expected: expected[index],
                actual: actual[index],
                keyPath: keyPath + [index],
                config: childConfig
            )
            result = result.combined(with: childResult)
        }
        
        // Validate any-order indexes
        for index in anyOrderIndexes {
            let childConfig = config.resolvedChild(at: index)
            let matchingActualIndex = availableActualIndexes.first { actualIndex in
                let checkResult = validateComparison(
                    expected: expected[index],
                    actual: actual[actualIndex],
                    keyPath: keyPath + [index],
                    config: childConfig
                )
                return checkResult.isValid
            }
            
            if let matchingIndex = matchingActualIndex {
                availableActualIndexes.remove(matchingIndex)
            } else {
                let remainingElements = availableActualIndexes.map { actual[$0] }
                result = result.combined(with: .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath),
                    message: "Any order \(childConfig.isExactMatch ? "exact" : "type") match found no matches on Actual side satisfying the Expected requirement.",
                    expected: String(describing: expected[index]),
                    actual: "Remaining unmatched elements: \(remainingElements)"
                )))
                break
            }
        }
        
        return result
    }
    
    // MARK: - Actual-Only Constraints Validation
    
    private static func validateActualConstraints(
        actual: AnyCodable?,
        keyPath: [Any] = [],
        config: NodeConfig
    ) -> ValidationResult {
        guard let actual = actual else { return .success }
        
        switch actual.value {
        case let dict as [String: AnyCodable]:
            return validateActualDictionaryConstraints(actual: dict, keyPath: keyPath, config: config)
        case let dict as [String: Any?]:
            return validateActualDictionaryConstraints(
                actual: AnyCodable.from(dictionary: dict),
                keyPath: keyPath,
                config: config
            )
        case let array as [AnyCodable]:
            return validateActualArrayConstraints(actual: array, keyPath: keyPath, config: config)
        case let array as [Any?]:
            return validateActualArrayConstraints(
                actual: AnyCodable.from(array: array),
                keyPath: keyPath,
                config: config
            )
        default:
            // Check for invalid elementCount on primitive
            if config.elementCount != nil {
                return .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath),
                    message: "Invalid elementCount assertion on a non-collection element. Remove elementCount requirements from this key path in the test setup."
                ))
            }
            return .success
        }
    }
    
    private static func validateActualDictionaryConstraints(
        actual: [String: AnyCodable]?,
        keyPath: [Any],
        config: NodeConfig
    ) -> ValidationResult {
        guard let actual = actual else { return .success }
        
        var result = ValidationResult.success
        
        for (key, value) in actual {
            // Use generic resolver to check if this child must be absent
            let childConfig = config.resolvedChild(named: key)
            if childConfig.isKeyMustBeAbsent {
                result = result.combined(with: .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath + [key]),
                    message: "Actual JSON must not have key with name: \(key)",
                    actual: String(describing: actual)
                )))
            }
            
            // Recursively check children
            let childResult = validateActualConstraints(
                actual: value,
                keyPath: keyPath + [key],
                config: childConfig
            )
            result = result.combined(with: childResult)
        }
        
        // Check elementCount constraint
        result = result.combined(with: validateElementCount(
            actual: actual,
            keyPath: keyPath,
            config: config
        ))
        
        return result
    }
    
    private static func validateActualArrayConstraints(
        actual: [AnyCodable]?,
        keyPath: [Any],
        config: NodeConfig
    ) -> ValidationResult {
        guard let actual = actual else { return .success }
        
        var result = ValidationResult.success
        
        for (index, element) in actual.enumerated() {
            // Use generic resolver to get child config
            let childConfig = config.resolvedChild(at: index)
            let childResult = validateActualConstraints(
                actual: element,
                keyPath: keyPath + [index],
                config: childConfig
            )
            result = result.combined(with: childResult)
        }
        
        // Check elementCount constraint
        result = result.combined(with: validateElementCount(
            actual: actual,
            keyPath: keyPath,
            config: config
        ))
        
        return result
    }
    
    private static func validateElementCount<T>(
        actual: T,
        keyPath: [Any],
        config: NodeConfig
    ) -> ValidationResult {
        // Check single node element count
        if let expectedCount = config.elementCount {
            let actualCount: Int
            if let dict = actual as? [String: AnyCodable] {
                actualCount = dict.count
            } else if let array = actual as? [AnyCodable] {
                actualCount = array.count
            } else {
                return .success
            }
            
            if actualCount != expectedCount {
                return .failure(ValidationFailure(
                    keyPath: keyPathAsString(keyPath),
                    message: "The expected element count is not equal to the actual number of elements.",
                    expected: "count: \(expectedCount)",
                    actual: "count: \(actualCount)"
                ))
            }
        }
        
        return .success
    }
    
    // MARK: - Utility Methods
    
    /// Converts a key path array into a human-readable string.
    static func keyPathAsString(_ keyPath: [Any]) -> String {
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
