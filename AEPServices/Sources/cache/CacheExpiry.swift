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

/// Represents a cache expiry date
public enum CacheExpiry: Equatable {
    case never
    case seconds(TimeInterval)
    case date(Date)

    /// Returns the date associated with the expiry
    public var date: Date {
        switch self {
        case .never:
            // http://lists.apple.com/archives/cocoa-dev/2005/Apr/msg01833.html
            return Date(timeIntervalSince1970: 60 * 60 * 24 * 365 * 68)
        case let .seconds(seconds):
            return Date().addingTimeInterval(seconds)
        case let .date(date):
            return date
        }
    }

    /// Returns true if this cache expiry has expired
    public var isExpired: Bool {
        return date.timeIntervalSinceNow < 0
    }
}
