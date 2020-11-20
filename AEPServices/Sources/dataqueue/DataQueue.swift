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

/// A thread-safe FIFO (First-In-First-Out) queue used to store `DataEntity` objects
@objc(AEPDataQueue) public protocol DataQueue {
    /// Adds a new `DataEntity` object to `DataQueue`
    /// - Parameter dataEntity: a `DataEntity` object
    @discardableResult
    func add(dataEntity: DataEntity) -> Bool

    /// Retrieves the head of this `DataQueue`, else return nil if the `DataQueue` is empty
    func peek() -> DataEntity?

    /// Retrieves the first `n` entries in this `DataQueue`, else return nil if the `DataQueue` is empty
    func peek(n: Int) -> [DataEntity]?

    /// Removes the head of this `DataQueue`
    @discardableResult
    func remove() -> Bool

    /// Removes the first `n` entities in this `DataQueue`
    @discardableResult
    func remove(n: Int) -> Bool

    /// Removes all stored `DataEntity` object
    @discardableResult
    func clear() -> Bool

    /// Returns the number of `DataEntity` objects in the DataQueue
    func count() -> Int

    /// Closes the current `DataQueue`
    func close()
}
