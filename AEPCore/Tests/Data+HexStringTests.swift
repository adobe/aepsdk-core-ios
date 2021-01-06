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
        let expected = "74657374486578537472696e67"

        // test
        let converted = data.hexDescription

        // verify
        XCTAssertEqual(expected, converted)
    }
    
    /// Tests that the string is properly encoded for longer strings
    func testHexStringFromDataHappyLong() {
        // setup
        let data = "Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, graphic or web designs. The passage is attributed to an unknown typesetter in the 15th century who is thought to have scrambled parts of Cicero's De Finibus Bonorum et Malorum for use in a type specimen book.".data(using: .utf8)!
        let expected = "4c6f72656d20697073756d2c206f72206c697073756d20617320697420697320736f6d6574696d6573206b6e6f776e2c2069732064756d6d792074657874207573656420696e206c6179696e67206f7574207072696e742c2067726170686963206f72207765622064657369676e732e205468652070617373616765206973206174747269627574656420746f20616e20756e6b6e6f776e207479706573657474657220696e2074686520313574682063656e747572792077686f2069732074686f7567687420746f206861766520736372616d626c6564207061727473206f662043696365726f27732044652046696e6962757320426f6e6f72756d206574204d616c6f72756d20666f722075736520696e206120747970652073706563696d656e20626f6f6b2e"

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
