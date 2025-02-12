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

    /// Returns the first element in the dictionary that satisfies the given predicate.
    /// - Parameter predicate: A throwing closure that takes a key-value pair and returns `true` if the element matches.
    /// - Returns: The first matching key-value pair, or `nil` if no match is found.
    @inlinable public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return queue.sync { return try? self.dictionary.first(where: predicate) }
    }

    /// Removes the value associated with the given key and returns it.
    /// - Parameter key: The key to remove.
    /// - Returns: The removed value if it exists, otherwise `nil`.
    @inlinable public func removeValue(forKey key: K) -> V? {
        return queue.sync {
            return self.dictionary.removeValue(forKey: key)
        }
    }
    
    /// Returns a new `Dictionary` containing only the elements that satisfy the given predicate.
    /// - Parameter isIncluded: A closure that takes a key-value pair and returns `true` if the element should be included.
    /// - Returns: A new `Dictionary` with the filtered elements.
    @inlinable public func filter(_ isIncluded: (Element) -> Bool) -> [K: V] {
        var filteredDictionary = [K: V]()
        queue.sync {
            for (key, value) in dictionary where isIncluded((key, value)) {
                filteredDictionary[key] = value
            }
        }
        return filteredDictionary
    }
    
    /// Checks if any element in the dictionary satisfies the given predicate.
    /// - Parameter predicate: A closure that takes a key-value pair and returns `true` if the condition is met.
    /// - Returns: `true` if any element satisfies the condition; otherwise, `false`.
    @inlinable public func contains(where predicate: (Element) -> Bool) -> Bool {
        return queue.sync {
            return dictionary.contains(where: predicate)
        }
    }
    
    /// Removes all key-value pairs from the dictionary asynchronously to avoid blocking.
    @inlinable public func removeAll() {
        queue.async {
            self.dictionary.removeAll()
        }
    }
    
    /// Merges another dictionary into this `ThreadSafeDictionary`, resolving key conflicts using a provided closure.
    /// - Parameters:
    ///   - other: The dictionary to merge.
    ///   - combine: A closure that determines how to resolve conflicts when the same key exists in both dictionaries.
    @inlinable public func merge(_ other: [K: V], uniquingKeysWith combine: @escaping (V, V) -> V) {
        queue.async {
            self.dictionary.merge(other, uniquingKeysWith: combine)
        }
    }
}
