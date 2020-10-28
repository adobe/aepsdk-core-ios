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
        let victory: Int64 = 1391398245000 // Feb 2, 2014 8:30:45 pm
        let date = Date(milliseconds: victory)
        
        // test
        let result = date.getUnixTimeInSeconds()
        
        // verify
        XCTAssertEqual(victory, result * 1000)
    }
    
    func testGetRFC822Date() {
        // setup
        let victory: Int64 = 1391398245000 // Feb 2, 2014 8:30:45 pm
        let date = Date(milliseconds: victory)
        let expectedDateString = "2014-02-02T20:30:45" + timezoneString
        
        // test
        let result = date.getRFC822Date()
        
        // verify
        XCTAssertEqual(expectedDateString, result)
    }
    
    func testGetISO8601Date() {
        // setup
        let victory: Int64 = 1391398245000 // Feb 2, 2014 8:30:45 pm
        let date = Date(milliseconds: victory)
        let expectedDateString = "2014-02-02T20:30:45" + timezoneStringWithColon
        
        // test
        let result = date.getISO8601Date()
        
        // verify
        XCTAssertEqual(expectedDateString, result)
    }
    
    // MARK: - Helpers
    
    var timezoneString: String {
        if TimeZone.current.isDaylightSavingTime() {
            return timezoneMapper[TimeZone.current.secondsFromGMT() - 3600]!
        } else {
            return timezoneMapper[TimeZone.current.secondsFromGMT()]!
        }
    }
    
    var timezoneStringWithColon: String {
        if TimeZone.current.isDaylightSavingTime() {
            return timezoneMapperWithColon[TimeZone.current.secondsFromGMT() - 3600]!
        } else {
            return timezoneMapperWithColon[TimeZone.current.secondsFromGMT()]!
        }
    }
    
    /// [milliseconds offset from GMT : hours offset from GMT]
    let timezoneMapper: [Int:String] = [
        -21600: "-0600",   // US Mountain Standard
        -25200: "-0700",   // US Mountain Daylight, US Pacific Standard
        -28800: "-0800",   // US Pacific Daylight
    ]
    
    let timezoneMapperWithColon: [Int:String] = [
        -21600: "-06:00",   // US Mountain Standard
        -25200: "-07:00",   // US Mountain Daylight, US Pacific Standard
        -28800: "-08:00",   // US Pacific Daylight
    ]
}
