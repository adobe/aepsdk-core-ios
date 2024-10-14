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

class IdentityHitResponseTests: XCTestCase {
    /// Tests that when all properties are present they are all populated in the response struct
    func testDecodeHappy() {
        // setup
        let jsonStr = """
        {"d_mid": "11055975576108377572226656299476126353",
        "d_optout": ["global"],
        "dcs_region": 6,
        "d_blob":"wxyz5432",
        "id_sync_ttl": 7200}
        """

        // test
        let response = try! JSONDecoder().decode(IdentityHitResponse.self, from: jsonStr.data(using: .utf8)!)

        // verify
        XCTAssertEqual("11055975576108377572226656299476126353", response.ecid)
        XCTAssertEqual("global", response.optOutList?.first)
        XCTAssertEqual(6, response.hint)
        XCTAssertEqual("wxyz5432", response.blob)
        XCTAssertEqual(7200, response.ttl)
    }

    /// Tests that when the opt out list is empty in json it is empty in the response
    func testDecodeNullOptOutList() {
        // setup
        let jsonStr = """
        {"d_mid": "11055975576108377572226656299476126353",
        "dcs_region": 6,
        "d_blob":"wxyz5432",
        "id_sync_ttl": 7200}
        """

        // test
        let response = try! JSONDecoder().decode(IdentityHitResponse.self, from: jsonStr.data(using: .utf8)!)

        // verify
        XCTAssertEqual("11055975576108377572226656299476126353", response.ecid)
        XCTAssertNil(response.optOutList)
        XCTAssertEqual(6, response.hint)
        XCTAssertEqual("wxyz5432", response.blob)
        XCTAssertEqual(7200, response.ttl)
    }

    func testDecodeAdditionalFields() {
        // setup
        let jsonStr = """
        {"d_mid":"03101358720715522005676253806759106050","id_sync_ttl":604800,"d_blob":"j8Odv6LonN4r3an7LhD3WZrU1bUpAkFkkiY1ncBR96t2PTI","dcs_region":9,"d_ottl":7200,"ibs":[],"subdomain":"obumobile5","tid":"c8VdE0tuQkg="}
        """

        // test
        let response = try! JSONDecoder().decode(IdentityHitResponse.self, from: jsonStr.data(using: .utf8)!)

        // verify
        XCTAssertEqual("03101358720715522005676253806759106050", response.ecid)
        XCTAssertNil(response.optOutList)
        XCTAssertEqual(9, response.hint)
        XCTAssertEqual("j8Odv6LonN4r3an7LhD3WZrU1bUpAkFkkiY1ncBR96t2PTI", response.blob)
        XCTAssertEqual(604800, response.ttl)
    }

    /// Tests that all properties are empty when the json is empty
    func testDecodeInvalid() {
        // setup
        let jsonStr = "{}"

        // test
        let response = try! JSONDecoder().decode(IdentityHitResponse.self, from: jsonStr.data(using: .utf8)!)

        // verify
        XCTAssertNil(response.ecid)
        XCTAssertNil(response.optOutList)
        XCTAssertNil(response.hint)
        XCTAssertNil(response.blob)
        XCTAssertNil(response.ttl)
    }
}
