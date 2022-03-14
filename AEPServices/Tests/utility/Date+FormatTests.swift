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

import XCTest

@testable import AEPServices

class DateFormatTests: XCTestCase {
    
    func testGetUnixTimeInSeconds() {
        // setup
        let victory: Int64 = 1391373045000 // Feb 2, 2014 8:30:45 pm MST
        let date = Date(milliseconds: victory)
        
        // test
        let result = date.getUnixTimeInSeconds()
        
        // verify
        XCTAssertEqual(victory, result * 1000)
    }
    
    func testGetISO8601Date() {
        // setup
        let tzOffset = TimeZone.current.secondsFromGMT()
        let victory: Int64 = Int64(tzOffset * 1000) + 1391398245000 // Feb 2, 2014 8:30:45 pm MST
        let date = Date(milliseconds: victory)
        let expectedDateString = getLocalExpectedDateStringFrom(date) + timezoneStringWithColon
        
        // test
        let result = date.getISO8601Date()
        
        // verify
        XCTAssertEqual(expectedDateString, result)
    }
    
    func testGetISO8601DateNoColon() {
        // setup
        let tzOffset = TimeZone.current.secondsFromGMT()
        let victory: Int64 = Int64(tzOffset * 1000) + 1391398245000 // Feb 2, 2014 8:30:45 pm MST
        let date = Date(milliseconds: victory)
        let expectedDateString = getLocalExpectedDateStringFrom(date) + timezoneString
        
        // test
        let result = date.getISO8601DateNoColon()

        // verify
        XCTAssertEqual(expectedDateString, result)
    }
    
    func testGetISO8601DateUTCInMilliseconds() {
        let date = Date(milliseconds: 1391398245203) // Feb 2, 2014 20:30:45.203 MST
        let result = date.getISO8601DateInMillisecondsUTC()
        // MST -> UTC = +7 hours
        XCTAssertEqual("2014-02-03T03:30:45.203Z", result)
    }
    
    // MARK: - Helpers

    /// [milliseconds offset from GMT : hours offset from GMT]
    let timezoneMapper: [Int:String] = [
        43200: "+1200",
        39600: "+1100",
        36000: "+1000",
        32400: "+0900",
        28800: "+0800",
        25200: "+0700",
        21600: "+0600",
        18000: "+0500",
        14400: "+0400",
        10800: "+0300",
        7200: "+0200",
        3600: "+0100",
        0: "Z",
        -3600: "-0100",
        -7200: "-0200",
        -10800: "-0300",
        -14400: "-0400",
        -18000: "-0500",
        -21600: "-0600",   // US Mountain Daylight
        -25200: "-0700",   // US Mountain Standard, US Pacific Daylight
        -28800: "-0800",   // US Pacific Standard
        -32400: "-0900",
        -36000: "-1000",
        -39600: "-1100",
        -43200: "-1200",
    ]
    
    let timezoneMapperWithColon: [Int:String] = [
        43200: "+12:00",
        39600: "+11:00",
        36000: "+10:00",
        32400: "+09:00",
        28800: "+08:00",
        25200: "+07:00",
        21600: "+06:00",
        18000: "+05:00",
        14400: "+04:00",
        10800: "+03:00",
        7200: "+02:00",
        3600: "+01:00",
        0: "Z",
        -3600: "-01:00",
        -7200: "-02:00",
        -10800: "-03:00",
        -14400: "-04:00",
        -18000: "-05:00",
        -21600: "-06:00",   // US Mountain Daylight
        -25200: "-07:00",   // US Mountain Standard, US Pacific Daylight
        -28800: "-08:00",   // US Pacific Standard
        -32400: "-09:00",
        -36000: "-10:00",
        -39600: "-11:00",
        -43200: "-12:00",
    ]
    
    var timezoneString: String {
        if TimeZone.current.isDaylightSavingTime() {
            return timezoneMapper[TimeZone.current.secondsFromGMT() - 3600] ?? ""
        } else {
            return timezoneMapper[TimeZone.current.secondsFromGMT()] ?? ""
        }
    }
    
    var timezoneStringWithColon: String {
        if TimeZone.current.isDaylightSavingTime() {
            return timezoneMapperWithColon[TimeZone.current.secondsFromGMT() - 3600] ?? ""
        } else {
            return timezoneMapperWithColon[TimeZone.current.secondsFromGMT()] ?? ""
        }
    }
    
    func getLocalExpectedDateStringFrom(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "YYYY"
        let year = formatter.string(from: date)
        formatter.dateFormat = "MM"
        let month = formatter.string(from: date)
        formatter.dateFormat = "dd"
        let day = formatter.string(from: date)
        formatter.dateFormat = "HH"
        let hours = formatter.string(from: date)
        formatter.dateFormat = "mm"
        let minutes = formatter.string(from: date)
        formatter.dateFormat = "ss"
        let seconds = formatter.string(from: date)
        
        return "\(year)-\(month)-\(day)T\(hours):\(minutes):\(seconds)"
    }
}
