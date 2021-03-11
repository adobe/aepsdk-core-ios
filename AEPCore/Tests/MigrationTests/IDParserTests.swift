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
@testable import AEPCore

class IDParserTests: XCTestCase {

    /// Nil should return an empty dict
    func testConvertStringToIdsNil() {
        XCTAssertTrue(IDParser().convertStringToIds(idString: nil).isEmpty)
    }

    /// Empty string should return an empty dict
    func testConvertStringToIdsEmpty() {
        XCTAssertTrue(IDParser().convertStringToIds(idString: "").isEmpty)
    }

    /// Tests that ids are parsed out of the url string
    func testConvertStringToIdsHappy() {
        // setup
        let testStr = "&d_cid_ic=loginidhash%0197717%010&d_cid_ic=xboxlivehash%011629158955%011&d_cid_ic=psnidhash%011144032295%012"
        let expectedIdCount = 3

        // test
        let parsedIds = IDParser().convertStringToIds(idString: testStr)

        // verify
        var matches = 0
        for id in parsedIds {
            if id["id_type"] as? String == "loginidhash" {
                XCTAssertEqual("97717", id["id"] as? String)
                XCTAssertEqual(0, id["authentication_state"] as? Int)
                matches += 1
            } else if id["id_type"] as? String == "xboxlivehash" {
                XCTAssertEqual("1629158955", id["id"] as? String)
                XCTAssertEqual(1, id["authentication_state"] as? Int)
                matches += 1
            } else if id["id_type"] as? String == "psnidhash" {
                XCTAssertEqual("1144032295", id["id"] as? String)
                XCTAssertEqual(2, id["authentication_state"] as? Int)
                matches += 1
            }
        }

        XCTAssertEqual(expectedIdCount, parsedIds.count)
        XCTAssertEqual(expectedIdCount, matches)
    }

    /// Tests that ids can be parsed out of the url string
    func testConvertStringToIdsEmptyHappyTwoWithOneEmptyId() {
        // setup
        let testStr = "&d_cid_ic=loginidhash%0197717%010&d_cid_ic=userid%01%012&d_cid_ic=psnidhash%011144032295%012"
        let expectedIdCount = 2

        // test
        let parsedIds = IDParser().convertStringToIds(idString: testStr)

        // verify
        var matches = 0
        for id in parsedIds {
            if id["id_type"] as? String == "loginidhash" {
                XCTAssertEqual("97717", id["id"] as? String)
                XCTAssertEqual(0, id["authentication_state"] as? Int)
                matches += 1
            } else if id["id_type"] as? String == "psnidhash" {
                XCTAssertEqual("1144032295", id["id"] as? String)
                XCTAssertEqual(2, id["authentication_state"] as? Int)
                matches += 1
            }
        }

        XCTAssertEqual(expectedIdCount, parsedIds.count)
        XCTAssertEqual(expectedIdCount, matches)
    }

}
