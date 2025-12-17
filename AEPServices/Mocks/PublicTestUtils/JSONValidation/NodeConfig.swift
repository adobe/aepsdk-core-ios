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

import Foundation

/// A struct representing the configuration for a node in a tree structure.
///
/// `NodeConfig` provides a way to set configuration options for nodes in a hierarchical tree structure.
/// Each node can have its own option overrides, plus inherited defaults from parent nodes.
struct NodeConfig: Hashable {
    
    // MARK: - Nested Types
    
    /// Default values inherited from parent nodes or set at the root.
    struct Defaults: Hashable {
        var anyOrder: Bool = false
        var exactMatch: Bool = true
        var equalCount: Bool = false
        var keyMustBeAbsent: Bool = false
        var valueNotEqual: Bool = false
        
        init(
            anyOrder: Bool = false,
            exactMatch: Bool = true,
            equalCount: Bool = false,
            keyMustBeAbsent: Bool = false,
            valueNotEqual: Bool = false
        ) {
            self.anyOrder = anyOrder
            self.exactMatch = exactMatch
            self.equalCount = equalCount
            self.keyMustBeAbsent = keyMustBeAbsent
            self.valueNotEqual = valueNotEqual
        }
    }
    
    // MARK: - Properties
    
    /// The name of the node. `nil` refers to the top level object.
    var name: String?
    
    /// Node-specific option overrides. `nil` means "use default".
    var anyOrder: Bool?
    var exactMatch: Bool?
    var equalCount: Bool?
    var elementCount: Int?
    var keyMustBeAbsent: Bool?
    var valueNotEqual: Bool?
    
    /// Inherited defaults for this node and its descendants.
    var defaults: Defaults
    
    /// Child nodes indexed by their name for O(1) lookup.
    var children: [String: NodeConfig] = [:]
    
    /// The node configuration for wildcard children.
    /// Backed by an array to enable recursive value type (recursion via heap storage).
    private var _wildcardChildren: [NodeConfig] = []
    
    var wildcardChildren: NodeConfig? {
        get { _wildcardChildren.first }
        set {
            if let newValue = newValue {
                _wildcardChildren = [newValue]
            } else {
                _wildcardChildren = []
            }
        }
    }
    
    // MARK: - Resolved Accessors (for self)
    
    /// Whether array elements can match in any order.
    var isAnyOrder: Bool { anyOrder ?? defaults.anyOrder }
    
    /// Whether values must match exactly (vs just type match).
    var isExactMatch: Bool { exactMatch ?? defaults.exactMatch }
    
    /// Whether collections must have equal counts.
    var isEqualCount: Bool { equalCount ?? defaults.equalCount }
    
    /// Whether certain keys must be absent.
    var isKeyMustBeAbsent: Bool { keyMustBeAbsent ?? defaults.keyMustBeAbsent }
    
    /// Whether values must be unequal.
    var isValueNotEqual: Bool { valueNotEqual ?? defaults.valueNotEqual }
    
    // MARK: - Initialization
    
    /// Creates a new node with the given values.
    init(
        name: String? = nil,
        defaults: Defaults = Defaults()
    ) {
        self.name = name
        self.defaults = defaults
    }
    
    // MARK: - Child Access Methods
    
    func getChild(named name: String?) -> NodeConfig? {
        guard let name = name else { return nil }
        return children[name]
    }
    
    func getChild(indexed index: Int?) -> NodeConfig? {
        guard let index = index else { return nil }
        return children[String(index)]
    }
    
    // MARK: - Child Resolution (Generic Resolver)
    
    /// Returns a fully-resolved config for a child, considering the full precedence chain:
    /// 1. Child's specific settings (if child exists)
    /// 2. Parent's wildcard settings (if wildcard exists)
    /// 3. Child's defaults (if child exists) or parent's defaults
    ///
    /// This is the primary method for getting child configuration during validation.
    /// The returned config has all settings resolved - just use `isExactMatch`, `isAnyOrder`, etc.
    ///
    /// - Parameter name: The child name (key or index as string)
    /// - Returns: A NodeConfig with fully resolved settings for the child
    func resolvedChild(named name: String?) -> NodeConfig {
        let childNode = getChild(named: name)
        let wildcardNode = wildcardChildren
        
        // Start with a base config using the appropriate defaults
        var resolved = NodeConfig(
            name: name,
            defaults: childNode?.defaults ?? wildcardNode?.defaults ?? defaults
        )
        
        // Copy children structure from child or wildcard if they exist
        resolved.children = childNode?.children ?? wildcardNode?.children ?? [:]
        resolved.wildcardChildren = childNode?.wildcardChildren ?? wildcardNode?.wildcardChildren
        
        // Resolve each option using precedence: child -> wildcard -> defaults
        // Note: Parent's specific options do NOT propagate (that's for .subtree/defaults).
        resolved.anyOrder = childNode?.anyOrder ?? wildcardNode?.anyOrder
        resolved.exactMatch = childNode?.exactMatch ?? wildcardNode?.exactMatch
        resolved.equalCount = childNode?.equalCount ?? wildcardNode?.equalCount
        resolved.keyMustBeAbsent = childNode?.keyMustBeAbsent ?? wildcardNode?.keyMustBeAbsent
        resolved.valueNotEqual = childNode?.valueNotEqual ?? wildcardNode?.valueNotEqual
        
        // Element count: only inherit from child or wildcard, not parent
        // (parent's element count shouldn't apply to children)
        resolved.elementCount = childNode?.elementCount ?? wildcardNode?.elementCount
        
        return resolved
    }
    
    /// Convenience method for resolving by integer index.
    func resolvedChild(at index: Int?) -> NodeConfig {
        guard let index = index else {
            return NodeConfig(name: nil, defaults: defaults)
        }
        return resolvedChild(named: String(index))
    }
    
    // MARK: - Option Setting Methods
    
    /// Sets a boolean option at the specified path using KeyPaths.
    ///
    /// - Parameters:
    ///   - nodeKeyPath: The KeyPath to the node-specific property
    ///   - defaultsKeyPath: The KeyPath to the defaults property
    ///   - value: The boolean value to set
    ///   - path: The JSON path where the option should be applied
    ///   - scope: Whether to apply to just this node or the entire subtree
    mutating func setBoolOption(
        _ nodeKeyPath: WritableKeyPath<NodeConfig, Bool?>,
        _ defaultsKeyPath: WritableKeyPath<Defaults, Bool>,
        value: Bool,
        at path: JSONPath,
        scope: JSONValidationScope
    ) {
        navigate(to: path.components) { node in
            switch scope {
            case .singleNode:
                node[keyPath: nodeKeyPath] = value
            case .subtree:
                node.defaults[keyPath: defaultsKeyPath] = value
                node.propagateDefaultsToChildren()
            }
        }
    }
    
    /// Sets the anyOrder option at the specified path.
    mutating func setAnyOrder(_ value: Bool, at path: JSONPath, scope: JSONValidationScope) {
        setBoolOption(\.anyOrder, \.anyOrder, value: value, at: path, scope: scope)
    }
    
    /// Sets the exactMatch option at the specified path.
    mutating func setExactMatch(_ value: Bool, at path: JSONPath, scope: JSONValidationScope) {
        setBoolOption(\.exactMatch, \.exactMatch, value: value, at: path, scope: scope)
    }
    
    /// Sets the equalCount option at the specified path.
    mutating func setEqualCount(_ value: Bool, at path: JSONPath, scope: JSONValidationScope) {
        setBoolOption(\.equalCount, \.equalCount, value: value, at: path, scope: scope)
    }
    
    /// Sets the keyMustBeAbsent option at the specified path.
    mutating func setKeyMustBeAbsent(_ value: Bool, at path: JSONPath, scope: JSONValidationScope) {
        setBoolOption(\.keyMustBeAbsent, \.keyMustBeAbsent, value: value, at: path, scope: scope)
    }
    
    /// Sets the valueNotEqual option at the specified path.
    mutating func setValueNotEqual(_ value: Bool, at path: JSONPath, scope: JSONValidationScope) {
        setBoolOption(\.valueNotEqual, \.valueNotEqual, value: value, at: path, scope: scope)
    }
    
    /// Sets the elementCount option at the specified path.
    /// Note: elementCount doesn't have a subtree scope - it only applies to the specific node.
    mutating func setElementCount(_ count: Int, at path: JSONPath) {
        navigate(to: path.components) { node in
            node.elementCount = count
        }
    }
    
    // MARK: - Navigation
    
    /// Navigates to the node at the specified path components, creating nodes as needed,
    /// then applies the given mutation.
    private mutating func navigate(to components: [JSONPath.Component], apply: (inout NodeConfig) -> Void) {
        if components.isEmpty {
            apply(&self)
            return
        }
        
        var remainingComponents = components
        let component = remainingComponents.removeFirst()
        let childName = component.nodeName
        let isWildcard = component.isWildcard
        
        if isWildcard {
            // Create or update wildcard child
            if wildcardChildren == nil {
                wildcardChildren = NodeConfig(name: childName, defaults: defaults)
            }
            
            if var wildcard = wildcardChildren {
                wildcard.navigate(to: remainingComponents, apply: apply)
                wildcardChildren = wildcard
            }
            
            // Also apply to all existing children
            for childKey in children.keys {
                children[childKey]?.navigate(to: remainingComponents, apply: apply)
            }
        } else {
            // Create or update specific child
            ensureChild(named: childName)
            children[childName]?.navigate(to: remainingComponents, apply: apply)
        }
    }
    
    /// Ensures a child with the given name exists, creating it if necessary.
    private mutating func ensureChild(named name: String) {
        if children[name] != nil { return }
        
        // If a wildcard child exists, use it as a template
        if let template = wildcardChildren {
            var newChild = template
            newChild.name = name
            children[name] = newChild
        } else {
            children[name] = NodeConfig(name: name, defaults: defaults)
        }
    }
    
    /// Propagates current defaults to all children.
    private mutating func propagateDefaultsToChildren() {
        if var wildcard = wildcardChildren {
            wildcard.defaults = defaults
            wildcard.propagateDefaultsToChildren()
            wildcardChildren = wildcard
        }
        
        for childKey in children.keys {
            children[childKey]?.defaults = defaults
            children[childKey]?.propagateDefaultsToChildren()
        }
    }
}

// MARK: - CustomStringConvertible

extension NodeConfig: CustomStringConvertible {
    var description: String {
        return describeNode(indentation: 0)
    }
    
    private func describeNode(indentation: Int) -> String {
        var result = indentation == 0 ? "\n" : ""
        let indent = String(repeating: "  ", count: indentation)
        
        result += "\(indent)Name: \(name ?? "<Unnamed>")\n"
        
        // Show resolved options
        var activeOptions: [String] = []
        if isAnyOrder { activeOptions.append("anyOrder") }
        if isExactMatch { activeOptions.append("exactMatch") }
        if isEqualCount { activeOptions.append("equalCount") }
        if isKeyMustBeAbsent { activeOptions.append("keyMustBeAbsent") }
        if let count = elementCount { activeOptions.append("elementCount(\(count))") }
        
        if activeOptions.isEmpty {
            result += "\(indent)Options: (defaults)\n"
        } else {
            result += "\(indent)Options: \(activeOptions.joined(separator: ", "))\n"
        }
        
        // Children
        if !children.isEmpty {
            result += "\(indent)Children:\n"
            for (_, child) in children.sorted(by: { $0.key < $1.key }) {
                result += child.describeNode(indentation: indentation + 1)
            }
        }
        if let wildcardChildren = wildcardChildren {
            result += "\(indent)Wildcard:\n"
            result += wildcardChildren.describeNode(indentation: indentation + 1)
        }
        
        return result
    }
}
