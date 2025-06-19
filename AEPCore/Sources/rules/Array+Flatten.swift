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

extension Array where Element == Any {
    /// Recursively flattens a nested `[Any]` array into a `[String: Any]` dictionary using dot separated index paths.
    ///
    /// - Elements within the array are assigned keys based on their index position, appended to any provided prefix.
    /// - If an element is a dictionary (`[String: Any]`), it is recursively flattened using the index as part of the path.
    /// - If an element is another array (`[Any]`), it is also recursively flattened with indexes forming the key path.
    ///
    /// ### Example
    /// ```swift
    /// let input: [Any] = [
    ///     ["a": 1],
    ///     ["b": [2, 3]]
    /// ]
    /// let flattened = input.flattening()
    /// // Result:
    /// // [
    /// //   "0.a": 1,
    /// //   "1.b.0": 2,
    /// //   "1.b.1": 3
    /// // ]
    /// ```
    ///
    /// - Parameter prefix: A string to prefix all resulting keys with (used for recursion; default is empty).
    /// - Returns: A flattened `[String: Any]` dictionary with dot-separated key paths for array elements.
    /// - SeeAlso: ``Dictionary.flattening(prefix:)``
    func flattening(prefix: String = "") -> [String: Any] {
        var result: [String: Any] = [:]

        for (index, element) in enumerated() {
            let path = prefix.isEmpty ? "\(index)" : "\(prefix).\(index)"

            switch element {
            case let dict as [String: Any]:
                result.merge(dict.flattening(prefix: path)) { _, new in new }

            case let subArray as [Any]:
                result.merge(subArray.flattening(prefix: path)) { _, new in new }

            default:
                result[path] = element
            }
        }
        return result
    }
}
