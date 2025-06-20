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
    /// Recursively flattens an `[Any]` array into a single-level `[String: Any]` dictionary using dot-separated index paths.
    ///
    /// - Arrays are expanded into key paths where each index is used as a segment (e.g., `"0.key"`).
    /// - Key names are not escaped; if flattened keys collide, the last value written wins. The resolution order in this case is undefined and may change.
    ///
    /// ### Example
    /// ```swift
    /// let input: [Any] = [
    ///     ["dict": "value"],
    ///     ["array": [1, 2]]
    /// ]
    /// let flattened = input.flattening()
    /// // Result:
    /// // [
    /// //   "0.dict": "value",
    /// //   "1.array.0": 1,
    /// //   "1.array.1": 2
    /// // ]
    /// ```
    ///
    /// - Parameter prefix: Internal recursion parameter representing the key path prefix. Defaults to `""`.
    /// - Returns: A single-level dictionary where keys represent the original structure via dot-separated paths.
    /// - SeeAlso: ``Dictionary.flattening(prefix:)``
    func flattening(prefix: String = "") -> [String: Any] {
        var result: [String: Any] = [:]

        for (index, element) in enumerated() {
            let path = prefix.isEmpty ? "\(index)" : "\(prefix).\(index)"

            if let dict = element as? [String: Any] {
                result.merge(dict.flattening(prefix: path)) { _, new in new }
            } else if let array = element as? [Any] {
                result.merge(array.flattening(prefix: path)) { _, new in new }
            } else {
                result[path] = element
            }
        }
        return result
    }
}
