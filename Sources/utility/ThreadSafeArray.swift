//
//  ThreadSafeArray.swift
//  AEPCore
//
//  Created by Christopher Hoffman on 6/2/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import Foundation

/// A thread safe reference type array
final class ThreadSafeArray<T> {
    private var array: [T] = []
    private var queue: DispatchQueue
    
    /// Creates a new thread safe array
    /// - Parameter identifier: A unique identifier for this array, a reverse-DNS naming style (com.example.myqueue) is recommended
    init(identifier: String = "com.adobe.threadsafearray.queue") {
        queue = DispatchQueue(label: identifier)
    }
    
    /// Appends a new element safetly to the array
    func append(newElement: T) {
        queue.async {
            self.array.append(newElement)
        }
    }
    
    /// The number of elements in the array
    var count: Int {
        return queue.sync { return self.array.count }
    }
    
    var nonThreadSafeArray: [T] {
        return queue.sync {
            self.array
        }
    }
    
    // MARK: - Subscript
    subscript(index: Int) -> T {
        get {
            queue.sync {
                return self.array[index]
            }
        }
        set {
            queue.async {
                self.array[index] = newValue
            }
        }
    }
}
