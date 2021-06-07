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

/// A thread safe reference type array
public final class ThreadSafeArray<T> {
    private var array: [T] = []
    private var queue: DispatchQueue

    /// Creates a new thread safe array
    /// - Parameter identifier: A unique identifier for this array, a reverse-DNS naming style (com.example.myqueue) is recommended
    public init(identifier: String = "com.adobe.threadsafearray.queue") {
        queue = DispatchQueue(label: identifier)
    }

    /// Appends a new element to the thread safe array
    public func append(_ newElement: T) {
        queue.async {
            self.array.append(newElement)
        }
    }

    /// Clears the array by removing all elements
    public func clear() {
        queue.async {
            self.array.removeAll()
        }
    }

    /// Removes and returns the first element of the thread safe array.
    /// Returns nil if the array is empty
    public func removeFirst() -> T? {
        queue.sync {
            if array.isEmpty {
                return nil
            }
            return self.array.removeFirst()
        }
    }

    /// Returns if the array is empty or not
    public var isEmpty: Bool {
        return queue.sync { return self.array.isEmpty }
    }

    /// The number of elements in the array
    public var count: Int {
        return queue.sync { return self.array.count }
    }

    /// Gets a non thread safe shallow copy of the array
    public var shallowCopy: [T] {
        return queue.sync {
            // Copy the array to avoid cross threading issues
            let array = self.array
            return array
        }
    }

    // MARK: - Subscript

    public subscript(index: Int) -> T {
        get {
            queue.sync {
                self.array[index]
            }
        }
        set {
            queue.async {
                self.array[index] = newValue
            }
        }
    }
}

extension ThreadSafeArray where T: Equatable {
    /// Filters the `ThreadSafeArray` and removes the matching items from the underlying array.
    /// - Parameter isIncluded: A predicate closure that defines a match.
    /// - Returns: Array of objects matching the given predicate
    public func filterRemove(_ isIncluded: (T) throws -> Bool) -> [T] {
        queue.sync {
            let filteredValues = (try? self.array.filter(isIncluded)) ?? []
            self.array = self.array.filter { !filteredValues.contains($0) }
            return filteredValues
        }
    }
}
