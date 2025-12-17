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
import XCTest

/// A fluent builder for constructing JSON validation assertions.
///
/// Use this builder to create readable, chainable JSON comparisons in tests.
///
/// ## Example Usage
///
/// ```swift
/// assertJSON(expected: expectedJSON, actual: actualJSON)
///     .anyOrder(at: "items[*]")
///     .typeMatch(at: "items[*].id", "items[*].timestamp")
///     .exactMatch(at: "items[*].name")
///     .equalCount(at: "items")
///     .validate()
/// ```
///
/// ## Default Behavior
///
/// By default, values are compared with exact matching (same type AND same value).
/// Use `.typeMatch(scope: .subtree)` for type-only matching across the entire tree.
///
/// ## Path Syntax
///
/// Paths use a JSONPath-like syntax:
/// - Object keys: `"user.name"` or `"user\.name"` (escaped dot for literal)
/// - Array indices: `"items[0]"`, `"items[0][1]"`
/// - Wildcards: `"items[*]"` (all array elements), `"user.*"` (all object keys)
///
/// ## Scopes
///
/// Options can be applied with different scopes:
/// - `.singleNode`: Applies only to the exact path specified
/// - `.subtree`: Applies to the path and all its descendants
///
public class JSONAssertionBuilder {
    
    // MARK: - Properties
    
    private let expected: AnyCodable?
    private let actual: AnyCodable?
    private var config: NodeConfig
    private let file: StaticString
    private let line: UInt
    
    // MARK: - Initialization
    
    init(expected: AnyCodable?, actual: AnyCodable?, file: StaticString, line: UInt) {
        self.expected = expected
        self.actual = actual
        self.file = file
        self.line = line
        // Initialize with exact match defaults
        self.config = NodeConfig(defaults: NodeConfig.Defaults(
            anyOrder: false,
            exactMatch: true,
            equalCount: false,
            keyMustBeAbsent: false,
            valueNotEqual: false
        ))
    }
    
    // MARK: - Array Ordering Options
    
    /// Enables any-order matching for array elements at the specified path(s).
    ///
    /// When enabled, array elements from `expected` can match elements in `actual`
    /// regardless of their index position.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where any-order matching should be enabled.
    ///            Pass empty array to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func anyOrder(at paths: [JSONPath], scope: JSONValidationScope = .singleNode) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setAnyOrder(true, at: path, scope: scope)
        }
        return self
    }
    
    /// Enables any-order matching for array elements at the specified path(s).
    ///
    /// When enabled, array elements from `expected` can match elements in `actual`
    /// regardless of their index position.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where any-order matching should be enabled.
    ///            Omit to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func anyOrder(at paths: JSONPath..., scope: JSONValidationScope = .singleNode) -> Self {
        return anyOrder(at: paths, scope: scope)
    }
    
    /// Requires strict ordering for array elements at the specified path(s).
    ///
    /// Use this to override an `anyOrder` setting for specific paths.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where strict ordering should be enforced.
    ///            Pass empty array to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func strictOrder(at paths: [JSONPath], scope: JSONValidationScope = .singleNode) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setAnyOrder(false, at: path, scope: scope)
        }
        return self
    }
    
    /// Requires strict ordering for array elements at the specified path(s).
    ///
    /// Use this to override an `anyOrder` setting for specific paths.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where strict ordering should be enforced.
    ///            Omit to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func strictOrder(at paths: JSONPath..., scope: JSONValidationScope = .singleNode) -> Self {
        return strictOrder(at: paths, scope: scope)
    }
    
    // MARK: - Collection Count Options
    
    /// Requires that collections have the same number of elements at the specified path(s).
    ///
    /// By default, `actual` can have more elements than `expected`.
    /// This option enforces that both have exactly the same count.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where equal count should be enforced.
    ///            Pass empty array to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func equalCount(at paths: [JSONPath], scope: JSONValidationScope = .singleNode) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setEqualCount(true, at: path, scope: scope)
        }
        return self
    }
    
    /// Requires that collections have the same number of elements at the specified path(s).
    ///
    /// By default, `actual` can have more elements than `expected`.
    /// This option enforces that both have exactly the same count.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where equal count should be enforced.
    ///            Omit to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func equalCount(at paths: JSONPath..., scope: JSONValidationScope = .singleNode) -> Self {
        return equalCount(at: paths, scope: scope)
    }
    
    /// Allows collections to have different counts at the specified path(s).
    ///
    /// Use this to override an `equalCount` setting.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where flexible count should be allowed.
    ///            Pass empty array to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func flexibleCount(at paths: [JSONPath], scope: JSONValidationScope = .singleNode) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setEqualCount(false, at: path, scope: scope)
        }
        return self
    }
    
    /// Allows collections to have different counts at the specified path(s).
    ///
    /// Use this to override an `equalCount` setting.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where flexible count should be allowed.
    ///            Omit to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func flexibleCount(at paths: JSONPath..., scope: JSONValidationScope = .singleNode) -> Self {
        return flexibleCount(at: paths, scope: scope)
    }
    
    /// Requires a specific number of elements at the specified path(s).
    ///
    /// - Parameters:
    ///   - count: The exact number of elements required.
    ///   - paths: The path(s) where the element count should be enforced.
    ///            Pass empty array to apply at the root level.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func elementCount(_ count: Int, at paths: [JSONPath]) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setElementCount(count, at: path)
        }
        return self
    }
    
    /// Requires a specific number of elements at the specified path(s).
    ///
    /// - Parameters:
    ///   - count: The exact number of elements required.
    ///   - paths: The path(s) where the element count should be enforced.
    ///            Omit to apply at the root level.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func elementCount(_ count: Int, at paths: JSONPath...) -> Self {
        return elementCount(count, at: paths)
    }
    
    // MARK: - Value Matching Options
    
    /// Requires exact value matching at the specified path(s).
    ///
    /// Values must have the same type AND the same literal value.
    /// This is the default behavior, but can be used to override a `typeMatch` setting.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where exact matching should be enforced.
    ///            Pass empty array to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func exactMatch(at paths: [JSONPath], scope: JSONValidationScope = .singleNode) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setExactMatch(true, at: path, scope: scope)
        }
        return self
    }
    
    /// Requires exact value matching at the specified path(s).
    ///
    /// Values must have the same type AND the same literal value.
    /// This is the default behavior, but can be used to override a `typeMatch` setting.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where exact matching should be enforced.
    ///            Omit to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func exactMatch(at paths: JSONPath..., scope: JSONValidationScope = .singleNode) -> Self {
        return exactMatch(at: paths, scope: scope)
    }
    
    /// Requires only type matching at the specified path(s).
    ///
    /// Values must have the same type, but their literal values can differ.
    /// Useful for dynamic values like timestamps, UUIDs, etc.
    ///
    /// Use `.typeMatch(scope: .subtree)` at root to enable type matching for the entire tree.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where type-only matching should be used.
    ///            Pass empty array to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func typeMatch(at paths: [JSONPath], scope: JSONValidationScope = .singleNode) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setExactMatch(false, at: path, scope: scope)
        }
        return self
    }
    
    /// Requires only type matching at the specified path(s).
    ///
    /// Values must have the same type, but their literal values can differ.
    /// Useful for dynamic values like timestamps, UUIDs, etc.
    ///
    /// Use `.typeMatch(scope: .subtree)` at root to enable type matching for the entire tree.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where type-only matching should be used.
    ///            Omit to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func typeMatch(at paths: JSONPath..., scope: JSONValidationScope = .singleNode) -> Self {
        return typeMatch(at: paths, scope: scope)
    }
    
    // MARK: - Key Presence Options
    
    /// Requires that the specified key(s) must NOT exist in actual.
    ///
    /// Use this to verify that certain fields have been removed or are not present.
    ///
    /// - Parameters:
    ///   - paths: The path(s) that must be absent in actual.
    ///            Pass empty array to apply at the root level.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func keyMustBeAbsent(at paths: [JSONPath]) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setKeyMustBeAbsent(true, at: path, scope: .singleNode)
        }
        return self
    }
    
    /// Requires that the specified key(s) must NOT exist in actual.
    ///
    /// Use this to verify that certain fields have been removed or are not present.
    ///
    /// - Parameters:
    ///   - paths: The path(s) that must be absent in actual.
    ///            Omit to apply at the root level.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func keyMustBeAbsent(at paths: JSONPath...) -> Self {
        return keyMustBeAbsent(at: paths)
    }
    
    // MARK: - Value Inequality Options
    
    /// Requires that values must NOT be equal at the specified path(s).
    ///
    /// This is the inverse of normal matching - validation fails if the expected
    /// and actual values ARE equal. Useful for verifying that a value has changed.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where values must differ.
    ///            Pass empty array to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func valueNotEqual(at paths: [JSONPath], scope: JSONValidationScope = .singleNode) -> Self {
        let finalPaths = paths.isEmpty ? [.root] : paths
        for path in finalPaths {
            config.setValueNotEqual(true, at: path, scope: scope)
        }
        return self
    }
    
    /// Requires that values must NOT be equal at the specified path(s).
    ///
    /// This is the inverse of normal matching - validation fails if the expected
    /// and actual values ARE equal. Useful for verifying that a value has changed.
    ///
    /// - Parameters:
    ///   - paths: The path(s) where values must differ.
    ///            Omit to apply at the root level.
    ///   - scope: The scope of the option. Defaults to `.singleNode`.
    /// - Returns: The builder for method chaining.
    @discardableResult
    public func valueNotEqual(at paths: JSONPath..., scope: JSONValidationScope = .singleNode) -> Self {
        return valueNotEqual(at: paths, scope: scope)
    }
    
    // MARK: - Terminal Operations
    
    /// Validates the JSON using the configured options.
    ///
    /// This method executes the validation and reports any failures as XCTest assertions.
    public func validate() {
        guard let expected = expected else {
            XCTFail("Expected is nil. If nil is expected, use XCTAssertNil instead.", file: file, line: line)
            return
        }
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        
        // Report failures
        for failure in result.failures {
            XCTFail(failure.description, file: file, line: line)
        }
    }
    
    /// Validates the JSON and returns the result without asserting.
    ///
    /// Use this when you need to check the validation result programmatically.
    ///
    /// - Returns: `true` if validation passes, `false` otherwise.
    public func check() -> Bool {
        guard let expected = expected else {
            return false
        }
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        return result.isValid
    }
    
    /// Validates the JSON and returns the detailed result.
    ///
    /// - Returns: A `ValidationResult` with details about any failures.
    public func validateWithResult() -> ValidationResult {
        guard let expected = expected else {
            return .failure(ValidationFailure(
                keyPath: "",
                message: "Expected is nil. If nil is expected, use XCTAssertNil instead."
            ))
        }
        
        return ValidationEngine.validate(expected: expected, actual: actual, config: config)
    }
}

// MARK: - XCTestCase Extension

public extension XCTestCase {
    
    /// Creates a fluent JSON assertion builder for comparing two JSON values.
    ///
    /// This is the entry point for the fluent assertion API. Chain configuration
    /// methods and call `validate()` to execute the assertion.
    ///
    /// ## Example
    ///
    /// ```swift
    /// func testAPIResponse() {
    ///     let expected = """
    ///         {"status": "ok", "items": [{"id": 1}, {"id": 2}]}
    ///         """
    ///
    ///     assertJSON(expected: expected, actual: response)
    ///         .exactMatch(at: "status")
    ///         .anyOrder(at: "items[*]")
    ///         .typeMatch(at: "items[*].id")
    ///         .validate()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - expected: The expected JSON value (can be String, Dictionary, NetworkRequest, AnyCodable, etc.)
    ///   - actual: The actual JSON value to validate
    ///   - file: The file where the assertion is made
    ///   - line: The line where the assertion is made
    /// - Returns: A builder for configuring the assertion
    func assertJSON(
        expected: AnyCodableComparable,
        actual: AnyCodableComparable?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> JSONAssertionBuilder {
        return JSONAssertionBuilder(
            expected: expected.toAnyCodable(),
            actual: actual?.toAnyCodable(),
            file: file,
            line: line
        )
    }
}
