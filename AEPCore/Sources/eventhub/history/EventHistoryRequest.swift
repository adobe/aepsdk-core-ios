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

/// Used for selecting or deleting Events from Event History.
@objc (AEPEventHistoryRequest)
public class EventHistoryRequest: NSObject {
    /// Key-value pairs that will be used to generate the hash when looking up an Event.
    @objc public let mask: [String: Any]

    /// Date that represents the lower bounds of the date range used when looking up an Event.
    ///
    /// If not provided, the lookup will use the beginning of Event History as the lower bounds.
    @objc public let fromDate: Date?

    /// Date that represents the upper bounds of the date range used when looking up an Event.
    ///
    /// If not provided, there will be no upper bound on the date range.
    @objc public let toDate: Date?

    /// Initialize an `EventHistoryRequest` object.
    ///
    /// - Parameters:
    ///   - mask: Key-value pairs that will be used to generate the hash when looking up an Event
    ///   - from: Date that represents the lower bounds of the date range used when looking up an Event
    ///   - to: Date that represents the upper bounds of the date range used when looking up an Event
    @objc
    public init(mask: [String: Any], from: Date? = nil, to: Date? = nil) {
        self.mask = mask
        self.fromDate = from
        self.toDate = to
    }
}
