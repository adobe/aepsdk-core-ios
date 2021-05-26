//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

/// Helper functions for XDM formatting
public enum XDMFormatters {

    /// Serialize the given Date to a string formatted to an ISO 8601 date-time as defined in
    /// <a href="https://tools.ietf.org/html/rfc3339#section-5.6">RFC 3339, section 5.6</a>
    /// For example, 2017-09-26T15:52:25-07:00
    /// - Parameters:
    ///   - Date: A timestamp and it must not be null
    /// - Returns: The timestamp formatted to a string in the format of 'yyyy-MM-dd'T'HH:mm:ssXXX',
    ///            or an empty string if Date  is null
    public static func dateToISO8601String(from: Date?) -> String? {
        if let unwrapped = from {
            return unwrapped.asISO8601String()
        } else {
            return nil
        }
    }

    /// Serialize the given Date to a string formatted to an ISO 8601 date as defined in
    /// <a href="https://tools.ietf.org/html/rfc3339#section-5.6">RFC 3339, section 5.6</a>
    /// For example, 2017-09-26
    /// - Parameters:
    ///   - Date:  A timestamp and it must not be null
    /// - Returns: The timestamp formatted to a string in the format of 'yyyy-MM-dd',
    ///            or an empty string if Date  is null
    public static func dateToFullDateString(from: Date?) -> String? {
        if let unwrapped = from {
            return unwrapped.asFullDate()
        } else {
            return nil
        }
    }
}

private extension Date {
    func asISO8601String() -> String {
        return ISO8601DateFormatter().string(from: self)
    }

    func asFullDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.string(from: self)
    }
}
