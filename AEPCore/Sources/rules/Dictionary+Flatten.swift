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
    /// Returns a "flattened" `Dictionary` which will not contain any `Dictionary` as a value.
    /// For example, an input dictionary of:
    ///   `[rootKey: [key1: value1, key2: value2]]`
    /// will return a dictionary represented as:
    ///  `[rootKey.key1: value1, rootKey.key2: value2]`
    ///
    /// This method uses recursion.
    ///
    /// - Parameter prefix: a prefix to append to the front of the key
    /// - Returns: flattened dictionary
    func flattening(prefix: String = "") -> [String: Any] {
        let keyPrefix = (prefix.count > 0) ? (prefix + ".") : prefix
        var flattenedDict = [String: Any]()
        for (key, value) in self {
            let expandedKey = keyPrefix + key
            if let dict = value as? [String: Any] {
                flattenedDict.merge(dict.flattening(prefix: expandedKey)) { _, new in new }
            } else {
                flattenedDict[expandedKey] = value
            }
        }
        return flattenedDict
    }
}
