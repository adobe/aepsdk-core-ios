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

@testable import AEPServices
import XCTest

class SHA256Tests: XCTestCase {

    // MARK: hexStringFromData(...) tests

    /// Tests that the string is properly encoded
    func testHexStringFromDataHappy() {
        // setup
        let data = "testHexString".data(using: .utf8)!
        let expected = "74657374486578537472696e67"

        // test
        let converted = SHA256.hexStringFromData(input: data as NSData)

        // verify
        XCTAssertEqual(expected, converted)
    }

    /// Tests that when an empty string is passed that we return an empty string
    func testHexStringFromDataEmpty() {
        let data = "".data(using: .utf8)!
        XCTAssertTrue(SHA256.hexStringFromData(input: data as NSData).isEmpty)
    }

    /// Tests that when empty nil is passed we return an empty string
    func testHexStringFromDataNil() {
        XCTAssertTrue(SHA256.hexStringFromData(input: nil).isEmpty)
    }
}
