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

@testable import AEPIdentity
import XCTest

class ECIDTests: XCTestCase {
    /// Ensures that an ECID has a length of 38
    func testECIDCorrectLength() {
        // test
        let ecid = ECID()

        // verify
        XCTAssertEqual(38, ecid.ecidString.count)
    }
    
    /// Ensures that an ECID has a length of 38
    func testECIDDescriptionCorrectLength() {
        // test
        let ecid = ECID()

        // verify
        XCTAssertEqual(38, ecid.description.count)
    }

    /// ECID should only contain numbers
    func testECIDContainsOnlyNumbers() {
        // test
        let ecid = ECID()

        // verify
        let isNumeric = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: ecid.ecidString))
        XCTAssertTrue(isNumeric)
    }

    /// ECID should be reasonably random
    func testECIDReasonablyRandom() {
        // setup
        let count = 1000
        var ecids = Set<ECID>()

        // test
        for _ in 0 ..< count {
            ecids.insert(ECID())
        }

        // verify
        XCTAssertEqual(count, ecids.count)
    }
}
