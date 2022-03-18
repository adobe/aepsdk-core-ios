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

public extension Date {

    /// Returns the number of seconds since the Unix Epoch on 1 January 1970.
    /// - Returns: the number of seconds since 1 January 1970.
    func getUnixTimeInSeconds() -> Int64 {
        return Int64(timeIntervalSince1970)
    }

    /// Returns a string representation of this Date formatted as an ISO 8601 date-time using system local time zone.
    /// For example, Oct. 28 2020 at 9:08:32.301 am PST is returned as `2020-10-28T09:08:32-08:00`
    /// - Returns: a string representation of the given Date formatted as an ISO 8601 date-time using system local time zone.
    func getISO8601Date() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions.insert(.withInternetDateTime)
        return formatter.string(from: self)
    }

    /// Returns a string representation of this Date formatted as an ISO 8601 date-time using system local time zone without colons.
    /// For example, Oct. 28 2020 at 9:08:32.301 am PST is returned as `2020-10-28T09:08:32-0800`
    /// - Returns: a string representation of the given Date formatted as an ISO 8601 date-time using system local time zone without colons.
    func getISO8601DateNoColon() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXX"
        return formatter.string(from: self)
    }

    /// Returns a string representation of this Date formatted as an ISO 8601 date-time with fractional seconds, using UTC time zone.
    /// Use this date format for timestamps send to the Adobe Experience Edge Network.
    /// For example, Oct. 28 2020 at 9:08:32.301 am PST is returned as `2020-10-28T17:08:32.301Z`
    /// - Returns: a string representation of the given Date formatted as an ISO 8601 date-time with fractional seconds using UTC time zone.
    func getISO8601UTCDateWithMilliseconds() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.string(from: self)
    }

    /// Returns a string representation of this Date formatted as an ISO 8601 date without time, using system local time zone.
    /// For example, Oct. 28 2020 at 9:08:32.301 am PST is returned as `2020-10-28`.
    /// - Returns: a string representation of this Date formatted as an ISO 8601 date without time, using system local time zone.
    func getISO8601FullDate() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.string(from: self)
    }
}
