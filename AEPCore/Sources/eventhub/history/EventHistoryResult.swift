/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Passed to handlers by `EventHistory` when Events are requested via `getEvents` API.
@objc (AEPEventHistoryResult)
public class EventHistoryResult: NSObject {
    /// The number of occurrences in `EventHistory` of the `EventHistoryRequest` specified.
    @objc public let count: Int

    /// A date representing the oldest occurrence of the event found in `EventHistory`.
    ///
    /// If `count` == 0, this value will be nil.
    @objc public let oldestOccurrence: Date?

    /// A date representing the most recent occurrence of the event found in `EventHistory`.
    ///
    /// If `count` == 0, this value will be nil.
    @objc public let newestOccurrence: Date?

    /// Creates a new `EventHistoryResult` object.
    ///
    /// - Parameters:
    ///   - count: The number of occurrences in `EventHistory` of the `EventHistoryRequest` specified
    ///   - oldest: A date representing the oldest occurrence of the event found in `EventHistory`
    ///   - newest: A date representing the most recent occurrence of the event found in `EventHistory`
    @objc
    internal init(count: Int, oldest: Date? = nil, newest: Date? = nil) {
        self.count = count
        self.oldestOccurrence = oldest
        self.newestOccurrence = newest
    }
}
