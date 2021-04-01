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

/// A type erasing struct that can allow for dynamic `Codable` types
public struct AnyCodable: Codable {
    public var value: Any? {
        return _value is NSNull ? nil : _value
    }

    private let _value: Any

    public var stringValue: String? {
        return value as? String
    }

    public var boolValue: Bool? {
        return value as? Bool
    }

    public var intValue: Int? {
        return value as? Int
    }

    public var longValue: Int64? {
        return value as? Int64
    }

    public var floatValue: Float? {
        return value as? Float
    }

    public var doubleValue: Double? {
        return value as? Double
    }

    public var arrayValue: [Any]? {
        return value as? [Any]
    }

    public var dictionaryValue: [String: Any]? {
        return value as? [String: Any]
    }

    public var dataValue: Data? {
        return value as? Data
    }

    public init(_ value: Any?) {
        self._value = value ?? NSNull()
    }

    public static func from(dictionary: [String: Any?]?) -> [String: AnyCodable]? {
        guard let unwrappedDict = dictionary else { return nil }

        var newDict: [String: AnyCodable] = [:]
        for (key, val) in unwrappedDict {
            if let anyCodableVal = val as? AnyCodable {
                newDict[key] = anyCodableVal
            } else {
                newDict[key] = AnyCodable(val)
            }
        }

        return newDict
    }

    public static func toAnyDictionary(dictionary: [String: AnyCodable]?) -> [String: Any]? {
        guard let unwrappedDict = dictionary else { return nil }
        return unwrappedDict.filter { $0.value != nil }.mapValues { $0.value! }
    }

    // MARK: - Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let long = try? container.decode(Int64.self) {
            self.init(long)
        } else if let float = try? container.decode(Float.self) {
            self.init(float)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else if container.decodeNil() {
            self.init(nil)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to decode AnyCodable")
        }
    }

    // MARK: - Codable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch _value {
        case is NSNull:
            try container.encodeNil()
        case is Void:
            try container.encodeNil()
        case let num as NSNumber:
            try encode(nsNumber: num, into: &container)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let float as Float:
            try container.encode(float)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            print("AnyCodable - encode: Failed to encode \(String(describing: _value))")
        }
    }

    private func encode(nsNumber: NSNumber, into container: inout SingleValueEncodingContainer) throws {
        switch CFNumberGetType(nsNumber) {
        case .charType:
            try container.encode(nsNumber.boolValue)
        case .sInt8Type:
            try container.encode(nsNumber.int8Value)
        case .sInt16Type:
            try container.encode(nsNumber.int16Value)
        case .sInt32Type:
            try container.encode(nsNumber.int32Value)
        case .sInt64Type:
            try container.encode(nsNumber.int64Value)
        case .shortType:
            try container.encode(nsNumber.uint16Value)
        case .longType:
            try container.encode(nsNumber.uint32Value)
        case .longLongType:
            try container.encode(nsNumber.uint64Value)
        case .intType, .nsIntegerType, .cfIndexType:
            try container.encode(nsNumber.intValue)
        case .floatType, .float32Type:
            try container.encode(nsNumber.floatValue)
        case .doubleType, .float64Type, .cgFloatType:
            try container.encode(nsNumber.doubleValue)
        @unknown default:
            print("AnyCodable - encode: Failed to encode NSNumber \(String(describing: value))")
        }
    }
}

// MARK: - Literal extensions

extension AnyCodable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }

    public init(longLiteral value: Int64) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        let dict = [String: Any](elements, uniquingKeysWith: { key, _ in key })
        self.init(dict)
    }
}

extension AnyCodable: ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) {
        self.init(nil)
    }
}

// MARK: - Equatable

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        if lhs.value == nil, rhs.value == nil {
            return true
        }

        switch (lhs.value, rhs.value) {
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return lhs == rhs
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

// MARK: Codable Helpers
extension Encodable {
    public func asDictionary(dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate
    ) -> [String: Any]? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dateEncodingStrategy
        guard let data = try? encoder.encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
