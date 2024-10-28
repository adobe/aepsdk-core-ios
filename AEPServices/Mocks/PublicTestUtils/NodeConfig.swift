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

import XCTest

/// A protocol that defines a multi-path configuration.
///
/// This protocol provides the necessary properties to configure multiple paths
/// within a node configuration context. It is designed to be used where multiple
/// paths need to be specified along with associated configuration options.
public protocol MultiPathConfig {
    /// An array of optional strings representing the paths to be configured. Each string in the array represents a distinct path. `nil` indicates the top level object.
    var paths: [String?] { get }
    /// A `NodeConfig.OptionKey` value that specifies the type of option applied to the paths.
    var optionKey: NodeConfig.OptionKey { get }
    /// A Boolean value indicating whether the configuration is active.
    var config: NodeConfig.Config { get }
    /// A `NodeConfig.Scope` value defining the scope of the configuration, such as whether it is applied to a single node or a subtree.
    var scope: NodeConfig.Scope { get }
}

/// A structure representing the configuration for a single path.
///
/// This structure is used to define the configuration details for a specific path within
/// a node configuration context. It encapsulates the path's specific options and settings.
struct PathConfig {
    ///  An optional String representing the path to be configured. `nil` indicates the top level object.
    var path: String?
    /// A `NodeConfig.OptionKey` value that specifies the type of option applied to the path.
    var optionKey: NodeConfig.OptionKey
    /// A Boolean value indicating whether the configuration is active.
    var config: NodeConfig.Config
    /// A `NodeConfig.Scope` value defining the scope of the configuration, such as whether it is applied to a single node or a subtree.
    var scope: NodeConfig.Scope
}

/// Validation option which specifies: Array elements from `expected` may match elements from `actual` regardless of index position.
/// When combining any position option indexes and standard indexes, standard indexes are validated first.
public struct AnyOrderMatch: MultiPathConfig {
    public let paths: [String?]
    public let optionKey: NodeConfig.OptionKey = .anyOrderMatch
    public let config: NodeConfig.Config
    public let scope: NodeConfig.Scope

    /// Initializes a new instance with an array of paths.
    public init(paths: [String?] = [nil], isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        self.paths = paths
        self.config = NodeConfig.Config(isActive: isActive)
        self.scope = scope
    }

    /// Variadic initializer allowing multiple string paths.
    public init(paths: String?..., isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        let finalPaths = paths.isEmpty ? [nil] : paths
        self.init(paths: finalPaths, isActive: isActive, scope: scope)
    }
}

/// Validation option which specifies: Collections (objects and/or arrays) must have the same number of elements.
public struct CollectionEqualCount: MultiPathConfig {
    public let paths: [String?]
    public let optionKey: NodeConfig.OptionKey = .collectionEqualCount
    public let config: NodeConfig.Config
    public let scope: NodeConfig.Scope

    /// Initializes a new instance with an array of paths.
    public init(paths: [String?] = [nil], isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        self.paths = paths
        self.config = NodeConfig.Config(isActive: isActive)
        self.scope = scope
    }

    /// Variadic initializer allowing multiple string paths.
    public init(paths: String?..., isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        let finalPaths = paths.isEmpty ? [nil] : paths
        self.init(paths: finalPaths, isActive: isActive, scope: scope)
    }
}

/// Validation option which specifies: The given number of elements (dictionary keys and array elements)
/// must be present.
public struct ElementCount: MultiPathConfig {
    public let paths: [String?]
    public let optionKey: NodeConfig.OptionKey = .elementCount
    public let config: NodeConfig.Config
    public let scope: NodeConfig.Scope

    /// Initializes a new instance with an array of paths.
    public init(paths: [String?] = [nil], requiredCount: Int?, isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        self.paths = paths
        self.config = NodeConfig.Config(isActive: isActive, elementCount: requiredCount)
        self.scope = scope
    }

    /// Variadic initializer allowing multiple string paths.
    public init(paths: String?..., requiredCount: Int?, isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        let finalPaths = paths.isEmpty ? [nil] : paths
        self.init(paths: finalPaths, requiredCount: requiredCount, isActive: isActive, scope: scope)
    }
}

/// Validation option which specifies: `actual` must not have the key name specified.
public struct KeyMustBeAbsent: MultiPathConfig {
    public let paths: [String?]
    public let optionKey: NodeConfig.OptionKey = .keyMustBeAbsent
    public let config: NodeConfig.Config
    public let scope: NodeConfig.Scope

    /// Initializes a new instance with an array of paths.
    public init(paths: [String?] = [nil], isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        self.paths = paths
        self.config = NodeConfig.Config(isActive: isActive)
        self.scope = scope
    }

    /// Variadic initializer allowing multiple string paths.
    public init(paths: String?..., isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        let finalPaths = paths.isEmpty ? [nil] : paths
        self.init(paths: finalPaths, isActive: isActive, scope: scope)
    }
}

/// Validation option which specifies: values must have the same type but the literal values must not be equal.
public struct ValueNotEqual: MultiPathConfig {
    public let paths: [String?]
    public let optionKey: NodeConfig.OptionKey = .valueNotEqual
    public let config: NodeConfig.Config
    public let scope: NodeConfig.Scope

    /// Initializes a new instance with an array of paths.
    public init(paths: [String?] = [nil], isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        self.paths = paths
        self.config = NodeConfig.Config(isActive: isActive)
        self.scope = scope
    }

    /// Variadic initializer allowing multiple string paths.
    public init(paths: String?..., isActive: Bool = true, scope: NodeConfig.Scope = .singleNode) {
        let finalPaths = paths.isEmpty ? [nil] : paths
        self.init(paths: finalPaths, isActive: isActive, scope: scope)
    }
}

/// Validation option which specifies: values must have the same type and literal value
public struct ValueExactMatch: MultiPathConfig {
    public let paths: [String?]
    public let optionKey: NodeConfig.OptionKey = .primitiveExactMatch
    public let config: NodeConfig.Config = NodeConfig.Config(isActive: true)
    public let scope: NodeConfig.Scope

    /// Initializes a new instance with an array of paths.
    public init(paths: [String?] = [nil], scope: NodeConfig.Scope = .singleNode) {
        self.paths = paths
        self.scope = scope
    }

    /// Variadic initializer allowing multiple string paths.
    public init(paths: String?..., scope: NodeConfig.Scope = .singleNode) {
        let finalPaths = paths.isEmpty ? [nil] : paths
        self.init(paths: finalPaths, scope: scope)
    }
}

/// Validation option which specifies: values must have the same type but their literal values can be different.
public struct ValueTypeMatch: MultiPathConfig {
    public let paths: [String?]
    public let optionKey: NodeConfig.OptionKey = .primitiveExactMatch
    public let config: NodeConfig.Config = NodeConfig.Config(isActive: false)
    public let scope: NodeConfig.Scope

    /// Initializes a new instance with an array of paths.
    public init(paths: [String?] = [nil], scope: NodeConfig.Scope = .singleNode) {
        self.paths = paths
        self.scope = scope
    }

    /// Variadic initializer allowing multiple string paths.
    public init(paths: String?..., scope: NodeConfig.Scope = .singleNode) {
        let finalPaths = paths.isEmpty ? [nil] : paths
        self.init(paths: finalPaths, scope: scope)
    }
}

/// A class representing the configuration for a node in a tree structure.
///
/// `NodeConfig` provides a way to set configuration options for nodes in a hierarchical tree structure.
/// It supports different types of configuration options, including options that apply to individual nodes
/// or to entire subtrees.
public class NodeConfig: Hashable { // swiftlint:disable:this type_body_length
    /// Represents the scope of the configuration; that is, to which nodes the configuration applies.
    public enum Scope: String, Hashable {
        /// Only this node should apply the current configuration.
        case singleNode
        /// This node and all descendants should apply the current configuration.
        case subtree
    }

    /// Defines the types of configuration options available for nodes.
    public enum OptionKey: String, Hashable, CaseIterable {
        case anyOrderMatch
        case collectionEqualCount
        case elementCount
        case keyMustBeAbsent
        case primitiveExactMatch
        case valueNotEqual
    }

    /// Represents the configuration details for a comparison option
    public struct Config: Hashable {
        /// Flag that controls if the option is active or not.
        var isActive: Bool
        var elementCount: Int?
    }

    public enum NodeOption {
        case option(OptionKey, Config, Scope)
    }

    struct PathComponent: Equatable {
        var name: String?
        /// Flag that controls if this path component is an array index
        var isArray: Bool
        /// Flag that controls if this path component is a wildcard
        var isWildcard: Bool
    }

    /// An string representing the name of the node. `nil` refers to the top level object
    var name: String?
    /// Options set specifically for this node. Specific `OptionKey`s may or may not be present - it is optional.
    var options: [OptionKey: Config] = [:]
    /// Options set for the subtree, used as the default option when no node-specific options are set. All `OptionKey`s MUST be
    /// present.
    var subtreeOptions: [OptionKey: Config] = [:]

    /// The set of child nodes.
    var children: Set<NodeConfig>
    /// The node configuration for wildcard children
    var wildcardChildren: NodeConfig?

    // Property accessors for each option which use the `options` set for the current node
    // and fall back to subtree options.
    var anyOrderMatch: Config {
        get { options[.anyOrderMatch] ?? subtreeOptions[.anyOrderMatch] ?? Config(isActive: false) }
        set { options[.anyOrderMatch] = newValue }
    }

    var collectionEqualCount: Config {
        get { options[.collectionEqualCount] ?? subtreeOptions[.collectionEqualCount] ?? Config(isActive: false) }
        set { options[.collectionEqualCount] = newValue }
    }

    var elementCount: Config {
        get { options[.elementCount] ?? subtreeOptions[.elementCount] ?? Config(isActive: true) }
        set { options[.elementCount] = newValue }
    }

    var keyMustBeAbsent: Config {
        get { options[.keyMustBeAbsent] ?? subtreeOptions[.keyMustBeAbsent] ?? Config(isActive: false) }
        set { options[.keyMustBeAbsent] = newValue }
    }

    var primitiveExactMatch: Config {
        get { options[.primitiveExactMatch] ?? subtreeOptions[.primitiveExactMatch] ?? Config(isActive: false) }
        set { options[.primitiveExactMatch] = newValue }
    }

    var valueNotEqual: Config {
        get { options[.valueNotEqual] ?? subtreeOptions[.valueNotEqual] ?? Config(isActive: false) }
        set { options[.valueNotEqual] = newValue }
    }

    /// Creates a new node with the given values.
    ///
    /// Make sure to specify **all** `OptionKey` values for `subtreeOptions`, especially when the node is intended to be the root.
    /// These subtree options will be used for all descendants unless otherwise specified. If any subtree option keys are missing, a
    /// default value will be provided.
    init(name: String?,
         options: [OptionKey: Config] = [:],
         subtreeOptions: [OptionKey: Config],
         children: Set<NodeConfig> = [],
         wildcardChildren: NodeConfig? = nil) {
        // Validate subtreeOptions has every option defined
        var validatedSubtreeOptions = subtreeOptions
        for key in OptionKey.allCases {
            if subtreeOptions[key] != nil {
                continue
            }
            // If key is missing, add a default value
            validatedSubtreeOptions[key] = Config(isActive: false)
        }

        self.name = name
        self.options = options
        self.subtreeOptions = validatedSubtreeOptions
        self.children = children
        self.wildcardChildren = wildcardChildren
    }

    // Implementation of Hashable
    public static func == (lhs: NodeConfig, rhs: NodeConfig) -> Bool {
        // Define equality based on properties of NodeConfig
        return lhs.name == rhs.name &&
            lhs.options == rhs.options &&
            lhs.subtreeOptions == rhs.subtreeOptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(options)
        hasher.combine(subtreeOptions)
    }

    /// Creates a deep copy of the current `NodeConfig` instance with optional resetting of the ElementCount.
    func deepCopy(resetElementCount: Bool = false) -> NodeConfig {
        let copiedNode = NodeConfig(name: name, options: options, subtreeOptions: subtreeOptions)

        if resetElementCount {
            copiedNode.subtreeOptions = NodeConfig.copySubtreeOptionsWithElementCountReset(map: subtreeOptions)
        } else {
            copiedNode.subtreeOptions = subtreeOptions
        }

        copiedNode.children = Set(self.children.map { $0.deepCopy(resetElementCount: resetElementCount) })
        copiedNode.wildcardChildren = wildcardChildren?.deepCopy(resetElementCount: resetElementCount)

        return copiedNode
    }

    /// Creates a deep copy of the subtree options with element count reset.
    static func copySubtreeOptionsWithElementCountReset(map: [OptionKey: Config]) -> [OptionKey: Config] {
        var deepCopiedSubtreeOptions = map

        // - Subtree options should always exist, but backup value defaults to false
        // - ElementCount's requiredCount value should be removed for nodes that are not explicitly the
        // node that had that option set, otherwise the expectation propagates improperly to all children
        deepCopiedSubtreeOptions[.elementCount] = Config(isActive: deepCopiedSubtreeOptions[.elementCount]?.isActive ?? true)

        return deepCopiedSubtreeOptions
    }

    func getChild(named name: String?) -> NodeConfig? {
        return children.first(where: { $0.name == name })
    }

    func getChild(indexed index: Int?) -> NodeConfig? {
        guard let index = index else { return nil }
        let indexString = String(index)
        return children.first(where: { $0.name == indexString })
    }

    func asFinalNode() -> NodeConfig {
        // Should not modify self since other recursive function calls may still depend on children.
        // Instead, return a new instance with the proper values set
        return NodeConfig(name: nil, options: [:], subtreeOptions: NodeConfig.copySubtreeOptionsWithElementCountReset(map: subtreeOptions))
    }

    func getNextNode(for name: String?) -> NodeConfig {
        return getChild(named: name) ?? wildcardChildren ?? asFinalNode()
    }

    func getNextNode(for index: Int?) -> NodeConfig {
        return getChild(indexed: index) ?? wildcardChildren ?? asFinalNode()
    }

    /// Resolves a given node's option using the following precedence:
    /// 1. Single node config
    ///    a. Child node
    ///    b. Parent's wildcard node
    ///    c. Parent node
    /// 2. Subtree config
    ///    a. Child node (by definition supersedes wildcard subtree option)
    ///    b. Parent node (only if child node doesn't exist)
    ///
    /// This is to handle the case where an array has a node-specific option like AnyPosition match which
    /// should apply to all direct children (that is, only 1 level down), but one of the children has a
    /// node specific option disabling AnyPosition match.
    static func resolveOption(_ option: OptionKey, childName: String?, parentNode: NodeConfig) -> Config {
        let childNode = parentNode.getChild(named: childName)

        // Single node options
        // Current node
        if let nodeOption = childNode?.options[option] {
            return nodeOption
        }

        // Parent's wildcard child
        if let wildcardOption = parentNode.wildcardChildren?.options[option] {
            return wildcardOption
        }

        // Check parent array's node-specific option
        if let arrayOption = parentNode.options[option] {
            return arrayOption
        }

        // Check subtree options in the same order of precedence, with the condition that if childNode exists,
        // it must have a subtree definition. Fallback to parentNode only if childNode doesn't exist.
        return childNode?.subtreeOptions[option] ?? parentNode.subtreeOptions[option] ?? Config(isActive: false)
    }

    static func resolveOption(_ option: OptionKey, childName: Int?, parentNode: NodeConfig) -> Config {
        return resolveOption(option, childName: childName?.description, parentNode: parentNode)
    }

    // MARK: - Node creation methods

    static func createOrUpdateNode(_ node: NodeConfig, with multiPathConfig: MultiPathConfig, file: StaticString, line: UInt) {
        let pathConfigs = multiPathConfig.paths.map({
            PathConfig(
                path: $0,
                optionKey: multiPathConfig.optionKey,
                config: multiPathConfig.config,
                scope: multiPathConfig.scope)
        })
        for pathConfig in pathConfigs {
            createOrUpdateNode(node, with: pathConfig, file: file, line: line)
        }
    }

    // Helper method to create or traverse nodes
    static func createOrUpdateNode(_ node: NodeConfig, with pathConfig: PathConfig, file: StaticString, line: UInt) {
        let pathComponents = getProcessedPathComponents(for: pathConfig.path, file: file, line: line)
        updateTree(nodes: [node], with: pathConfig, pathComponents: pathComponents)
    }

    /// Finds or creates a child node, returning the child node. After creation, also handles the assignment to the proper descendants location
    /// in the current node.
    static func findOrCreateChild(of node: NodeConfig, named name: String, isWildcard: Bool) -> NodeConfig {
        if isWildcard {
            if let existingChild = node.wildcardChildren {
                return existingChild
            } else {
                // Apply subtreeOptions to the child
                let newChild = NodeConfig(name: name, subtreeOptions: NodeConfig.copySubtreeOptionsWithElementCountReset(map: node.subtreeOptions))
                node.wildcardChildren = newChild
                return newChild
            }
        } else {
            if let existingChild = node.children.first(where: { $0.name == name }) {
                return existingChild
            } else {
                // If a wildcard child already exists, use that as the base, deep copying its existing setup
                if let wildcardTemplateChild = node.wildcardChildren?.deepCopy() {
                    wildcardTemplateChild.name = name
                    node.children.insert(wildcardTemplateChild)
                    return wildcardTemplateChild
                } else {
                    // Apply subtreeOptions to the child
                    let newChild = NodeConfig(name: name, subtreeOptions: NodeConfig.copySubtreeOptionsWithElementCountReset(map: node.subtreeOptions))
                    node.children.insert(newChild)
                    return newChild
                }
            }
        }
    }

    static func propagateSubtreeOption(for node: NodeConfig, pathConfig: PathConfig) {
        let key = pathConfig.optionKey
        // Set the subtree configuration for the current node with a copy of the config
        node.subtreeOptions[key] = pathConfig.config

        // A non-null elementCount means the ElementCount assertion is active at the given node;
        // however, child nodes (including wildcard children) should not inherit this assertion.
        // The element counter is set to null so that while the direct path target of the subtree
        // option has the counter applied, this assertion is not propagated to any children.
        let elementCountRemovedConfig = Config(isActive: pathConfig.config.isActive, elementCount: nil)

        // Set the subtree configuration for wildcard children, if they exist, with the element count
        // requirements removed
        node.wildcardChildren?.subtreeOptions[key] = elementCountRemovedConfig

        // Create a modified pathConfig for propagation
        let elementCountRemovedPathConfig = PathConfig(path: pathConfig.path, optionKey: pathConfig.optionKey, config: elementCountRemovedConfig, scope: pathConfig.scope)
        // Propagate the modified configuration to all children
        for child in node.children {
            // Only propagate the subtree value for the specific option key,
            // otherwise, previously set subtree values will be reset to the default values
            child.subtreeOptions[key] = elementCountRemovedPathConfig.config
            propagateSubtreeOption(for: child, pathConfig: elementCountRemovedPathConfig)
        }
    }

    static func updateTree(nodes: [NodeConfig], with pathConfig: PathConfig, pathComponents: [PathComponent]) {
        if nodes.isEmpty { return }
        var pathComponents = pathComponents
        // Reached the end of the pathComponents - apply the PathConfig to the current nodes
        if pathComponents.isEmpty {
            // Apply the node option to the final node
            for node in nodes {
                if pathConfig.scope == .subtree {
                    // Propagate this subtree option update to all children
                    propagateSubtreeOption(for: node, pathConfig: pathConfig)
                } else {
                    node.options[pathConfig.optionKey] = pathConfig.config
                }
            }
            return
        }

        // Note the removal of the first path component from the overall array - this progresses the recursion by 1
        let pathComponent = pathComponents.removeFirst()
        var nextNodes: [NodeConfig] = []
        for node in nodes {
            // Note: the `[*]` case is processed as name = "[*]"; name is not `nil` (reserved for root node)
            guard let pathComponentName = pathComponent.name else { continue }

            let child = findOrCreateChild(of: node, named: pathComponentName, isWildcard: pathComponent.isWildcard)
            nextNodes.append(child)

            if pathComponent.isWildcard {
                nextNodes.append(contentsOf: node.children)
            }
        }
        updateTree(nodes: nextNodes, with: pathConfig, pathComponents: pathComponents)
    }

    // MARK: - Path interpretation methods

    /// Breaks a path string into its nested object segments. Any trailing array style access components are bundled with a
    /// preceeding object segment (if such an object segment exists).
    ///
    /// For example, the key path: `"key0\.key1.key2[1][2].key3"`, represents a path to an element in a nested
    /// JSON structure. The result for the input is: `["key0\.key1", "key2[1][2]", "key3"]`.
    ///
    /// The method breaks each object path segment separated by the `.` character and escapes
    /// the sequence `\.` as a part of the key itself (that is, it ignores `\.` as a nesting indicator).
    ///
    /// - Parameter text: The key path string to be split into its nested object segments.
    ///
    /// - Returns: An array of strings representing the individual components of the key path. If the input `text` is empty,
    /// a list containing an empty string is returned. If no components are found, an empty list is returned.
    static func getObjectPathComponents(from path: String?) -> [String] {
        // Handle edge case where input is nil
        guard let path = path else { return [] }
        // Handle edge case where input is empty
        if path.isEmpty { return [""] }

        var segments: [String] = []
        var startIndex = path.startIndex
        var inEscapeSequence = false

        // Iterate over each character in the input string with its index
        for (index, char) in path.enumerated() {
            let currentIndex = path.index(path.startIndex, offsetBy: index)

            // If current character is a backslash and we're not already in an escape sequence
            if char == "\\" {
                inEscapeSequence = true
            }
            // If current character is a dot and we're not in an escape sequence
            else if char == "." && !inEscapeSequence {
                // Add the segment from the start index to current index (excluding the dot)
                segments.append(String(path[startIndex..<currentIndex]))

                // Update the start index for the next segment
                startIndex = path.index(after: currentIndex)
            }
            // Any other character or if we're ending an escape sequence
            else {
                inEscapeSequence = false
            }
        }

        // Add the remaining segment after the last dot (if any)
        segments.append(String(path[startIndex...]))

        // Handle edge case where input ends with a dot (but not an escaped dot)
        if path.hasSuffix(".") && !path.hasSuffix("\\.") && !(segments.last ?? "").isEmpty {
            segments.append("")
        }

        return segments
    }

    // swiftlint:disable function_body_length
    /// Extracts valid array format access components from a given path component and returns the separated components.
    ///
    /// Given `"key1[0][1]"`, the result is `["key1", "[0]", "[1]"]`.
    /// Array format access can be escaped using a backslash character preceding an array bracket. Valid bracket escape sequences are cleaned so
    /// that the final path component does not have the escape character.
    /// For example: `"key1\[0\]"` results in the single path component `"key1[0]"`.
    ///
    /// - Parameter pathComponent: The path component to be split into separate components given valid array formatted components.
    ///
    /// - Returns: An array of `String` path components, where the original path component is divided into individual elements. Valid array format
    ///  components in the original path are extracted as distinct elements, in order. If there are no array format components, the array contains only
    ///  the original path component.
    static func getArrayPathComponents(from pathComponent: String) -> (stringComponent: String?, arrayComponents: [String]) {
        // Handle edge case where input is empty
        if pathComponent.isEmpty { return (stringComponent: "", arrayComponents: []) }

        var stringComponent: String = ""
        var arrayComponents: [String] = []
        var bracketCount = 0
        var componentBuilder = ""
        var skipNextChar = false
        var lastArrayAccessEnd = pathComponent.endIndex // to track the end of the last valid array-style access

        func isEscaped(_ index: String.Index) -> Bool {
            if index == pathComponent.startIndex {
                return false
            }

            var backslashCount = 0
            var currentIndex = pathComponent.index(before: index)

            while currentIndex >= pathComponent.startIndex {
                if pathComponent[currentIndex] == "\\" {
                    backslashCount += 1
                    if currentIndex == pathComponent.startIndex {
                        break
                    }
                    currentIndex = pathComponent.index(before: currentIndex)
                } else {
                    break
                }
            }

            return backslashCount % 2 != 0
        }

        outerLoop: for index in pathComponent.indices.reversed() {
            if skipNextChar {
                skipNextChar = false
                continue
            }

            switch pathComponent[index] {
            case "]" where !isEscaped(index):
                bracketCount += 1
                componentBuilder.append("]")
            case "[" where !isEscaped(index):
                bracketCount -= 1
                componentBuilder.append("[")
                if bracketCount == 0 {
                    arrayComponents.insert(String(componentBuilder.reversed()), at: 0)
                    componentBuilder = ""
                    lastArrayAccessEnd = index
                }
            case "\\" where isEscaped(index):
                componentBuilder.append("\\")
                skipNextChar = true
            default:
                // Non-continuous array style bracket access means the rest is the object key name
                if bracketCount == 0 && index < lastArrayAccessEnd {
                    stringComponent = String(pathComponent[pathComponent.startIndex...index])
                    break outerLoop
                }
                // If bracket count is non-zero, still inside an array bracket pair
                componentBuilder.append(pathComponent[index])
            }
        }

        // Add any remaining component that's not yet added
        if !componentBuilder.isEmpty {
            stringComponent += String(componentBuilder.reversed())
        }
        if !stringComponent.isEmpty {
            stringComponent = stringComponent
                .replacingOccurrences(of: "\\[", with: "[")
                .replacingOccurrences(of: "\\]", with: "]")
        }
        if lastArrayAccessEnd == pathComponent.startIndex {
            return (stringComponent: nil, arrayComponents: arrayComponents)
        }
        return (stringComponent: stringComponent, arrayComponents: arrayComponents)
    }
    // swiftlint:enable function_body_length

    /// Extracts a valid array index from a given array access string.
    ///
    /// This method checks if the input string follows the format of an array access (i.e., it starts with "[" and ends with "]").
    /// It then attempts to extract and convert the inner string to a non-negative integer. If the format is invalid or the conversion
    /// fails, the method records a test failure and returns nil.
    ///
    /// - Parameters:
    ///   - arrayAccess: The array access string to be processed. This should be in the format "[index]".
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: An optional integer representing the array index. If the input is not in the correct format or the index
    ///            is not a non-negative integer, the method returns nil and logs a test failure.
    ///
    /// - Note: This method uses `XCTFail` to log failures. It is intended to be used in a testing context where
    ///         failing to extract a valid index is considered an error.
    static func extractArrayIndex(from arrayAccess: String, file: StaticString, line: UInt) -> Int? {
        // Check if the string starts with "[" and ends with "]"
        guard arrayAccess.hasPrefix("[") && arrayAccess.hasSuffix("]") else {
            XCTFail("Invalid array format: \(arrayAccess). Expected format: '[index]'", file: file, line: line)
            return nil
        }

        // Extract the inner part of the string by removing the first and last characters
        let startIndex = arrayAccess.index(after: arrayAccess.startIndex)
        let endIndex = arrayAccess.index(before: arrayAccess.endIndex)
        let innerString = String(arrayAccess[startIndex..<endIndex])

        // Attempt to convert the inner string to an integer
        guard let index = Int(innerString), index >= 0 else {
            XCTFail("Invalid index value: \(innerString). Index should be a non-negative integer.", file: file, line: line)
            return nil
        }

        return index
    }

    /// Processes a given path string and returns an array of `PathComponent` objects representing the components of the path.
    ///
    /// This method breaks down a path string into its components, handling both object and array segments. It
    /// converts escaped characters, identifies wildcards, and validates array indices. The method logs failures for invalid
    /// formats or indices using `XCTFail`.
    ///
    /// - Parameters:
    ///   - pathString: The path string to be processed. This string can contain object keys, array indices, and wildcards.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: An array of `PathComponent` objects representing the individual components of the path. If the input path
    ///            string is nil or empty, the method returns an empty array. If an invalid array index is encountered, the
    ///            method logs a failure and returns the components processed up to that point.
    ///
    /// - Note: This method uses `XCTFail` to log failures for invalid formats or indices. It is intended to be used in a
    ///         testing context where such failures are considered errors.
    static func getProcessedPathComponents(for pathString: String?, file: StaticString, line: UInt) -> [PathComponent] {
        let objectPathComponents = getObjectPathComponents(from: pathString)

        var pathComponents: [PathComponent] = []
        for objectPathComponent in objectPathComponents {
            let key = objectPathComponent.replacingOccurrences(of: "\\.", with: ".")
            // Extract the string part and array component part(s) from the key string
            let components = getArrayPathComponents(from: key)

            // Process string segment
            if let stringComponent = components.stringComponent {
                // Check if component is wildcard
                let isWildcard = stringComponent == "*"
                if isWildcard {
                    pathComponents.append(PathComponent(name: stringComponent, isArray: false, isWildcard: isWildcard))
                } else {
                    let cleanStringComponent = stringComponent.replacingOccurrences(of: "\\*", with: "*")
                    pathComponents.append(PathComponent(name: cleanStringComponent, isArray: false, isWildcard: isWildcard))
                }
            }

            // Process array segment(s)
            for arrayComponent in components.arrayComponents {
                // Check for array wildcard case
                if arrayComponent == "[*]" {
                    pathComponents.append(PathComponent(name: arrayComponent, isArray: true, isWildcard: true))
                } else {
                    // Indices represent the "named" child elements of arrays
                    guard let indexResult = extractArrayIndex(from: arrayComponent, file: file, line: line) else {
                        // Failure path: In case of invalid array/index format, test failure emitted by extractArrayIndex
                        return pathComponents
                    }
                    pathComponents.append(PathComponent(name: String(indexResult), isArray: true, isWildcard: false))
                }
            }
        }
        return pathComponents
    }
}

extension NodeConfig: CustomStringConvertible {
    public var description: String {
        return describeNode(indentation: 0)
    }

    // swiftlint:disable function_body_length
    private func describeNode(indentation: Int) -> String {
        var result = indentation == 0 ? "\n" : ""
        let indentString = String(repeating: "  ", count: indentation) // Two spaces per indentation level

        // Node name
        result += "\(indentString)Name: \(name ?? "<Unnamed>")\n"

        var finalOptionsDescriptions: [String] = []

        if anyOrderMatch.isActive {
            finalOptionsDescriptions.append("\(indentString)Any Order  : \(anyOrderMatch)")
        }
        if collectionEqualCount.isActive {
            finalOptionsDescriptions.append("\(indentString)Equal Count: \(collectionEqualCount)")
        }
        if primitiveExactMatch.isActive {
            finalOptionsDescriptions.append("\(indentString)Exact Match: \(primitiveExactMatch)")
        }
        if keyMustBeAbsent.isActive {
            finalOptionsDescriptions.append("\(indentString)Key Absent : \(keyMustBeAbsent)")
        }

        // Append FINAL options to the result
        if finalOptionsDescriptions.isEmpty {
            result += "\(indentString)FINAL options: none active\n"
        } else {
            result += "\(indentString)FINAL options:\n"
            result += finalOptionsDescriptions.joined(separator: "\n") + "\n"
        }

        // Node options - Only include options where config is TRUE
        let filteredOptions = options.filter { $1.isActive }
        let sortedOptions = filteredOptions.sorted { $0.key < $1.key }
        let optionsDescription = sortedOptions
            .map { key, config in
                "\(indentString)  \(key): \(config)"
            }
            .joined(separator: "\n")

        // Append filtered options to the result if there are any
        if !optionsDescription.isEmpty {
            result += "\(indentString)Options:\n" + optionsDescription + "\n"
        }

        // Subtree options - Only include options where config is TRUE
        let filteredSubtreeOptions = subtreeOptions.filter { $1.isActive }
        let sortedSubtreeOptions = filteredSubtreeOptions.sorted { $0.key < $1.key }
        let subtreeOptionsDescription = sortedSubtreeOptions
            .map { key, config in
                "\(indentString)  \(key): \(config)"
            }
            .joined(separator: "\n")

        // Append filtered subtree options to the result if there are any
        if !subtreeOptionsDescription.isEmpty {
            result += "\(indentString)Subtree options:\n" + subtreeOptionsDescription + "\n"
        }
        // Children nodes
        if !children.isEmpty {
            result += "\(indentString)Children:\n"
            for child in children {
                result += child.describeNode(indentation: indentation + 1)
            }
        }
        if let wildcardChildren = wildcardChildren {
            result += "\(indentString)Wildcard children:\n"
            result += wildcardChildren.describeNode(indentation: indentation + 1)
        }

        return result
    }
    // swiftlint:enable function_body_length
}

extension NodeConfig.OptionKey: Comparable {
    public static func < (lhs: NodeConfig.OptionKey, rhs: NodeConfig.OptionKey) -> Bool {
        // Implement comparison logic
        // For enums without associated values, a simple approach is to compare their raw values
        return lhs.rawValue < rhs.rawValue
    }
}

public extension NodeConfig.NodeOption {
    static func option(_ key: NodeConfig.OptionKey, active: Bool, scope: NodeConfig.Scope = .subtree) -> NodeConfig.NodeOption {
        return .option(key, NodeConfig.Config(isActive: active), scope)
    }
}

extension NodeConfig.Config: CustomStringConvertible {
    public var description: String {
        let isActiveDescription = (isActive ? "TRUE " : "F").padding(toLength: 6, withPad: " ", startingAt: 0)
        return "\(isActiveDescription)"
    }
}

extension NodeConfig.OptionKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .anyOrderMatch: return "Any Order"
        case .collectionEqualCount: return "Equal Count"
        case .elementCount: return "Element Count"
        case .keyMustBeAbsent: return "Key Absent"
        case .primitiveExactMatch: return "Exact Match"
        case .valueNotEqual: return "Value not Equal"
            // Add cases for other options
        }
    }
}

extension NodeConfig.Scope: CustomStringConvertible {
    public var description: String {
        switch self {
        case .singleNode: return "Node"
        case .subtree: return "Tree"
        }
    }
}
