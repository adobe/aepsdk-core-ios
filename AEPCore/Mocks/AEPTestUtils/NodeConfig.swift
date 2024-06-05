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

import Foundation
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
public class NodeConfig: Hashable {
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
        case primitiveExactMatch
        case keyMustBeAbsent
    }

    /// Represents the configuration details for a comparison option
    public struct Config: Hashable {
        /// Flag that controls if the option is active or not.
        var isActive: Bool
    }

    public enum NodeOption {
        case option(OptionKey, Config, Scope)
    }

    private struct PathComponent {
        var name: String?
        /// Flag that controls if this path component is an AnyOrder option type
        var isAnyOrder: Bool
        /// Flag that controls if this path component is an array index
        var isArray: Bool
        /// Flag that controls if this path component is a wildcard
        var isWildcard: Bool
    }

    /// An string representing the name of the node. `nil` refers to the top level object
    var name: String?
    /// Options set specifically for this node. Specific `OptionKey`s may or may not be present - it is optional.
    private(set) var options: [OptionKey: Config] = [:]
    /// Options set for the subtree, used as the default option when no node-specific options are set. All `OptionKey`s MUST be
    /// present.
    private var subtreeOptions: [OptionKey: Config] = [:]

    /// The set of child nodes.
    private(set) var children: Set<NodeConfig>
    /// The node configuration for wildcard children
    private(set) var wildcardChildren: NodeConfig?

    // Property accessors for each option which use the `options` set for the current node
    // and fall back to subtree options.
    var anyOrderMatch: Config {
        get { options[.anyOrderMatch] ?? subtreeOptions[.anyOrderMatch]! }
        set { options[.anyOrderMatch] = newValue }
    }

    var collectionEqualCount: Config {
        get { options[.collectionEqualCount] ?? subtreeOptions[.collectionEqualCount]! }
        set { options[.collectionEqualCount] = newValue }
    }

    var keyMustBeAbsent: Config {
        get { options[.keyMustBeAbsent] ?? subtreeOptions[.keyMustBeAbsent]! }
        set { options[.keyMustBeAbsent] = newValue }
    }

    var primitiveExactMatch: Config {
        get { options[.primitiveExactMatch] ?? subtreeOptions[.primitiveExactMatch]! }
        set { options[.primitiveExactMatch] = newValue }
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
            if let foundConfig = subtreeOptions[key] {
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

    /// Creates a deep copy of the current `NodeConfig` instance.
    func deepCopy() -> NodeConfig {
        let copiedNode = NodeConfig(name: name, options: options, subtreeOptions: subtreeOptions)
        copiedNode.children = Set(self.children.map { $0.deepCopy() })
        copiedNode.wildcardChildren = wildcardChildren?.deepCopy()
        return copiedNode
    }

    func getChild(named name: String?) -> NodeConfig? {
        return children.first(where: { $0.name == name })
    }

    func getChild(indexed index: Int?) -> NodeConfig? {
        guard let index = index else { return nil }
        let indexString = String(index)
        return children.first(where: { $0.name == indexString })
    }

    func getNextNode(for name: String?) -> NodeConfig {
        return getChild(named: name) ?? wildcardChildren ?? asFinalNode()
    }

    func getNextNode(for index: Int?) -> NodeConfig {
        return getChild(indexed: index) ?? wildcardChildren ?? asFinalNode()
    }

    /// Resolves a given node's option using the following precedence:
    /// 1. Single node option
    ///   a. Current node
    ///   b. Wildcard child
    ///   c. Parent node
    ///
    /// 2. Subtree option
    ///   a. Current node
    ///   b. Wildcard child
    ///   c. Parent node
    ///
    /// This is to handle the case where an array has a node-specific option like wildcard match which should apply to all direct children
    /// (that is, only 1 level down), and one of the children has a node specific option disabling wildcard match.
    static func resolveOption(_ option: OptionKey, for node: NodeConfig?, parent parentNode: NodeConfig) -> Config {
        // Single node options
        // Current node
        if let nodeOption = node?.options[option] {
            return nodeOption
        }
        // Wildcard child
        if let wildcardOption = node?.wildcardChildren?.options[option] {
            return wildcardOption
        }
        // Check array's node-specific option
        if let arrayOption = parentNode.options[option] {
            return arrayOption
        }
        // Check node's subtree option, falling back to array node's default subtree config
        switch option {
        case .anyOrderMatch:
            return node?.anyOrderMatch ?? node?.wildcardChildren?.anyOrderMatch ?? parentNode.anyOrderMatch
        case .collectionEqualCount:
            return node?.collectionEqualCount ?? node?.wildcardChildren?.collectionEqualCount ?? parentNode.collectionEqualCount
        case .keyMustBeAbsent:
            return node?.keyMustBeAbsent ?? node?.wildcardChildren?.keyMustBeAbsent ?? parentNode.keyMustBeAbsent
        case .primitiveExactMatch:
            return node?.primitiveExactMatch ?? node?.wildcardChildren?.primitiveExactMatch ?? parentNode.primitiveExactMatch
        }
    }

    func createOrUpdateNode(with multiPathConfig: MultiPathConfig, isLegacyMode: Bool, file: StaticString, line: UInt) {
        let pathConfigs = multiPathConfig.paths.map({
            PathConfig(
                path: $0,
                optionKey: multiPathConfig.optionKey,
                config: multiPathConfig.config,
                scope: multiPathConfig.scope)
        })
        for pathConfig in pathConfigs {
            createOrUpdateNode(with: pathConfig, isLegacyMode: isLegacyMode, file: file, line: line)
        }
    }

    // Helper method to create or traverse nodes
    func createOrUpdateNode(with pathConfig: PathConfig, isLegacyMode: Bool, file: StaticString, line: UInt) {
        let pathComponents = getProcessedPathComponents(for: pathConfig.path, file: file, line: line)
        updateTree(nodes: [self], with: pathConfig, pathComponents: pathComponents, isLegacyMode: isLegacyMode)
    }

    private func updateTree(nodes: [NodeConfig], with pathConfig: PathConfig, pathComponents: [PathComponent], isLegacyMode: Bool) {
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
            // Note: the `[*]` case is processed as name = "[*]" not name is nil
            guard let pathComponentName = pathComponent.name else { continue }

            let child = findOrCreateChild(of: node, named: pathComponentName, isWildcard: pathComponent.isWildcard)
            nextNodes.append(child)

            if pathComponent.isWildcard {
                nextNodes.append(contentsOf: node.children)
            }
            if isLegacyMode && pathComponent.isAnyOrder {
                // This is the legacy AnyOrder that should apply to all children
                // Apply the option to the parent level so it applies to all children
                if pathComponentName == "[*]" {
                    node.options[.anyOrderMatch] = Config(isActive: true)
                } else {
                    child.options[.anyOrderMatch] = Config(isActive: true)
                }
            }
        }
        updateTree(nodes: nextNodes, with: pathConfig, pathComponents: pathComponents, isLegacyMode: isLegacyMode)
    }

    private func getProcessedPathComponents(for pathString: String?, file: StaticString, line: UInt) -> [PathComponent] {
        let objectPathComponents = getObjectPathComponents(from: pathString)

        var pathComponents: [PathComponent] = []
        for objectPathComponent in objectPathComponents {
            let key = objectPathComponent.replacingOccurrences(of: "\\.", with: ".")
            // Extract the string part and array component part(s) from the key string
            let components = getArrayPathComponents(from: key)

            // Process string segment
            if var stringComponent = components.stringComponent {
                // Check if component is wildcard
                let isWildcard = stringComponent == "*"
                if isWildcard {
                    pathComponents.append(PathComponent(name: stringComponent, isAnyOrder: false, isArray: false, isWildcard: isWildcard))
                } else {
                    pathComponents.append(PathComponent(name: stringComponent.replacingOccurrences(of: "\\*", with: "*"), isAnyOrder: false, isArray: false, isWildcard: isWildcard))
                }
            }

            // Process array segment(s)
            for arrayComponent in components.arrayComponents {
                // Check for array wildcard case
                if arrayComponent == "[*]" {
                    pathComponents.append(PathComponent(name: arrayComponent, isAnyOrder: true, isArray: true, isWildcard: true))
                    // indexes represent the "named" child elements of arrays
                } else {
                    guard let indexResult = getArrayIndexAndAnyOrder(from: arrayComponent, file: file, line: line) else {
                        // Test failure emitted by extractIndexAndWildcardStatus
                        return pathComponents
                    }
                    pathComponents.append(PathComponent(name: String(indexResult.index), isAnyOrder: indexResult.isAnyOrder, isArray: true, isWildcard: false))
                }
            }
        }
        return pathComponents
    }

    /// Finds or creates a child node, returning the child node. After creation, also handles the assignment to the proper descendants location
    /// in the current node.
    private func findOrCreateChild(of node: NodeConfig, named name: String, isWildcard: Bool) -> NodeConfig {
        if isWildcard {
            if let existingChild = node.wildcardChildren {
                return existingChild
            } else {
                // Apply subtreeOptions to the child
                let newChild = NodeConfig(name: name, subtreeOptions: node.subtreeOptions)
                node.wildcardChildren = newChild
                return newChild
            }
        } else {
            if let existingChild = node.children.first(where: { $0.name == name }) {
                return existingChild
            } else {
                // If a wildcard child already exists, use that as the base
                if let wildcardTemplateChild = wildcardChildren?.deepCopy() {
                    wildcardTemplateChild.name = name
                    node.children.insert(wildcardTemplateChild)
                    return wildcardTemplateChild
                } else {
                    // Apply subtreeOptions to the child
                    let newChild = NodeConfig(name: name, subtreeOptions: node.subtreeOptions)
                    node.children.insert(newChild)
                    return newChild
                }
            }
        }
    }

    private func propagateSubtreeOption(for node: NodeConfig, pathConfig: PathConfig) {
        let key = pathConfig.optionKey
        node.subtreeOptions[key] = pathConfig.config
        wildcardChildren?.subtreeOptions[key] = node.subtreeOptions[key]
        for child in node.children {
            // Only propagate the subtree value for the current option key,
            // otherwise, previously set subtree values will be reset to the default values
            child.subtreeOptions[key] = node.subtreeOptions[key]
            propagateSubtreeOption(for: child, pathConfig: pathConfig)
        }
    }

    func asFinalNode() -> NodeConfig {
        // Should not modify self since other recursive function calls may still depend on children.
        // Instead, return a new instance with the proper values set
        return NodeConfig(name: nil, options: [:], subtreeOptions: subtreeOptions)
    }

    /// Extracts and returns a tuple with a valid index and a flag indicating whether it's an `AnyOrder` index from a single array path segment.
    ///
    /// This method considers a key that matches the array access format (ex: `[*123]` or `[123]`).
    /// It identifies an index by optionally checking for the wildcard marker `*`.
    ///
    /// - Parameters:
    ///   - pathComponent: A single path component which may contain a potential index with or without a wildcard marker.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: A tuple containing an optional valid `Int` index and a boolean indicating whether it's a wildcard index.
    ///   Returns `nil` if no valid index is found.
    ///
    /// - Note:
    ///   Examples of conversions:
    ///   - `[*123]` -> `(123, true)`
    ///   - `[123]` -> `(123, false)`
    ///   - `[*ab12]` causes a test failure since "ab12" is not a valid integer.
    private func getArrayIndexAndAnyOrder(from pathComponent: String, file: StaticString, line: UInt) -> (index: Int, isAnyOrder: Bool)? {
        let arrayIndexValueRegex = #"^\[(.*?)\]$"#
        guard let arrayIndexValue = getCapturedRegexGroups(text: pathComponent, regexPattern: arrayIndexValueRegex).first else {
            XCTFail("TEST ERROR: unable to find valid index value from path component: \(pathComponent)")
            return nil
        }

        let isAnyOrder = arrayIndexValue.starts(with: "*")
        let indexString = isAnyOrder ? String(arrayIndexValue.dropFirst()) : arrayIndexValue

        guard let validIndex = Int(indexString) else {
            XCTFail("TEST ERROR: Index is not a valid Int: \(indexString)", file: file, line: line)
            return nil
        }

        return (validIndex, isAnyOrder)
    }

    /// Finds all matches of the `regexPattern` in the `text` and for each match, returns the original matched `String`
    /// and its corresponding non-null capture groups.
    ///
    /// - Parameters:
    ///   - text: The input `String` on which the regex matching is to be performed.
    ///   - regexPattern: The regex pattern to be used for matching against the `text`.
    ///
    /// - Returns: An array of tuples, where each tuple consists of the original matched `String` and an array of its non-null capture groups. Returns `nil` if an invalid regex pattern is provided.
    private func extractRegexCaptureGroups(text: String, regexPattern: String, file: StaticString = #file, line: UInt = #line) -> [(matchString: String, captureGroups: [String])]? {
        do {
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            var matchResult: [(matchString: String, captureGroups: [String])] = []
            for match in matches {
                var rangeStrings: [String] = []
                // [(matched string), (capture group 0), (capture group 1), etc.]
                for rangeIndex in 0 ..< match.numberOfRanges {
                    let rangeBounds = match.range(at: rangeIndex)
                    guard let range = Range(rangeBounds, in: text) else {
                        continue
                    }
                    rangeStrings.append(String(text[range]))
                }
                guard !rangeStrings.isEmpty else {
                    continue
                }
                let matchString = rangeStrings.removeFirst()
                matchResult.append((matchString: matchString, captureGroups: rangeStrings))
            }
            return matchResult
        } catch let error {
            XCTFail("TEST ERROR: Invalid regex: \(error.localizedDescription)", file: file, line: line)
            return nil
        }
    }

    /// Applies the provided regex pattern to the text and returns all the capture groups from the regex pattern
    private func getCapturedRegexGroups(text: String, regexPattern: String, file: StaticString = #file, line: UInt = #line) -> [String] {

        guard let captureGroups = extractRegexCaptureGroups(text: text, regexPattern: regexPattern, file: file, line: line)?.flatMap({ $0.captureGroups }) else {
            return []
        }

        return captureGroups
    }

    /// Breaks a path string into its nested *object* segments. Any trailing *array* style access components are bundled with a
    /// preceeding object segment (if the object segment exists).
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
    func getObjectPathComponents(from path: String?) -> [String] {
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
        if path.hasSuffix(".") && !path.hasSuffix("\\.") && segments.last != "" {
            segments.append("")
        }

        return segments
    }

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
    func getArrayPathComponents(from pathComponent: String) -> (stringComponent: String?, arrayComponents: [String]) {
        // Handle edge case where input is empty
        if pathComponent.isEmpty { return (stringComponent: "", arrayComponents: []) }

        var stringComponent: String = ""
        var arrayComponents: [String] = []
        var bracketCount = 0
        var componentBuilder = ""
        var nextCharIsBackslash = false
        var lastArrayAccessEnd = pathComponent.endIndex // to track the end of the last valid array-style access

        func isNextCharBackslash(_ index: String.Index) -> Bool {
            if index == pathComponent.startIndex {
                // There is no character before the startIndex.
                return false
            }

            // Since we're iterating in reverse, the "next" character is before i
            let previousIndex = pathComponent.index(before: index)
            return pathComponent[previousIndex] == "\\"
        }

        outerLoop: for index in pathComponent.indices.reversed() {
            switch pathComponent[index] {
            case "]" where !isNextCharBackslash(index):
                bracketCount += 1
                componentBuilder.append("]")
            case "[" where !isNextCharBackslash(index):
                bracketCount -= 1
                componentBuilder.append("[")
                if bracketCount == 0 {
                    arrayComponents.insert(String(componentBuilder.reversed()), at: 0)
                    componentBuilder = ""
                    lastArrayAccessEnd = index
                }
            case "\\":
                if nextCharIsBackslash {
                    nextCharIsBackslash = false
                    continue outerLoop
                } else {
                    componentBuilder.append("\\")
                }
            default:
                if bracketCount == 0 && index < lastArrayAccessEnd {
                    stringComponent = String(pathComponent[pathComponent.startIndex...index])
                    break outerLoop
                }
                componentBuilder.append(pathComponent[index])
            }
        }

        // Add any remaining component that's not yet added
        if !componentBuilder.isEmpty {
            stringComponent = String(componentBuilder.reversed())
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
}

extension NodeConfig: CustomStringConvertible {
    public var description: String {
        return describeNode(indentation: 0)
    }

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
        var optionsDescription = sortedOptions.map { key, config in
            "\(indentString)  \(key): \(config)"
        }.joined(separator: "\n")

        // Append filtered options to the result if there are any
        if !optionsDescription.isEmpty {
            result += "\(indentString)Options:\n" + optionsDescription + "\n"
        }

        // Subtree options - Only include options where config is TRUE
        let filteredSubtreeOptions = subtreeOptions.filter { $1.isActive }
        let sortedSubtreeOptions = filteredSubtreeOptions.sorted { $0.key < $1.key }
        var subtreeOptionsDescription = sortedSubtreeOptions.map { key, config in
            "\(indentString)  \(key): \(config)"
        }.joined(separator: "\n")

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
        case .keyMustBeAbsent: return "Key Absent"
        case .primitiveExactMatch: return "Exact Match"
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
