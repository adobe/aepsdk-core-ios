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
    func validateSharedState(_ version: Int, _ dictionaryValue: String?, _ resolution: SharedStateResolution = .any, _ expectedStatus: SharedStateStatus? = nil) {
        switch resolution {
        case .lastSet:
            let resolved = sharedState.resolveLastSet(version: version)
            if let expectedStatus = expectedStatus {
                XCTAssertEqual(resolved.status, expectedStatus)
            }
            guard let value = resolved.value else {
                if dictionaryValue != nil {
                    XCTFail("resolved value is unexpectedly nil")
                }
                return
            }
            XCTAssertEqual(value[SharedStateTestHelper.DICT_KEY] as? String, dictionaryValue)
        case .any:
            let resolved = sharedState.resolve(version: version)
            XCTAssertEqual(resolved.value![SharedStateTestHelper.DICT_KEY] as? String, dictionaryValue)
            if let expectedStatus = expectedStatus {
                XCTAssertEqual(resolved.status, expectedStatus)
            }
        }
    }


    override func setUp() {
        sharedState = SharedState()
    }

    override func tearDown() {}

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
        sharedState.set(version: 0, data: SharedStateTestHelper.ZERO)
        sharedState.set(version: 1, data: SharedStateTestHelper.ONE)
        sharedState.addPending(version: 2)
        sharedState.set(version: 3, data: SharedStateTestHelper.THREE)

        validateSharedState(0, "zero", .any, .set)
        validateSharedState(1, "one", .any, .set)
        validateSharedState(2, "one", .any, .pending)
        validateSharedState(3, "three", .any, .set)

        sharedState.updatePending(version: 2, data: SharedStateTestHelper.TWO)

        validateSharedState(0, "zero", .any, .set)
        validateSharedState(1, "one", .any, .set)
        validateSharedState(2, "two", .any, .set)
        validateSharedState(3, "three", .any, .set)
    }

    func testUpdatePendingWithLastSetInterleaved() {
        sharedState.set(version: 0, data: SharedStateTestHelper.ZERO)
        sharedState.set(version: 1, data: SharedStateTestHelper.ONE)
        sharedState.addPending(version: 2)
        sharedState.set(version: 3, data: SharedStateTestHelper.THREE)

        validateSharedState(0, "zero", .lastSet, .set)
        validateSharedState(1, "one", .lastSet, .set)
        // Because version 2 was set to pending, last set is version 1
        validateSharedState(2, "one", .lastSet, .set)
        validateSharedState(3, "three", .lastSet, .set)

        sharedState.updatePending(version: 2, data: SharedStateTestHelper.TWO)

        validateSharedState(0, "zero", .lastSet, .set)
        validateSharedState(1, "one", .lastSet, .set)
        validateSharedState(2, "two", .lastSet, .set)
        validateSharedState(3, "three", .lastSet, .set)
    }

    func testUpdatePendingWithLastSetAllPending() {
        sharedState.addPending(version: 0)
        sharedState.addPending(version: 1)
        sharedState.addPending(version: 2)

        validateSharedState(0, nil, .lastSet, SharedStateStatus.none)
        validateSharedState(1, nil, .lastSet, SharedStateStatus.none)
        validateSharedState(3, nil, .lastSet, SharedStateStatus.none)

        sharedState.updatePending(version: 0, data: SharedStateTestHelper.ZERO)

        validateSharedState(0, "zero", .lastSet, .set)
        validateSharedState(1, "zero", .lastSet, .set)
        validateSharedState(2, "zero", .lastSet, .set)

        sharedState.updatePending(version: 1, data: SharedStateTestHelper.ONE)

        validateSharedState(0, "zero", .lastSet, .set)
        validateSharedState(1, "one", .lastSet, .set)
        validateSharedState(2, "one", .lastSet, .set)

        sharedState.updatePending(version: 2, data: SharedStateTestHelper.TWO)

        validateSharedState(0, "zero", .lastSet, .set)
        validateSharedState(1, "one", .lastSet, .set)
        validateSharedState(2, "two", .lastSet, .set)
    }

    func testBackwardLookingResolve() {
        sharedState.set(version: 10, data: SharedStateTestHelper.TEN)

        validateSharedState(10, "ten")
        validateSharedState(11, "ten")
        validateSharedState(1000, "ten")
    }

    func testForwardLookingResolve() {
        sharedState.set(version: 10, data: SharedStateTestHelper.TEN)

        validateSharedState(10, "ten", .any, SharedStateStatus.set)
        validateSharedState(9, "ten", .any, SharedStateStatus.set)
        validateSharedState(0, "ten", .any, SharedStateStatus.set)
        validateSharedState(-1000, "ten", .any, SharedStateStatus.set)
    }

    func testForwardLookingResolveLastSet() {
        sharedState.set(version: 10, data: SharedStateTestHelper.TEN)

        validateSharedState(10, "ten", .lastSet, .set)
        validateSharedState(9, "ten", .lastSet, .set)
        validateSharedState(0, "ten", .lastSet, .set)
        validateSharedState(-1000, "ten", .lastSet, .set)
    }

    func testMiddleResolve() {
        sharedState.set(version: 1, data: SharedStateTestHelper.ONE)
        sharedState.set(version: 5, data: SharedStateTestHelper.FIVE)
        sharedState.set(version: 10, data: SharedStateTestHelper.TEN)

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

    func testSharedStatePendingPreservesData() {
        // setup
        sharedState.set(version: 1, data: SharedStateTestHelper.ONE)
        sharedState.addPending(version: 2)

        // test
        let (data, _) = sharedState.resolve(version: 2)

        // verify
        XCTAssertEqual(SharedStateTestHelper.ONE as! [String: String], data as! [String: String])
    }

    func testSharedStateIsEmpty() {
        XCTAssertTrue(sharedState.isEmpty)
    }

    func testSharedStateIsNotEmptySet() {
        // setup
        sharedState.set(version: 1, data: SharedStateTestHelper.ONE)

        // verify
        XCTAssertFalse(sharedState.isEmpty)
    }

    func testSharedStateIsNotEmptyPending() {
        // setup
        sharedState.addPending(version: 1)

        // verify
        XCTAssertFalse(sharedState.isEmpty)
    }
}
