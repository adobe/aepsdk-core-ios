/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import Foundation

extension Event {
    /// Returns an ``EventHistoryRequest`` based on this event's ``Event/data``, applying the ``Event/mask`` if one is set.
    ///
    /// - Parameters:
    ///   - from: The start date of the range to use for historical lookup. If `nil`, the lookup starts from the earliest available event.
    ///   - to: The end date of the range to use for historical lookup. If `nil`, the lookup includes events up to the most recent.
    /// - Returns: An ``EventHistoryRequest`` with the ``EventHistoryRequest/mask`` derived from this event's ``Event/data``, filtered by its event ``Event/mask`` if set.
    public func toEventHistoryRequest(from: Date? = nil, to: Date? = nil) -> EventHistoryRequest {
        let flattenedData = data?.flattening() ?? [:]

        // Filter the flattened data based on mask if provided
        let filteredData: [String: Any]
        if let mask = self.mask {
            // Convert mask array to a set for O(1) lookups
            let maskSet = Set(mask)
            filteredData = flattenedData.filter { maskSet.contains($0.key) }
        } else {
            // If no mask is provided, use all the data
            filteredData = flattenedData
        }

        return EventHistoryRequest(mask: filteredData, from: from, to: to)
    }
}
