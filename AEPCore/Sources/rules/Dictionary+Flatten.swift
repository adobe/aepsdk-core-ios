/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

extension Dictionary where Key == String, Value == Any {
    /// Recursively flattens a `[String: Any]` dictionary into a single-level dictionary with dot-separated key paths.
    ///
    /// - Keys from nested structures are concatenated using dots (`.`).
    /// - When `flattenArrays` is `false`, arrays are left as-is and stored under their current key path.
    /// - Key names are not escaped; if flattened keys collide, the last value written wins. The resolution order in this case is undefined and may change.
    ///
    /// ### Example
    /// ```swift
    /// let input: [String: Any] = [
    ///     "a": [
    ///         "b": [
    ///             "c": 1
    ///         ],
    ///         "d": [2, 3]
    ///     ],
    ///     "e": "value"
    /// ]
    /// let flattened = input.flattening()
    /// // Result:
    /// // [
    /// //   "a.b.c": 1,
    /// //   "a.d.0": 2,
    /// //   "a.d.1": 3,
    /// //   "e": "value"
    /// // ]
    /// ```
    ///
    /// - Parameters:
    ///   - prefix: Internal recursion parameter representing the key path prefix. Defaults to `""`.
    ///   - flattenArrays: Controls whether arrays are flattened (`true`) or preserved as-is (`false`). Defaults to `true`.
    /// - Returns: A single-level dictionary where keys represent the original structure via dot-separated paths.
    /// - SeeAlso: ``Array.flattening(prefix:)``
    func flattening(prefix: String = "", flattenArrays: Bool = true) -> [String: Any] {
        var result: [String: Any] = [:]
        let keyPrefix = prefix.isEmpty ? "" : "\(prefix)."

        for (key, value) in self {
            let path = "\(keyPrefix)\(key)"
            if let dict = value as? [String: Any] {
                result.merge(dict.flattening(prefix: path, flattenArrays: flattenArrays)) { _, new in new }
            } else if flattenArrays, let array = value as? [Any] {
                result.merge(array.flattening(prefix: path)) { _, new in new }
            } else {
                result[path] = value
            }
        }
        return result
    }
}
