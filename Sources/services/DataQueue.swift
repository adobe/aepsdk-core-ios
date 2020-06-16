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
public protocol DataQueue {
    /// adds a new `DataEntity` object to `DataQueue`
    ///
    /// - Parameter dataEntity: a `DataEntity` object
    func add(dataEntity: DataEntity) -> Bool

    /// Returns the `DataEntity` object at the top of the `DataQueue`, else return nil if the `DataQueue` is empty
    func peek() -> DataEntity?

    /// Returns the `DataEntity` object at the top of the `DataQueue` and then remove it from the `DataQueue`, else return nil if the `DataQueue` is empty
    func pop() -> DataEntity?

    /// Clear all stored `DataEntity` object
    func clear() -> Bool
}
