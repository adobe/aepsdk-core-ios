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

/// A namespacing wrapper that provides Adobe Experience Platform Mobile SDK helper functionality.
///
/// Accessed via the `.aep` computed property.
public struct AEPNamespace<Base> {
    /// The wrapped instance for instance-level helpers.
    public let base: Base

    /// Initializes a new `AEPNamespace` with the given base value.
    /// - Parameter base: The value to wrap.
    fileprivate init(_ base: Base) {
        self.base = base
    }
}

// MARK: - Namespace Accessors

public extension Encodable {
    /// Provides an Adobe Experience Platform helper namespace for the current instance.
    ///
    /// Use this property to access instance-level convenience methods.
    ///
    /// Example:
    /// ```swift
    /// let dict = model.aep.dictionary()
    /// ```
    var aep: AEPNamespace<Self> {
        .init(self)
    }
}

public extension Decodable {
    /// Provides an Adobe Experience Platform helper namespace for the type itself.
    ///
    /// Use this property to access type-level convenience methods.
    ///
    /// Example:
    /// ```swift
    /// let model = MyType.aep.from(dictionary)
    /// ```
    static var aep: AEPNamespace<Self>.Type {
        AEPNamespace<Self>.self
    }
}

// Encodable helper
public extension AEPNamespace where Base: Encodable {
    /// Converts the current value into a `[String: Any]` dictionary.
    ///
    /// This method encodes the instance using `JSONEncoder`, then converts
    /// the resulting `Data` into a top-level JSON dictionary.
    ///
    /// - Parameter dateEncodingStrategy: Strategy for encoding `Date` values.
    ///   Defaults to `.deferredToDate`.
    /// - Returns: A `[String: Any]` dictionary representation of the value,
    ///   or `nil` if encoding or serialization fails.
    func dictionary(
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate
    ) -> [String: Any]? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dateEncodingStrategy
        guard let data = try? encoder.encode(base) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

// Decodable helper
public extension AEPNamespace where Base: Decodable {
    /// Creates a new instance of the type from a `[String: Any]` dictionary.
    ///
    /// This method converts the dictionary to `Data` using `JSONSerialization`,
    /// then attempts to decode it using a `JSONDecoder`.
    ///
    /// - Parameters:
    ///   - dictionary: The input dictionary to decode from.
    ///   - dateDecodingStrategy: Strategy for decoding `Date` values.
    ///     Defaults to `.deferredToDate`.
    /// - Returns: A decoded instance of the type, or `nil` if decoding fails.
    static func from(
        _ dictionary: [String: Any],
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) -> Base? {
        guard JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try? decoder.decode(Base.self, from: data)
    }
}
