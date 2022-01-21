/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import AEPServices

extension Dictionary where Key == String, Value == Any {
    /// Flattens the dictionary then calls `fnv1a32_inner`.
    ///
    /// The `mask`, if provided, determines which key-value pairs in the dictionary will be used
    /// to generate the hash.
    /// If `mask` is `nil`, all key-value pairs in the dictionary will be used.
    ///
    /// The method for generating the hash does not recurse through the dictionary,
    /// so flattening the dictionary first will ensure there are no nested containers as values.
    ///
    /// - Parameter mask: an array of `String`s that will be used to determine which KVPs are in the hash.
    /// - Returns an unsigned integer hash that represents the requested data in the dictionary.
    func fnv1a32(mask: [String]? = nil) -> UInt32 {
        return self.flattening().fnv1a32_inner(mask: mask)
    }

    // swiftlint:disable function_body_length
    /// processes the flattened dictionary
    private func fnv1a32_inner(mask: [String]? = nil) -> UInt32 {
        var alphabeticalKeys: [String]
        // if a mask is provided, only use keys in the provided mask and alphabetize their order
        if let mask = mask {
            alphabeticalKeys = self.keys.filter({ mask.contains($0) }).sorted()
        } else {
            alphabeticalKeys = self.keys.sorted()
        }

        var hash: UInt32 = 0
        for i in 0..<alphabeticalKeys.count {
            let key = alphabeticalKeys[i]
            var valueAsString = ""
            if let value = self[key] {
                switch value.self {
                case is String:
                    valueAsString = String(describing: (value as! String))
                case is Character:
                    valueAsString = String(describing: (value as! Character))
                case is Int:
                    valueAsString = String(describing: (value as! Int))
                case is Int8:
                    valueAsString = String(describing: (value as! Int8))
                case is Int16:
                    valueAsString = String(describing: (value as! Int16))
                case is Int32:
                    valueAsString = String(describing: (value as! Int32))
                case is Int64:
                    valueAsString = String(describing: (value as! Int64))
                case is UInt:
                    valueAsString = String(describing: (value as! UInt))
                case is UInt8:
                    valueAsString = String(describing: (value as! UInt8))
                case is UInt16:
                    valueAsString = String(describing: (value as! UInt16))
                case is UInt32:
                    valueAsString = String(describing: (value as! UInt32))
                case is UInt64:
                    valueAsString = String(describing: (value as! UInt64))
                case is Float:
                    valueAsString = String(describing: (value as! Float))
                case is Double:
                    valueAsString = String(describing: (value as! Double))
                case is Bool:
                    valueAsString = String(describing: (value as! Bool))
                case is AnyCodable:
                    if let codableValue = (value as? AnyCodable)?.value {
                        valueAsString = String(describing: codableValue)
                    }
                default:
                    valueAsString = String(describing: value)
                }
            }

            if !valueAsString.isEmpty {
                let kvpString = key + ":" + valueAsString
                hash = kvpString.fnv1a32(hash)
            }
        }

        return hash
    }
    // swiftlint:enable function_body_length
}
