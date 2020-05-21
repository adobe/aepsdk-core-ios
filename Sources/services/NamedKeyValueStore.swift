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
public class NamedKeyValueStore {

    private var storageService: NamedKeyValueService
    private var name: String
    
    init(name: String) {
        self.storageService = AEPServiceProvider.shared.namedKeyValueService
        self.name = name
    }

    subscript(key: String) -> Int? {
        get {
            return getInt(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func set(key: String, value: Int?) {
        set(key: key, value: value as Any?)
    }

    func getInt(key: String, fallback: Int? = nil) -> Int? {
        return get(key: key) as? Int ?? fallback
    }
    
    subscript(key: String) -> String? {
        get {
            return getString(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func set(key: String, value: String?) {
        set(key: key, value: value as Any?)
    }

    func getString(key: String, fallback: String? = nil) -> String? {
        return get(key: key) as? String ?? fallback
    }
    
    subscript(key: String) -> Double? {
        get {
            return getDouble(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func set(key: String, value: Double?) {
        set(key: key, value: value as Any?)
    }
    
    func getDouble(key: String, fallback: Double? = nil) -> Double? {
        return get(key: key) as? Double ?? fallback
    }
    
    subscript(key: String) -> Int64? {
        get {
            return getLong(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func set(key: String, value: Int64?) {
        set(key: key, value: value as Any?)
    }
    
    func getLong(key: String, fallback: Int64? = nil) -> Int64? {
        return get(key: key) as? Int64 ?? fallback
    }
    
    subscript(key: String) -> Float? {
        get {
            return getFloat(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func set(key: String, value: Float?) {
        set(key: key, value: value as Any?)
    }
    
    func getFloat(key: String, fallback: Float? = nil) -> Float? {
        return get(key: key) as? Float ?? fallback
    }
    
    func set(key: String, value: Bool?) {
        set(key: key, value: value as Any?)
    }
    
    subscript(key: String) -> Bool? {
        get {
            return getBool(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func getBool(key: String, fallback: Bool? = nil) -> Bool? {
        return get(key: key) as? Bool ?? fallback
    }
    
    
    subscript(key: String) -> [Any]? {
        get {
            return getArray(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func set(key: String, value: [Any]?) {
        set(key: key, value: value as Any)
    }
    
    func getArray(key: String, fallback: [Any]? = nil) -> [Any]? {
        return get(key: key) as? [Any] ?? fallback
    }
    
    subscript(key: String) -> [AnyHashable: Any]? {
        get {
            return getDictionary(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func set(key: String, value: [AnyHashable: Any]?) {
        set(key: key, value: value as Any)
    }
    
    func getDictionary(key: String, fallback: [AnyHashable: Any]? = nil) -> [AnyHashable: Any]? {
        return get(key: key) as? [AnyHashable: Any] ?? fallback
    }
    
    subscript<T: Codable>(key: String) -> T? {
        get {
            return getObject(key: key)
        }
        set {
            set(key: key, value: newValue)
        }
    }
    
    func setObject<T: Codable>(key: String, value: T) {
        let encoder = JSONEncoder()
        let encodedValue = try? encoder.encode(value)
        set(key: key, value: encodedValue)
    }
    
    func getObject<T: Codable>(key: String, fallback: T? = nil) -> T? {
        if let savedData = get(key: key) as? Data {
            return try? JSONDecoder().decode(T.self, from: savedData)
        }
        
        return fallback
    }

    func contains(key: String) -> Bool {
        return (get(key: key) != nil) ? true : false
    }
    
    func remove(key: String) {
        if key.isEmpty {
            return
        }
        
        storageService.remove(collectionName: self.name, key: key)
    }
    
    func removeAll() {
        storageService.removeAll(collectionName: self.name)
    }

    func set(key: String, value: Any?) {
        if key.isEmpty {
            return
        }
        storageService.set(collectionName: self.name, key: key, value: value)
    }

    private func get(key: String) -> Any? {
        if key.isEmpty {
           return nil
        }
        return storageService.get(collectionName: self.name, key: key)
    }
}
