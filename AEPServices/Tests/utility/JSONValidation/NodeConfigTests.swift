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
@testable import AEPServicesMocks

class NodeConfigTests: XCTestCase {

    // MARK: - Option Storage Tests

    /// NodeConfig stores option overrides and exposes them via resolved accessors.
    func testOptionStorage_StoresValuesCorrectly() {
        // Given
        var config = NodeConfig()
        
        // Then (initial)
        XCTAssertNil(config.exactMatch)
        XCTAssertNil(config.anyOrder)
        
        // When
        config.exactMatch = false
        config.anyOrder = true
        
        // Then
        XCTAssertEqual(config.exactMatch, false)
        XCTAssertEqual(config.anyOrder, true)
        XCTAssertFalse(config.isExactMatch)
        XCTAssertTrue(config.isAnyOrder)
    }

    // MARK: - Defaults Inheritance Tests

    /// When no overrides are set, resolved accessors fall back to `defaults`.
    func testDefaultsInheritance_UsesDefaultsWhenNil() {
        // Given
        let defaults = NodeConfig.Defaults(anyOrder: false, exactMatch: true)
        let config = NodeConfig(defaults: defaults)
        
        // Then
        XCTAssertNil(config.exactMatch)
        XCTAssertTrue(config.isExactMatch)
        XCTAssertFalse(config.isAnyOrder)
    }

    /// Resolved child defaults follow: child defaults > wildcard defaults > parent defaults.
    func testDefaultsInheritance_ResolvedDefaultsPreferChildOverWildcardOverParent() {
        // Given
        let parentDefaults = NodeConfig.Defaults(anyOrder: false, exactMatch: true)
        var parent = NodeConfig(defaults: parentDefaults)

        parent.wildcardChildren = NodeConfig(defaults: NodeConfig.Defaults(anyOrder: false, exactMatch: false))

        parent.children["child"] = NodeConfig(name: "child", defaults: NodeConfig.Defaults(anyOrder: true, exactMatch: true))

        // When
        let resolved = parent.resolvedChild(named: "child")

        // Then
        XCTAssertTrue(resolved.isExactMatch, "Resolved child should inherit exactMatch from the child defaults")
        XCTAssertTrue(resolved.isAnyOrder, "Resolved child should inherit anyOrder from the child defaults")
    }

    /// When the child does not exist, resolved child defaults fall back to wildcard defaults.
    func testDefaultsInheritance_ResolvedDefaultsFallBackToWildcardWhenChildMissing() {
        // Given
        let parentDefaults = NodeConfig.Defaults(anyOrder: false, exactMatch: true)
        var parent = NodeConfig(defaults: parentDefaults)
        parent.wildcardChildren = NodeConfig(defaults: NodeConfig.Defaults(anyOrder: true, exactMatch: false))

        // When
        let resolved = parent.resolvedChild(named: "missingChild")

        // Then
        XCTAssertFalse(resolved.isExactMatch, "Resolved child should inherit exactMatch from wildcard defaults when child is missing")
        XCTAssertTrue(resolved.isAnyOrder, "Resolved child should inherit anyOrder from wildcard defaults when child is missing")
    }

    /// When neither child nor wildcard exist, resolved child defaults fall back to the parent defaults.
    func testDefaultsInheritance_ResolvedDefaultsFallBackToParentWhenNoChildOrWildcard() {
        // Given
        let parentDefaults = NodeConfig.Defaults(anyOrder: false, exactMatch: false)
        let parent = NodeConfig(defaults: parentDefaults)

        // When
        let resolved = parent.resolvedChild(named: "missingChild")

        // Then
        XCTAssertFalse(resolved.isExactMatch, "Resolved child should inherit exactMatch from parent defaults when no wildcard exists")
        XCTAssertFalse(resolved.isAnyOrder, "Resolved child should inherit anyOrder from parent defaults when no wildcard exists")
    }

    // MARK: - Navigation & Mutation Tests

    /// Setting an option at a deep path creates the intermediate nodes and sets the leaf value.
    func testSetOption_CreatesPathAndSetsValue() {
        // Given
        var root = NodeConfig()
        let path: JSONPath = "users[0].name"
        
        // When
        root.setExactMatch(false, at: path, scope: .singleNode)
        
        // Then
        guard let users = root.getChild(named: "users"),
              let index0 = users.getChild(indexed: 0),
              let name = index0.getChild(named: "name") else {
            XCTFail("Failed to navigate to created node")
            return
        }
        
        XCTAssertEqual(name.exactMatch, false)
        XCTAssertNil(users.exactMatch)
        XCTAssertNil(index0.exactMatch)
    }

    // MARK: - Resolution Precedence Tests
    
    // Precedence: child option > wildcard option > defaults (for resolved values)

    /// A child option override takes precedence over wildcard and parent options.
    func testResolution_ChildOverridesEverything() {
        // Given
        var parent = NodeConfig()
        parent.exactMatch = true
        parent.wildcardChildren = NodeConfig()
        parent.wildcardChildren?.exactMatch = true
        
        var child = NodeConfig(name: "child")
        child.exactMatch = false
        parent.children["child"] = child
        
        // When
        let resolved = parent.resolvedChild(named: "child")

        // Then
        XCTAssertFalse(resolved.isExactMatch, "Child specific override should win")
    }

    /// A wildcard option override takes precedence over parent options when the child has no explicit option.
    func testResolution_WildcardOverridesParent() {
        // Given
        var parent = NodeConfig()
        parent.exactMatch = true
        
        parent.wildcardChildren = NodeConfig()
        parent.wildcardChildren?.exactMatch = false
        
        let child = NodeConfig(name: "child")
        parent.children["child"] = child
        
        // When
        let resolved = parent.resolvedChild(named: "child")

        // Then
        XCTAssertFalse(resolved.isExactMatch, "Wildcard setting should override parent")
    }

    /// A parent option override takes precedence over the parent's defaults.
    func testResolution_ParentOverridesDefault() {
        // Given
        let defaults = NodeConfig.Defaults(exactMatch: false)
        var parent = NodeConfig(defaults: defaults)
        parent.exactMatch = true
        
        let child = NodeConfig(name: "child")
        parent.children["child"] = child
        
        // When
        let resolved = parent.resolvedChild(named: "child")

        // Then
        XCTAssertTrue(resolved.isExactMatch, "Parent setting should override defaults")
    }
    
    /// With no parent/wildcard/child option override, resolved values fall back to defaults.
    func testResolution_FallsBackToDefault() {
        // Given
        let defaults = NodeConfig.Defaults(exactMatch: true)
        var parent = NodeConfig(defaults: defaults)
        
        let child = NodeConfig(name: "child")
        parent.children["child"] = child
        
        // When
        let resolved = parent.resolvedChild(named: "child")

        // Then
        XCTAssertTrue(resolved.isExactMatch, "Should fall back to defaults")
    }

    // MARK: - Wildcard Creation Tests

    /// Setting an option on a wildcard path creates a wildcard node and its descendants.
    func testSetOption_WithWildcardPath_CreatesWildcardNode() {
        // Given
        var root = NodeConfig()
        let path: JSONPath = "items[*].id"
        
        // When
        root.setExactMatch(false, at: path, scope: .singleNode)
        
        // Then
        guard let items = root.getChild(named: "items") else {
            XCTFail("Items node not created")
            return
        }
        
        guard let wildcard = items.wildcardChildren else {
            XCTFail("Wildcard child not created")
            return
        }
        
        guard let id = wildcard.getChild(named: "id") else {
            XCTFail("ID node not created under wildcard")
            return
        }
        
        XCTAssertEqual(id.exactMatch, false)
    }
    
    /// Wildcard configuration applies to non-existent children during resolution.
    func testResolve_WildcardAppliesToNonExistentChild() {
        // Given
        var root = NodeConfig()
        let path: JSONPath = "items[*]"
        root.setExactMatch(false, at: path, scope: .singleNode)
        
        // When
        let items = root.resolvedChild(named: "items")
        let index0 = items.resolvedChild(at: 0)
        
        // Then
        XCTAssertFalse(index0.isExactMatch)
    }

    // MARK: - Scope Tests

    /// Subtree scope updates a node's defaults so its descendants inherit the option.
    func testSetOption_SubtreeScope_PropagatesToDefaults() {
        // Given
        var root = NodeConfig()
        let path: JSONPath = "users"
        
        // When
        root.setExactMatch(false, at: path, scope: .subtree)
        
        // Then
        let users = root.resolvedChild(named: "users")
        
        XCTAssertNil(users.exactMatch)
        XCTAssertFalse(users.defaults.exactMatch)
        XCTAssertFalse(users.isExactMatch)
        
        let child = users.resolvedChild(named: "anyChild")
        XCTAssertFalse(child.isExactMatch)
    }
}

