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
    let sha256Test = [
        "wat": "f00a787f7492a95e165b470702f4fe9373583fbdc025b2c8bdf0262cc48fcff4",
        "thisisatest": "a7c96262c21db9a06fd49e307d694fd95f624569f9b35bb3ffacd880440f9787",
        "5DCD537D-A351-408E-92D7-EBCBC69FEF44": "521ff623340269fd77ebc5bd19e459dcd6a3bfd89a8fbcd10e0b11672914e36b",
        "㧶Ẫ什៣溊⠶ￃ폾溊": "4b0545fa73d4cc69de864b923c6cfb08809ce67d42caa3e43265c05cdf17ab3c",
        "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq": "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
        "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu": "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1",
        "": "",
    ]

    // MARK: hash(...) tests

    /// Tests that the values are hashed correctly
    func testSha256() {
        for (unhashed, hashed) in sha256Test {
            XCTAssertEqual(SHA256.hash(unhashed), hashed)
        }
    }

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
