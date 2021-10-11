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

import XCTest

@testable import AEPCore

class EventHistoryResponseTests: XCTestCase {
    func testInit() throws {
        // setup
        let count = 552
        let oldest = Date(timeIntervalSince1970: 123456789)
        let newest = Date(timeIntervalSince1970: 234567890)
        
        // test
        let result = EventHistoryResult(count: count, oldest: oldest, newest: newest)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(count, result.count)
        XCTAssertEqual(oldest, result.oldestOccurrence)
        XCTAssertEqual(newest, result.newestOccurrence)
    }
    
    func testInitNilDates() throws {
        // setup
        let count = 0
        
        // test
        let result = EventHistoryResult(count: count)
        
        // verify
        XCTAssertNotNil(result)
        XCTAssertEqual(count, result.count)
        XCTAssertNil(result.oldestOccurrence)
        XCTAssertNil(result.newestOccurrence)
    }
}
