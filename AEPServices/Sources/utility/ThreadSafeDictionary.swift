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

/// A thread safe reference type dictionary
public final class ThreadSafeDictionary<K: Hashable, V> {
    public typealias Element = Dictionary<K, V>.Element
    @usableFromInline internal var dictionary = [K: V]()
    @usableFromInline internal let queue: DispatchQueue

    /// Creates a new thread safe dictionary
    /// - Parameter identifier: A unique identifier for this dictionary, a reverse-DNS naming style (com.example.myqueue) is recommended
    public init(identifier: String = "com.adobe.threadsafedictionary.queue") {
        queue = DispatchQueue(label: identifier)
    }

    /// How many key pair values are preset in the dictionary
    public var count: Int {
        return queue.sync { return self.dictionary.keys.count }
    }

    /// A collection containing just the keys of the dictionary.
    public var keys: [K] {
        return queue.sync { return Array(self.dictionary.keys) }
    }
    
    /// A collection containing the values of the dictionary.
    public var values: [V] {
        return queue.sync { Array(dictionary.values) }
    }
    
    /// A boolean to check if dictionary is empty or not.
    public var isEmpty: Bool {
        return queue.sync { dictionary.isEmpty }
    }

    // Gets a non-thread-safe shallow copy of the backing dictionary
    public var shallowCopy: [K: V] {
        return queue.sync {
            let dictionary = self.dictionary
            return dictionary
        }
    }

    // MARK: Subscript

    public subscript(key: K) -> V? {
        get {
            return queue.sync { return self.dictionary[key] }
        }
        set {
            queue.async {
                self.dictionary[key] = newValue
            }
        }
    }

    @inlinable public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return queue.sync { return try? self.dictionary.first(where: predicate) }
    }

    @inlinable public func removeValue(forKey key: K) -> V? {
        return queue.sync {
            return self.dictionary.removeValue(forKey: key)
        }
    }
    
    @inlinable public func filter(_ isIncluded: (Element) -> Bool) -> ThreadSafeDictionary<K, V> {
        let filteredDictionary = ThreadSafeDictionary<K, V>()
        queue.sync {
            for (key, value) in dictionary where isIncluded((key, value)) {
                filteredDictionary[key] = value
            }
        }
        return filteredDictionary
    }
    
    @inlinable public func contains(where predicate: (Element) -> Bool) -> Bool {
        return queue.sync {
            return dictionary.contains(where: predicate)
        }
    }
    
    @inlinable public func removeAll() {
        queue.async {
            self.dictionary.removeAll()
        }
    }
    
    @inlinable public func merge(_ other: [K: V], uniquingKeysWith combine: @escaping (V, V) -> V) {
        queue.async {
            self.dictionary.merge(other, uniquingKeysWith: combine)
        }
    }
    
}

extension ThreadSafeDictionary: Codable where K: Codable, V: Codable {
    // Encode function for Encodable conformance
    public func encode(to encoder: Encoder) throws {
        try queue.sync {
            var container = encoder.singleValueContainer()
            try container.encode(dictionary)
        }
    }

    // Decode initializer for Decodable conformance
    public convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.singleValueContainer()
        let decodedDictionary = try container.decode([K: V].self)
        
        queue.sync {
            self.dictionary = decodedDictionary
        }
    }
}
