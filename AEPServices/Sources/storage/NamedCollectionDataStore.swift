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

/// The named key value storage object to be used to store and retrieve values
public class NamedCollectionDataStore {
    private var storageService: NamedCollectionProcessing {
        get { ServiceProvider.shared.namedKeyValueService }
    }
    private var name: String

    public init(name: String) {
        self.name = name
    }

    public subscript(key: String) -> Int? {
        get {
            return getInt(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func set(key: String, value: Int?) {
        set(key: key, value: value as Any?)
    }

    public func getInt(key: String, fallback: Int? = nil) -> Int? {
        return get(key: key) as? Int ?? fallback
    }

    public subscript(key: String) -> String? {
        get {
            return getString(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func set(key: String, value: String?) {
        set(key: key, value: value as Any?)
    }

    public func getString(key: String, fallback: String? = nil) -> String? {
        return get(key: key) as? String ?? fallback
    }

    public subscript(key: String) -> Double? {
        get {
            return getDouble(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func set(key: String, value: Double?) {
        set(key: key, value: value as Any?)
    }

    public func getDouble(key: String, fallback: Double? = nil) -> Double? {
        return get(key: key) as? Double ?? fallback
    }

    public subscript(key: String) -> Int64? {
        get {
            return getLong(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func set(key: String, value: Int64?) {
        set(key: key, value: value as Any?)
    }

    public func getLong(key: String, fallback: Int64? = nil) -> Int64? {
        return get(key: key) as? Int64 ?? fallback
    }

    public subscript(key: String) -> Float? {
        get {
            return getFloat(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func set(key: String, value: Float?) {
        set(key: key, value: value as Any?)
    }

    public func getFloat(key: String, fallback: Float? = nil) -> Float? {
        return get(key: key) as? Float ?? fallback
    }

    public func set(key: String, value: Bool?) {
        set(key: key, value: value as Any?)
    }

    public subscript(key: String) -> Bool? {
        get {
            return getBool(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func getBool(key: String, fallback: Bool? = nil) -> Bool? {
        return get(key: key) as? Bool ?? fallback
    }

    public subscript(key: String) -> [Any]? {
        get {
            return getArray(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func set(key: String, value: [Any]?) {
        set(key: key, value: value as Any)
    }

    public func getArray(key: String, fallback: [Any]? = nil) -> [Any]? {
        return get(key: key) as? [Any] ?? fallback
    }

    public subscript(key: String) -> [AnyHashable: Any]? {
        get {
            return getDictionary(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }

    public func set(key: String, value: [AnyHashable: Any]?) {
        set(key: key, value: value as Any)
    }

    public func getDictionary(key: String, fallback: [AnyHashable: Any]? = nil) -> [AnyHashable: Any]? {
        return get(key: key) as? [AnyHashable: Any] ?? fallback
    }

    public subscript<T: Codable>(key: String) -> T? {
        get {
            return getObject(key: key)
        }
        set {
            setObject(key: key, value: newValue)
        }
    }

    public func setObject<T: Codable>(key: String, value: T) {
        // https://bugs.swift.org/browse/SR-6163
        // JSON Encoder shipped as part of Swift standard library in iOS versions < 13 fails to encode top level fragments. Persist date as double in iOS versions < 13
        if T.self == Date.self, let value = value as? Date {
            guard #available(iOS 13.0, tvOS 13.0, *) else {
                set(key: key, value: value.timeIntervalSince1970)
                return
            }
        }

        let encoder = JSONEncoder()
        var setVal: Any?
        if let encodedValue = try? encoder.encode(value), let encodedString = String(data: encodedValue, encoding: .utf8) {
            setVal = encodedString
        }
        set(key: key, value: setVal)
    }

    public func getObject<T: Codable>(key: String, fallback: T? = nil) -> T? {
        // setObject persists date as double in iOS versions < 13.
        // Try reading date as double first to see if they were persisted from earlier OS versions.
        if T.self == Date.self, let date = getDouble(key: key) {
            return Date(timeIntervalSince1970: date) as? T
        }

        if let savedString = get(key: key) as? String, let savedData = savedString.data(using: .utf8) {
            return try? JSONDecoder().decode(T.self, from: savedData)
        }

        return fallback
    }

    public func contains(key: String) -> Bool {
        return (get(key: key) != nil) ? true : false
    }

    public func remove(key: String) {
        if key.isEmpty {
            return
        }

        storageService.remove(collectionName: name, key: key)
    }

    func set(key: String, value: Any?) {
        if key.isEmpty {
            return
        }

        storageService.set(collectionName: name, key: key, value: value)
    }

    private func get(key: String) -> Any? {
        if key.isEmpty {
            return nil
        }
        return storageService.get(collectionName: name, key: key)
    }
}
