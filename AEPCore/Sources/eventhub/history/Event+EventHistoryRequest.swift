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
    /// Creates an `EventHistoryRequest` from this event.
    /// 
    /// - Parameters:
    ///   - from: Date that represents the lower bounds of the date range used when looking up an Event
    ///   - to: Date that represents the upper bounds of the date range used when looking up an Event
    /// - Returns: An `EventHistoryRequest` with mask derived from this event's data
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
