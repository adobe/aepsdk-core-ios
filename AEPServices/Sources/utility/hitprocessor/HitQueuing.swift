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

/// A class of types who provide the functionality for queuing hits
public protocol HitQueuing {
    /// The processor responsible for implementing the logic for processing an individual hit
    var processor: HitProcessing { get }

    /// Queues a `DataEntity` to be processed
    /// - Parameters:
    ///   - entity: the entity to be processed
    /// - Returns: True if queuing the entity was successful, false otherwise
    @discardableResult
    func queue(entity: DataEntity) -> Bool

    /// Puts the queue in non-suspended state and begins processing hits
    func beginProcessing()

    /// Puts the queue in a suspended state and discontinues hit processing
    func suspend()

    /// Removes all the persisted hits from the queue
    func clear()

    /// Returns the number of items in the queue
    func count() -> Int

    /// Closes the curernt `HitQueuing`
    func close()
}
