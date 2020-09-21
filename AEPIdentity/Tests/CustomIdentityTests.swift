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

class CustomIdentityTests: XCTestCase {

    /// CustomIdentity's with same types are considered equal
    func testCustomIdentityAreEqual() {
        // setup
        let id1 = CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)
        let id2 = CustomIdentity(origin: "origin1", type: "type", identifier: "id1", authenticationState: .loggedOut)

        // test & verify
        XCTAssertTrue(id1 == id2)
    }

    /// CustomIdentity's with different types are considered not equal
    func testCustomIdentityAreNotEqual() {
        // setup
        let id1 = CustomIdentity(origin: "origin", type: "type", identifier: "id", authenticationState: .authenticated)
        let id2 = CustomIdentity(origin: "origin", type: "type1", identifier: "id", authenticationState: .authenticated)

        // test & verify
        XCTAssertFalse(id1 == id2)
    }
}
