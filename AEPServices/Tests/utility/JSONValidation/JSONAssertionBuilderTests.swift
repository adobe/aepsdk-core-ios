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

class JSONAssertionBuilderTests: XCTestCase {

    // MARK: - Chaining & Path Resolution

    /// Applying `anyOrder` to a wildcard element path (`items[*]`) allows array reordering during comparison.
    func testBuilder_AnyOrder_SetsConfigCorrectly() {
        let builder = JSONAssertionBuilder(expected: nil, actual: nil, file: #file, line: #line)
        builder.anyOrder(at: "items[*]")

        // Given
        let expected = AnyCodable(["items": [1, 2]])
        let actual = AnyCodable(["items": [2, 1]])

        // When / Then
        let strictBuilder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
        XCTAssertFalse(strictBuilder.check())

        let looseBuilder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "items[*]")
        XCTAssertTrue(looseBuilder.check())
    }

    // MARK: - Modifier Ordering (Last Call Wins)

    /// When multiple modifiers set conflicting options for the same path, the last modifier wins.
    func testBuilder_ModifierOrder_LastCallWins_ValueMatching() {
        // Given
        let expected = AnyCodable(["id": 1])
        let actual = AnyCodable(["id": 2])

        // When / Then
        // When: relax matching to type-only, then re-tighten to exact at the same path.
        let exactWins = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "id")
            .exactMatch(at: "id")
        XCTAssertFalse(exactWins.check(), "Last call should win; exactMatch should make this fail")

        // When: tighten to exact, then relax to type-only at the same path.
        let typeWins = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .exactMatch(at: "id")
            .typeMatch(at: "id")
        XCTAssertTrue(typeWins.check(), "Last call should win; typeMatch should make this pass")
    }

    /// When multiple modifiers set conflicting count rules for the same collection, the last modifier wins.
    func testBuilder_ModifierOrder_LastCallWins_CountRules() {
        // Given
        let expected = AnyCodable(["items": [1]])
        let actual = AnyCodable(["items": [1, 2]])

        // When / Then
        // When: enforce equalCount, then relax back to flexibleCount for the same path.
        let flexibleWins = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .equalCount(at: "items")
            .flexibleCount(at: "items")
        XCTAssertTrue(flexibleWins.check(), "Last call should win; flexibleCount should allow extra elements")

        // When: relax to flexibleCount, then re-tighten to equalCount for the same path.
        let equalWins = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .flexibleCount(at: "items")
            .equalCount(at: "items")
        XCTAssertFalse(equalWins.check(), "Last call should win; equalCount should reject extra elements")
    }

    /// When multiple modifiers set conflicting ordering rules for the same array elements, the last modifier wins.
    func testBuilder_ModifierOrder_LastCallWins_ArrayOrdering() {
        // Given
        let expected = AnyCodable(["items": [1, 2]])
        let actual = AnyCodable(["items": [2, 1]])

        // When / Then
        // When: allow anyOrder at the element level, then override back to strict ordering.
        let strictWins = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "items[*]")
            .strictOrder(at: "items[*]")
        XCTAssertFalse(strictWins.check(), "Last call should win; strictOrder should make this fail")

        // When: enforce strict ordering, then relax to anyOrder.
        let anyOrderWins = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .strictOrder(at: "items[*]")
            .anyOrder(at: "items[*]")
        XCTAssertTrue(anyOrderWins.check(), "Last call should win; anyOrder should allow reordering")
    }
    
    // MARK: - AnyOrder Propagation Behavior

    /// `anyOrder` on an array container (`items`) does not apply to its elements unless a wildcard is used.
    func testAnyOrder_OnContainer_DoesNotAffectElements() {
        // Given
        let expected = AnyCodable(["items": [1, 2]])
        let actual = AnyCodable(["items": [2, 1]])
        
        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "items")
        
        // Then
        XCTAssertFalse(builder.check(), "anyOrder on container should not relax element ordering")
    }

    /// `anyOrder` on a wildcard element path (`items[*]`) applies to all elements and allows reordering.
    func testAnyOrder_OnWildcard_AffectsAllElements() {
        // Given
        let expected = AnyCodable(["items": [1, 2]])
        let actual = AnyCodable(["items": [2, 1]])
        
        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "items[*]")
        
        // Then
        XCTAssertTrue(builder.check(), "anyOrder on wildcard should allow reordering")
    }

    /// `anyOrder` applied to a specific index only affects that element and does not relax ordering for siblings.
    func testAnyOrder_OnSpecificIndex_AffectsOnlyThatElement() {
        // Given
        let expected = AnyCodable(["items": [1, 2]])
        let actual = AnyCodable(["items": [2, 1]])
        
        // When / Then
        // When: relax ordering for only `items[0]` (not the entire array).
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "items[0]")
        XCTAssertFalse(builder.check(), "Partial anyOrder should not allow global reordering")

        // Given (order already matches)
        let passingBuilder = JSONAssertionBuilder(expected: expected, actual: expected, file: #file, line: #line)
            .anyOrder(at: "items[0]")
        XCTAssertTrue(passingBuilder.check(), "Should pass when order matches regardless of flag")

        // When (explicitly relax all indices)
        // When: relax ordering for every element (equivalent to `items[*]` behavior).
        let explicitAllBuilder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "items[0]")
            .anyOrder(at: "items[1]")
        XCTAssertTrue(explicitAllBuilder.check(), "Explicitly setting all indices to anyOrder should pass")
    }
    
    // MARK: - Propagation Logic Tests
    
    /// Single-node config applied to a parent does not affect children unless the scope is `.subtree`.
    func testBuilder_ParentConfig_DoesNotPropagateToChildren() {
        // Given
        let expected = AnyCodable(["container": ["child": 123]])
        let actual = AnyCodable(["container": ["child": 456]])
        
        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "container")
        
        // Then
        XCTAssertFalse(builder.check(), "Parent-only config should not propagate to children")
    }
    
    /// Subtree-scoped config becomes the default for all descendants.
    func testBuilder_Defaults_PropagateToChildren() {
        // Given
        let expected = AnyCodable(["container": ["child": 123]])
        let actual = AnyCodable(["container": ["child": 456]])

        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "container", scope: .subtree)
        
        // Then
        XCTAssertTrue(builder.check(), "Subtree scope defaults should propagate to children")
    }
    
    /// Wildcard config applies to all matching array elements.
    func testBuilder_Wildcard_PropagatesToMatchingChildren() {
        // Given
        let expected = AnyCodable(["items": [123, 456]])
        let actualDiffValues = AnyCodable(["items": [999, 888]])
        
        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actualDiffValues, file: #file, line: #line)
            .typeMatch(at: "items[*]")
        
        // Then
        XCTAssertTrue(builder.check(), "Wildcard config should apply to all array elements")
    }
    
    /// More specific child config overrides a wildcard config.
    func testBuilder_ChildOverride_TakesPrecedence() {
        // Given
        let expected = AnyCodable(["items": [1, 2]])
        let actual = AnyCodable(["items": [9, 2]])
        
        // When / Then
        // When: apply relaxed defaults to all items, then override index 0 to be strict.
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "items[*]")
            .exactMatch(at: "items[0]")
        
        XCTAssertFalse(builder.check(), "Child specific config should override wildcard")
        
        // Given (inverse: strict wildcard, relaxed child)
        // When: apply strict defaults to all items, then relax index 0 to be type-only matching.
        let builder2 = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .exactMatch(at: "items[*]") // redundant (default), but explicit for readability
            .typeMatch(at: "items[0]")
        
        XCTAssertTrue(builder2.check(), "Child specific config should override strict wildcard")
    }
    
    // MARK: - Complex Inheritance Tests
    
    /// Mixed inheritance: subtree defaults from a wildcard can be overridden at an intermediate node.
    func testBuilder_ComplexInheritance_WildcardSubtree_WithMiddleOverride() {
        // Given
        // `val` differs to prove `typeMatch` is inherited to descendants.
        // `nested` exists to prove `equalCount` continues to apply below the middle override.
        let expected = AnyCodable(["items": [["val": 1, "nested": ["k": 1]]]])
        let actual = AnyCodable(["items": [["val": 2, "extra": 3, "nested": ["k": 9]]]])
        
        // When
        // When: enforce subtree defaults under `items[*]` (type-only + equalCount),
        // but relax count at `items[0]` so extra keys there do not fail validation.
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "items[*]", scope: .subtree)
            .equalCount(at: "items[*]", scope: .subtree)
            .flexibleCount(at: "items[0]", scope: .singleNode)
            
        // Then
        XCTAssertTrue(builder.check(), "`items[0].extra` should be allowed, while `val` is type-matched")

        // And: `equalCount` still applies below the middle override.
        // If a descendant collection has an extra key, it should fail.
        let actualFailingNested = AnyCodable(["items": [["val": 2, "extra": 3, "nested": ["k": 9, "extra2": 10]]]])
        let failingBuilder = JSONAssertionBuilder(expected: expected, actual: actualFailingNested, file: #file, line: #line)
            .typeMatch(at: "items[*]", scope: .subtree)
            .equalCount(at: "items[*]", scope: .subtree)
            .flexibleCount(at: "items[0]", scope: .singleNode)
        let failingResult = failingBuilder.validateWithResult()
        XCTAssertFalse(failingResult.isValid)
        XCTAssertTrue(
            failingResult.failures.contains { failure in
                failure.keyPath == "items[0].nested" &&
                failure.message.contains("count does not match")
            },
            "Expected an equalCount failure at items[0].nested; failures were: \(failingResult.failures)"
        )
    }
    
    /// Mixed inheritance without wildcards: subtree defaults at an ancestor can be overridden at a middle node.
    func testBuilder_ComplexInheritance_PlainHierarchy_WithMiddleOverride() {
        // Given
        // `leaf` differs to prove `typeMatch` is inherited to descendants.
        // `nested` exists to prove `equalCount` continues to apply below the middle override.
        let expected = AnyCodable(["root": ["middle": ["leaf": 1, "nested": ["k": 1]]]])
        let actualPassing = AnyCodable(["root": ["middle": ["leaf": 2, "extra": 3, "nested": ["k": 9]]]])
        
        // When
        // When: enforce subtree defaults under `root` (type-only + equalCount),
        // but relax count at `root.middle` so extra keys there do not fail validation.
        let builder = JSONAssertionBuilder(expected: expected, actual: actualPassing, file: #file, line: #line)
            .typeMatch(at: "root", scope: .subtree)
            .equalCount(at: "root", scope: .subtree)
            .flexibleCount(at: "root.middle", scope: .singleNode)
            
        // Then
        XCTAssertTrue(builder.check(), "`root.middle.extra` should be allowed, while `leaf` is type-matched")

        // And: `equalCount` still applies below the middle override.
        let actualFailingNested = AnyCodable(["root": ["middle": ["leaf": 2, "extra": 3, "nested": ["k": 9, "extra2": 10]]]])
        let failingBuilder = JSONAssertionBuilder(expected: expected, actual: actualFailingNested, file: #file, line: #line)
            .typeMatch(at: "root", scope: .subtree)
            .equalCount(at: "root", scope: .subtree)
            .flexibleCount(at: "root.middle", scope: .singleNode)
        let failingResult = failingBuilder.validateWithResult()
        XCTAssertFalse(failingResult.isValid)
        XCTAssertTrue(
            failingResult.failures.contains { failure in
                failure.keyPath == "root.middle.nested" &&
                failure.message.contains("count does not match")
            },
            "Expected an equalCount failure at root.middle.nested; failures were: \(failingResult.failures)"
        )
    }
    
    /// Wildcard path `[*]` can address top-level array elements.
    func testBuilder_TopLevelArray_WildcardPath() {
        // Given
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([2, 1])
        
        // When / Then
        XCTAssertFalse(JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line).check())
        
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "[*]")
            
        XCTAssertTrue(builder.check(), "Top-level array children should be addressable via '[*]'")
    }
    
    // MARK: - Nested Subtree Overrides
    
    /// Nearest subtree config (including wildcard subtrees) should win for deeply nested descendants.
    func testBuilder_NestedWildcardSubtree_Override() {
        // Given
        let expected = AnyCodable(["items": [["subitems": [["val": 1]]]]])
        let actual = AnyCodable(["items": [["subitems": [["val": 2]]]]])
        
        // When
        // When: make `items[*]` strict, but re-relax under `items[*].subitems[*]` so the leaf uses type-only matching.
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "items", scope: .subtree)
            .exactMatch(at: "items[*]", scope: .subtree)
            .typeMatch(at: "items[*].subitems[*]", scope: .subtree)
            
        // Then
        XCTAssertTrue(builder.check(), "Leaf should follow the nearest ancestor subtree config (Relaxed)")
        
        // And: removing the nearest override should fall back to the strict wildcard subtree.
        // When: remove the subitems override so the leaf inherits strict matching from `items[*]`.
        let strictBuilder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "items", scope: .subtree)
            .exactMatch(at: "items[*]", scope: .subtree)
            
        XCTAssertFalse(strictBuilder.check(), "Leaf should fail if nearest ancestor config is Strict")
    }
    
    /// Nearest plain (non-wildcard) subtree config should win for deeply nested descendants.
    func testBuilder_NestedPlainSubtree_Override() {
        // Given
        let expected = AnyCodable(["root": ["level1": ["level2": ["leaf": 1]]]])
        let actual = AnyCodable(["root": ["level1": ["level2": ["leaf": 2]]]])
        
        // When
        // When: make `root.level1` strict, then re-relax under `root.level1.level2` so the leaf uses type-only matching.
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "root", scope: .subtree)
            .exactMatch(at: "root.level1", scope: .subtree)
            .typeMatch(at: "root.level1.level2", scope: .subtree)
            
        // Then
        XCTAssertTrue(builder.check(), "Leaf should follow nearest plain ancestor subtree config")
    }
    
    /// When both apply, wildcard subtree defaults take precedence over a parent plain subtree config.
    func testBuilder_PlainSubtree_OverriddenBy_WildcardSubtree() {
        // Given
        let expected = AnyCodable(["items": [["leaf": 1]]])
        let actual = AnyCodable(["items": [["leaf": 2]]])
        
        // When
        // When: set strict defaults at the parent (`items`), then relax for all children via wildcard (`items[*]`).
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .exactMatch(at: "items", scope: .subtree)
            .typeMatch(at: "items[*]", scope: .subtree)
            
        // Then
        XCTAssertTrue(builder.check(), "Wildcard subtree config should override Parent plain config")
    }
    
    /// A specific child subtree config takes precedence over a wildcard subtree config.
    func testBuilder_WildcardSubtree_OverriddenBy_PlainSubtree() {
        // Given
        let expected = AnyCodable(["items": [["leaf": 1]]])
        let actual = AnyCodable(["items": [["leaf": 2]]])
        
        // When
        // When: set strict defaults for all children via wildcard (`items[*]`), then relax for a specific child (`items[0]`).
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .exactMatch(at: "items[*]", scope: .subtree)
            .typeMatch(at: "items[0]", scope: .subtree)
            
        // Then
        XCTAssertTrue(builder.check(), "Specific child subtree config should override Wildcard config")
    }

    /// `typeMatch` at a specific path relaxes value comparison to type-only matching.
    func testBuilder_TypeMatch_SetsConfigCorrectly() {
        // Given
        let expected = AnyCodable(["id": 123])
        let actual = AnyCodable(["id": 456])
        
        // When / Then
        XCTAssertFalse(JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line).check())
        
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "id")
        
        XCTAssertTrue(builder.check())
    }

    /// `equalCount` enforces strict key/element count matching.
    func testBuilder_EqualCount_SetsConfigCorrectly() {
        // Given
        let expected = AnyCodable([1])
        let actual = AnyCodable([1, 2])
        
        // When / Then
        XCTAssertTrue(JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line).check())
        
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .equalCount(at: []) // Root
        
        XCTAssertFalse(builder.check())
    }

    /// `keyMustBeAbsent` fails when the specified key exists in the actual JSON.
    func testBuilder_KeyMustBeAbsent_SetsConfigCorrectly() {
        // Given
        let actual = AnyCodable(["deleted": true])
        
        // When
        let builder = JSONAssertionBuilder(expected: nil, actual: actual, file: #file, line: #line)
            .keyMustBeAbsent(at: "deleted")
        
        // Then
        XCTAssertFalse(builder.check())
    }

    /// `valueNotEqual` fails when expected and actual are equal at the configured path.
    func testBuilder_ValueNotEqual_SetsConfigCorrectly() {
        // Given
        let expected = AnyCodable("same")
        let actual = AnyCodable("same")
        
        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .valueNotEqual(at: [])
        
        // Then
        XCTAssertFalse(builder.check())
    }

    // MARK: - Scopes

    /// `.subtree` scope applies the config to the node and all descendants.
    func testBuilder_ScopeSubtree_AppliesToDescendants() {
        // Given
        let expected = AnyCodable(["a": 1, "b": ["c": 2]])
        let actual = AnyCodable(["a": 9, "b": ["c": 8]])
        
        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: [], scope: .subtree)
        
        // Then
        XCTAssertTrue(builder.check())
    }

    /// `.singleNode` scope applies the config only to that node, not its children.
    func testBuilder_ScopeSingleNode_DoesNotPropagate() {
        // Given
        let expected = AnyCodable(["a": 1, "b": 2])
        let actual = AnyCodable(["a": 9, "b": 9])
        
        // When
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "a", scope: .singleNode)
        
        // Then
        let result = builder.validateWithResult()
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.contains { $0.keyPath.contains("b") })
        XCTAssertFalse(result.failures.contains { $0.keyPath.contains("a") })
    }

    // MARK: - Validation Execution

    /// `check()` and `validateWithResult()` both report success when the JSON matches.
    func testValidate_ReturnsSuccess_WhenValid() {
        // Given
        let expected = AnyCodable("test")
        let actual = AnyCodable("test")
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
        
        // When / Then
        XCTAssertTrue(builder.check())
        
        let result = builder.validateWithResult()
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.failures.isEmpty)
    }

    /// `check()` and `validateWithResult()` both report failure when the JSON does not match.
    func testValidate_ReturnsFailure_WhenInvalid() {
        // Given
        let expected = AnyCodable("test")
        let actual = AnyCodable("mismatch")
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
        
        // When / Then
        XCTAssertFalse(builder.check())
        
        let result = builder.validateWithResult()
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.failures.isEmpty)
    }
}
