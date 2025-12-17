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

import AEPServices
import Foundation

/// A protocol that enables conversion of conforming types into `AnyCodable` format.
public protocol AnyCodableComparable {
    /// Converts the conforming type to an optional `AnyCodable` instance.
    ///
    /// - Returns: An optional `AnyCodable` instance representing the conforming type, or `nil` if the conversion fails.
    func toAnyCodable() -> AnyCodable?
}

extension Optional: AnyCodableComparable where Wrapped: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        switch self {
        case .some(let value):
            return value.toAnyCodable()
        case .none:
            return nil
        }
    }
}

/// Enables direct comparison of `[String: Any]` dictionaries.
extension Dictionary: AnyCodableComparable where Key == String, Value: Any {
    public func toAnyCodable() -> AnyCodable? {
        // Use AnyCodable initializer directly to avoid unnecessary Optional wrapping
        return AnyCodable(self)
    }
}

/// Enables comparison of Strings, with automatic JSON parsing.
///
/// If the string contains valid JSON, it is parsed into `AnyCodable` structure (Object/Array).
/// Otherwise, it is treated as a raw string value.
extension String: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        // Try to parse as JSON first
        if let data = self.data(using: .utf8),
           let anyCodable = try? JSONDecoder().decode(AnyCodable.self, from: data) {
            return anyCodable
        }
        // Fallback to raw string
        return AnyCodable(self)
    }
}

extension AnyCodable: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        return self
    }
}

/// Enables comparison of `NetworkRequest` objects by extracting their payload.
///
/// This implementation parses the `connectPayload` property as a dictionary.
extension NetworkRequest: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        guard let payloadAsDictionary = try? JSONSerialization.jsonObject(with: self.connectPayload, options: []) as? [String: Any] else {
            return nil
        }
        return payloadAsDictionary.toAnyCodable()
    }
}
