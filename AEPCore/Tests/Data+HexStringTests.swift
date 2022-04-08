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

@testable import AEPCore
import XCTest

class Data_HexStringTests: XCTestCase {

    /// Tests that the string is properly encoded
    func testHexStringFromDataHappy() {
        // setup
        let data = "testHexString".data(using: .utf8)!
        let expected = "74657374486578537472696E67"

        // test
        let converted = data.hexDescription

        // verify
        XCTAssertEqual(expected, converted)
    }

    /// Tests that the string is properly encoded for longer strings
    func testHexStringFromDataHappyLong() {
        // setup
        let data = "Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, graphic or web designs. The passage is attributed to an unknown typesetter in the 15th century who is thought to have scrambled parts of Cicero's De Finibus Bonorum et Malorum for use in a type specimen book.".data(using: .utf8)!
        let expected = "4C6F72656D20697073756D2C206F72206C697073756D20617320697420697320736F6D6574696D6573206B6E6F776E2C2069732064756D6D792074657874207573656420696E206C6179696E67206F7574207072696E742C2067726170686963206F72207765622064657369676E732E205468652070617373616765206973206174747269627574656420746F20616E20756E6B6E6F776E207479706573657474657220696E2074686520313574682063656E747572792077686F2069732074686F7567687420746F206861766520736372616D626C6564207061727473206F662043696365726F27732044652046696E6962757320426F6E6F72756D206574204D616C6F72756D20666F722075736520696E206120747970652073706563696D656E20626F6F6B2E"

        // test
        let converted = data.hexDescription

        // verify
        XCTAssertEqual(expected, converted)
    }

    /// Tests that when an empty string is passed that we return an empty string
    func testHexStringFromDataEmpty() {
        let data = "".data(using: .utf8)!
        XCTAssertTrue(data.hexDescription.isEmpty)
    }

}
