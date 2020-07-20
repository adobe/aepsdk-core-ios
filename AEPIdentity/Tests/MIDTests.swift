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
@testable import AEPIdentity

class MIDTests: XCTestCase {
    
    /// Ensures that an MID has a length of 38
    func testMIDCorrectLength() {
        // test
        let mid = MID()
        
        // verify
        XCTAssertEqual(38, mid.midString.count)
    }
    
    /// MID should only contain numbers
    func testMIDContainsOnlyNumbers() {
        // test
        let mid = MID()
        
        // verify
        let isNumeric = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: mid.midString))
        XCTAssertTrue(isNumeric)
    }
    
    /// MID should be reasonably random
    func testMIDReasonablyRandom() {
        // setup
        let count = 1000
        var mids = Set<MID>()
        
        // test
        for _ in 0..<count {
            mids.insert(MID())
        }
        
        // verify
        XCTAssertEqual(count, mids.count)
    }
}
