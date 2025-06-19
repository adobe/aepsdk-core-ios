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
    /// Recursively flattens a `[String: Any]` dictionary into a single-level dictionary with dot separated keys.
    ///
    /// - Nested dictionaries and arrays are flattened into key paths where each segment is separated by a dot (`.`).
    /// - Dictionary keys are appended directly to the path.
    /// - Array indexes are included in the path as numeric segments (ex: `array.0.key`).
    /// - This method does not escape dots (`.`) in dictionary key names. If two distinct keys flatten to the same path, later entries overwrite earlier ones, but the order is undefined.
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
    /// - Parameter prefix: A string to prefix all resulting keys with (used for recursion; default is empty).
    /// - Returns: A flattened `[String: Any]` dictionary with dot separated key paths.
    /// - SeeAlso: ``Array.flattening(prefix:)``
    func flattening(prefix: String = "") -> [String: Any] {
        var result: [String: Any] = [:]
        let keyPrefix = prefix.isEmpty ? "" : "\(prefix)."

        for (key, value) in self {
            let path = "\(keyPrefix)\(key)"
            switch value {
            case let dict as [String: Any]:
                result.merge(dict.flattening(prefix: path)) { _, new in new }

            case let array as [Any]:
                result.merge(array.flattening(prefix: path)) { _, new in new }

            default:
                result[path] = value
            }
        }
        return result
    }
}
