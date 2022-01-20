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

class EventHistoryRequestTests: XCTestCase {
    func testInit() throws {
        // setup
        let mask: [String: Any] = ["key":"value"]
        let from = Date(timeIntervalSince1970: 123456789)
        let to = Date(timeIntervalSince1970: 234567890)
        
        // test
        let request = EventHistoryRequest(mask: mask, from: from, to: to)
        
        // verify
        XCTAssertNotNil(request)
        XCTAssertEqual(request.mask["key"] as? String, mask["key"] as? String)
        XCTAssertEqual(request.fromDate, from)
        XCTAssertEqual(request.toDate, to)
    }
    
    func testInitNilDates() throws {
        // setup
        let mask: [String: Any] = ["key":"value"]
        
        // test
        let request = EventHistoryRequest(mask: mask)
        
        // verify
        XCTAssertNotNil(request)
        XCTAssertEqual(request.mask["key"] as? String, mask["key"] as? String)
        XCTAssertNil(request.fromDate)
        XCTAssertNil(request.toDate)
    }
}
