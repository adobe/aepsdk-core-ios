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

/// Provides functions to percent encode and decode a `String`
public struct URLEncoder {
    /// Percent encodes a `String`
    /// - Parameter value: the `String` to be encoded
    /// - Returns: The percent encoded `String`, empty if encoding failed
    public static func encode(value: String) -> String {
        let unreserved = "-._~"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return value.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet) ?? ""
    }

    /// Percent decodes a `String`
    /// - Parameter value: the `String` to be decoded
    /// - Returns: The percent decoded `String`, empty if decoding failed
    public static func decode(value: String) -> String {
        return value.removingPercentEncoding ?? ""
    }
}
