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

class URLQueryItem_IdentityTests: XCTestCase {
    // MARK: URLQueryItem(identifiable) tests

    /// Tests that one custom ID is encoded correctly
    func testQueryItemFromIdentifiableCorrectly() {
        // setup
        let expected = "d_cid_ic=DSID_20915%01test_ad_id%011"

        // test
        let queryItem = URLQueryItem(identifier: CustomIdentity(origin: "d_cid_ic", type: "DSID_20915", identifier: "test_ad_id", authenticationState: .authenticated))

        // verify
        XCTAssertEqual(expected, queryItem.description)
    }

    // MARK: URLQueryItem(dpid) tests

    /// Tests that one custom ID is encoded correctly
    func testQueryItemFromDpidCorrectly() {
        // setup
        let expected = "d_cid=key1%01val1"

        // test
        let queryItem = URLQueryItem(dpidKey: "key1", dpidValue: "val1")

        // verify
        XCTAssertEqual(expected, queryItem.description)
    }
}
