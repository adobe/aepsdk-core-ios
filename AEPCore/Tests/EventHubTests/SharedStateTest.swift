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

class SharedStateTest: XCTestCase {

    private var sharedState: SharedState = SharedState()

    // helper function
    func validateSharedState(_ version: Int, _ dictionaryValue: String) {
        XCTAssertEqual(sharedState.resolve(version: version).value![SharedStateTestHelper.DICT_KEY] as! String, dictionaryValue)
    }

    override func setUp() {
        sharedState = SharedState()
    }

    override func tearDown() {
    }

    func testSetVersion() {
        sharedState.set(version: 0, data: SharedStateTestHelper.ZERO)

        validateSharedState(0, "zero")
    }

    func testSetMultipleVersions() {
        sharedState.set(version: 0, data: SharedStateTestHelper.ZERO)
        sharedState.set(version: 1, data: SharedStateTestHelper.ONE)
        sharedState.set(version: 2, data: SharedStateTestHelper.TWO)
        sharedState.set(version: 3, data: SharedStateTestHelper.THREE)
        sharedState.set(version: 4, data: SharedStateTestHelper.FOUR)
        sharedState.set(version: 5, data: SharedStateTestHelper.FIVE)
        sharedState.set(version: 10, data: SharedStateTestHelper.TEN)

        validateSharedState(0, "zero")
        validateSharedState(0, "zero")
        validateSharedState(1, "one")
        validateSharedState(2, "two")
        validateSharedState(3, "three")
        validateSharedState(4, "four")
        validateSharedState(5, "five")
        validateSharedState(10, "ten")
    }

    func testAddSameVersion() {
        sharedState.set(version: 0, data: SharedStateTestHelper.ZERO)
        sharedState.set(version: 0, data: SharedStateTestHelper.ONE) // should fail because data is not "pending"

        validateSharedState(0, "zero")
    }

    func testUpdateNonPending() {
        sharedState.set(version: 0, data: SharedStateTestHelper.ZERO)
        sharedState.updatePending(version: 0, data: SharedStateTestHelper.ONE)

        validateSharedState(0, "zero")
    }

    func testUpdatePending() {
        sharedState.addPending(version: 0)
        sharedState.updatePending(version: 0, data: SharedStateTestHelper.ONE)

        validateSharedState(0, "one")

        let (_, status) = sharedState.resolve(version: 0)
        XCTAssertEqual(status, .set)
    }

    func testUpdatePendingInterleaved() {
        sharedState.set(version:0, data: SharedStateTestHelper.ZERO)
        sharedState.set(version:1, data: SharedStateTestHelper.ONE)
        sharedState.addPending(version:2)
        sharedState.set(version:3, data: SharedStateTestHelper.THREE)

        sharedState.updatePending(version: 2, data: SharedStateTestHelper.TWO)

        validateSharedState(0, "zero")
        validateSharedState(1, "one")
        validateSharedState(2, "two")
        validateSharedState(3, "three")
    }

    func testBackwardLookingResolve() {
        sharedState.set(version:10, data: SharedStateTestHelper.TEN)

        validateSharedState(10, "ten")
        validateSharedState(11, "ten")
        validateSharedState(1000, "ten")
    }

    func testForwardLookingResolve() {
        sharedState.set(version:10, data: SharedStateTestHelper.TEN)

        validateSharedState(10, "ten")
        validateSharedState(9, "ten")
        validateSharedState(0, "ten")
        validateSharedState(-1000, "ten")
    }

    func testMiddleResolve() {
        sharedState.set(version:1, data: SharedStateTestHelper.ONE)
        sharedState.set(version:5, data: SharedStateTestHelper.FIVE)
        sharedState.set(version:10, data: SharedStateTestHelper.TEN)

        validateSharedState(4, "one")
        validateSharedState(5, "five")
        validateSharedState(6, "five")
        validateSharedState(9, "five")
        validateSharedState(11, "ten")
    }

    func testGetSharedStateStatus() {
        sharedState.addPending(version: 0)

        let (_, status) = sharedState.resolve(version: 0)
        XCTAssertEqual(status, .pending)
    }

    func testSharedStateHasNoneStatus() {
        XCTAssertEqual(sharedState.resolve(version: 0).status, SharedStateStatus.none)
    }

    func testAddPerformance() {
        // This is an example of a performance test case.
        self.measure {
            for version in 1...1000 {
                sharedState.set(version: version, data: SharedStateTestHelper.ZERO)
            }
            // Put the code you want to measure the time of here.
        }
    }

    func testResolvePerformance() {
        self.measure {
            for version in 1...1000 {
                sharedState.set(version: version, data: SharedStateTestHelper.ZERO)
            }

            for version in 1...1000 {
                _ = sharedState.resolve(version: version)
            }
        }
    }

}
