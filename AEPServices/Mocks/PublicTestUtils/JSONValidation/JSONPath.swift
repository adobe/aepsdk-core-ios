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

import Foundation

/// A type-safe representation of a path within a JSON structure.
///
/// `JSONPath` provides a way to reference specific locations within nested JSON objects
/// and arrays using a familiar dot-notation and bracket syntax.
///
/// ## Path Syntax
///
/// ### Object Keys
/// - Standard keys: `"user"`, `"name"`
/// - Nested keys: `"user.profile.name"` (dot notation)
/// - Keys containing dots: `"user\.name"` (escaped with backslash)
/// - Keys containing brackets: `"key\[0\]"` (escaped with backslash)
/// - Keys containing asterisks: `"\*"` (escaped with backslash)
///
/// ### Array Indices
/// - Single index: `"items[0]"`, `"items[42]"`
/// - Chained indices: `"matrix[0][1]"`
/// - Combined with keys: `"users[0].name"`
///
/// ### Wildcards
/// - Array wildcard: `"items[*]"` (matches all array elements)
/// - Object wildcard: `"data.*"` (matches all object keys)
///
/// ## Usage
///
/// ```swift
/// // String literal initialization
/// let path: JSONPath = "users[0].profile.name"
///
/// // Explicit initialization
/// let path = JSONPath("items[*].id")
///
/// // Root path (empty)
/// let root = JSONPath.root
///
/// // Building paths programmatically
/// let path = JSONPath.root
///     .appending(.key("users"))
///     .appending(.index(0))
///     .appending(.key("name"))
/// ```
public struct JSONPath: Hashable {
    
    // MARK: - Component
    
    /// Represents a single component of a JSON path.
    public enum Component: Hashable {
        /// An object key (e.g., "name" in "user.name")
        case key(String)
        
        /// An array index (e.g., 0 in "items[0]")
        case index(Int)
        
        /// A wildcard matching all keys in an object (e.g., "*" in "data.*")
        case wildcardKey
        
        /// A wildcard matching all indices in an array (e.g., "[*]" in "items[*]")
        case wildcardIndex
        
        /// Returns `true` if this component is a wildcard (either key or index).
        public var isWildcard: Bool {
            switch self {
            case .wildcardKey, .wildcardIndex:
                return true
            case .key, .index:
                return false
            }
        }
        
        /// Returns `true` if this component references an array (index or wildcard index).
        public var isArrayAccess: Bool {
            switch self {
            case .index, .wildcardIndex:
                return true
            case .key, .wildcardKey:
                return false
            }
        }
        
        /// Returns the string representation of this component for use in node naming.
        ///
        /// - For keys: the key string itself
        /// - For indices: the index as a string (e.g., "0", "42")
        /// - For wildcardKey: "*"
        /// - For wildcardIndex: "[*]"
        public var nodeName: String {
            switch self {
            case .key(let name):
                return name
            case .index(let idx):
                return String(idx)
            case .wildcardKey:
                return "*"
            case .wildcardIndex:
                return "[*]"
            }
        }
    }
    
    // MARK: - Properties
    
    /// The ordered list of components that make up this path.
    public let components: [Component]
    
    // MARK: - Static Properties
    
    /// The root path, representing the top-level of the JSON structure.
    ///
    /// Use this when you want to apply an option at the root level rather than
    /// at a specific nested path.
    public static let root = JSONPath(components: [])
    
    // MARK: - Initialization
    
    /// Creates a path from an array of components.
    ///
    /// - Parameter components: The path components in order from root to leaf.
    public init(components: [Component]) {
        self.components = components
    }
    
    /// Creates a path by parsing a string representation.
    ///
    /// - Parameter pathString: The path string to parse (e.g., "users[0].name").
    public init(_ pathString: String) {
        self.components = JSONPath.parse(pathString)
    }
    
    // MARK: - Path Operations
    
    /// Returns a new path with the given component appended.
    ///
    /// - Parameter component: The component to append.
    /// - Returns: A new path with the component added at the end.
    public func appending(_ component: Component) -> JSONPath {
        JSONPath(components: components + [component])
    }
    
    /// Returns a new path with multiple components appended.
    ///
    /// - Parameter newComponents: The components to append.
    /// - Returns: A new path with the components added at the end.
    public func appending(_ newComponents: [Component]) -> JSONPath {
        JSONPath(components: components + newComponents)
    }
    
    /// Returns a new path by joining this path with another.
    ///
    /// - Parameter other: The path to append.
    /// - Returns: A new path combining both paths.
    public func appending(_ other: JSONPath) -> JSONPath {
        JSONPath(components: components + other.components)
    }
    
    /// Returns the parent path (all components except the last).
    ///
    /// - Returns: The parent path, or `nil` if this is the root path.
    public var parent: JSONPath? {
        guard !components.isEmpty else { return nil }
        return JSONPath(components: Array(components.dropLast()))
    }
    
    /// Returns `true` if this is the root path (no components).
    public var isRoot: Bool {
        components.isEmpty
    }
    
    /// Returns the last component of the path.
    public var lastComponent: Component? {
        components.last
    }
    
    // MARK: - Parsing
    
    /// Parses a path string into an array of components.
    ///
    /// - Parameter pathString: The path string to parse.
    /// - Returns: An array of path components.
    private static func parse(_ pathString: String) -> [Component] {
        let objectSegments = parseObjectPathComponents(from: pathString)
        
        var components: [Component] = []
        for segment in objectSegments {
            let unescapedSegment = segment.replacingOccurrences(of: "\\.", with: ".")
            let (stringPart, arrayParts) = parseArrayPathComponents(from: unescapedSegment)
            
            // Process the string part (object key)
            if let stringPart = stringPart {
                if stringPart == "*" {
                    components.append(.wildcardKey)
                } else {
                    let cleanKey = stringPart.replacingOccurrences(of: "\\*", with: "*")
                    components.append(.key(cleanKey))
                }
            }
            
            // Process array access parts
            for arrayPart in arrayParts {
                if arrayPart == "[*]" {
                    components.append(.wildcardIndex)
                } else if let index = parseArrayIndex(from: arrayPart) {
                    components.append(.index(index))
                }
                // Invalid array format is silently skipped (original behavior used XCTFail)
            }
        }
        
        return components
    }
    
    /// Splits a path string into its object path segments.
    ///
    /// Handles escaped dots (`\.`) as part of the key name.
    ///
    /// Example: `"key0\.key1.key2[1][2].key3"` -> `["key0\.key1", "key2[1][2]", "key3"]`
    private static func parseObjectPathComponents(from path: String) -> [String] {
        if path.isEmpty { return [""] }
        
        var segments: [String] = []
        var startIndex = path.startIndex
        var inEscapeSequence = false
        
        for (index, char) in path.enumerated() {
            let currentIndex = path.index(path.startIndex, offsetBy: index)
            
            if char == "\\" {
                inEscapeSequence = true
            } else if char == "." && !inEscapeSequence {
                segments.append(String(path[startIndex..<currentIndex]))
                startIndex = path.index(after: currentIndex)
            } else {
                inEscapeSequence = false
            }
        }
        
        // Add the remaining segment
        segments.append(String(path[startIndex...]))
        
        // Handle trailing dot (but not escaped dot)
        if path.hasSuffix(".") && !path.hasSuffix("\\.") && !(segments.last ?? "").isEmpty {
            segments.append("")
        }
        
        return segments
    }
    
    /// Extracts the string part and array access parts from a path segment.
    ///
    /// Example: `"key1[0][1]"` -> `(stringComponent: "key1", arrayComponents: ["[0]", "[1]"])`
    private static func parseArrayPathComponents(from segment: String) -> (stringComponent: String?, arrayComponents: [String]) {
        if segment.isEmpty { return (stringComponent: "", arrayComponents: []) }
        
        var stringComponent: String = ""
        var arrayComponents: [String] = []
        var bracketCount = 0
        var componentBuilder = ""
        var skipNextChar = false
        var lastArrayAccessEnd = segment.endIndex
        
        func isEscaped(_ index: String.Index) -> Bool {
            if index == segment.startIndex { return false }
            
            var backslashCount = 0
            var currentIndex = segment.index(before: index)
            
            while currentIndex >= segment.startIndex {
                if segment[currentIndex] == "\\" {
                    backslashCount += 1
                    if currentIndex == segment.startIndex { break }
                    currentIndex = segment.index(before: currentIndex)
                } else {
                    break
                }
            }
            
            return backslashCount % 2 != 0
        }
        
        outerLoop: for index in segment.indices.reversed() {
            if skipNextChar {
                skipNextChar = false
                continue
            }
            
            switch segment[index] {
            case "]" where !isEscaped(index):
                bracketCount += 1
                componentBuilder.append("]")
            case "[" where !isEscaped(index):
                bracketCount -= 1
                componentBuilder.append("[")
                if bracketCount == 0 {
                    let rawComponent = String(componentBuilder.reversed())
                    
                    // Validates that the array syntax is correct (integer or wildcard)
                    // If invalid, this is a developer error in the path syntax -> fatalError
                    if parseArrayIndex(from: rawComponent) == nil && rawComponent != "[*]" {
                        fatalError("Invalid JSONPath array syntax: '\(rawComponent)' in segment '\(segment)'. Indices must be integers or '*'. To use literal brackets in a key, escape them: '\\[...\\].")
                    }
                    
                    arrayComponents.insert(rawComponent, at: 0)
                    componentBuilder = ""
                    lastArrayAccessEnd = index
                }
            case "\\" where isEscaped(index):
                componentBuilder.append("\\")
                skipNextChar = true
            default:
                if bracketCount == 0 && index < lastArrayAccessEnd {
                    stringComponent = String(segment[segment.startIndex...index])
                    break outerLoop
                }
                componentBuilder.append(segment[index])
            }
        }
        
        // Add any remaining component
        if !componentBuilder.isEmpty {
            stringComponent += String(componentBuilder.reversed())
        }
        if !stringComponent.isEmpty {
            stringComponent = stringComponent
                .replacingOccurrences(of: "\\[", with: "[")
                .replacingOccurrences(of: "\\]", with: "]")
        }
        if lastArrayAccessEnd == segment.startIndex {
            return (stringComponent: nil, arrayComponents: arrayComponents)
        }
        return (stringComponent: stringComponent, arrayComponents: arrayComponents)
    }
    
    /// Extracts an array index from a bracket notation string.
    ///
    /// Example: `"[42]"` -> `42`
    private static func parseArrayIndex(from arrayAccess: String) -> Int? {
        guard arrayAccess.hasPrefix("[") && arrayAccess.hasSuffix("]") else {
            return nil
        }
        
        let startIndex = arrayAccess.index(after: arrayAccess.startIndex)
        let endIndex = arrayAccess.index(before: arrayAccess.endIndex)
        let innerString = String(arrayAccess[startIndex..<endIndex])
        
        guard let index = Int(innerString), index >= 0 else {
            return nil
        }
        
        return index
    }
}

extension JSONPath: ExpressibleByStringLiteral {
    /// Creates a path from a string literal.
    ///
    /// This allows you to use string literals directly where a `JSONPath` is expected:
    /// ```swift
    /// let path: JSONPath = "users[0].name"
    /// ```
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension JSONPath: CustomStringConvertible {
    /// Returns a string representation of the path.
    public var description: String {
        if components.isEmpty {
            return "<root>"
        }
        
        var result = ""
        for component in components {
            switch component {
            case .key(let name):
                if !result.isEmpty {
                    result += "."
                }
                // Escape special characters for display
                let escapedName = name
                    .replacingOccurrences(of: ".", with: "\\.")
                    .replacingOccurrences(of: "[", with: "\\[")
                    .replacingOccurrences(of: "]", with: "\\]")
                result += escapedName
            case .index(let idx):
                result += "[\(idx)]"
            case .wildcardKey:
                if !result.isEmpty {
                    result += "."
                }
                result += "*"
            case .wildcardIndex:
                result += "[*]"
            }
        }
        return result
    }
}

// MARK: - Component CustomStringConvertible

extension JSONPath.Component: CustomStringConvertible {
    public var description: String {
        switch self {
        case .key(let name):
            return ".key(\"\(name)\")"
        case .index(let idx):
            return ".index(\(idx))"
        case .wildcardKey:
            return ".wildcardKey"
        case .wildcardIndex:
            return ".wildcardIndex"
        }
    }
}

