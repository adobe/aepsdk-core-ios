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
import AEPServicesMocks
import AEPServicesMocks
import XCTest

class HitQueuing_PrivacyTests: XCTestCase {
    var hitQueue: MockHitQueue!

    override func setUp() {
        hitQueue = MockHitQueue(processor: MockHitProcessor())
    }

    /// Tests that when we pass opt-in that the hit queue begins processing
    func testOptIn() {
        // test
        hitQueue.handlePrivacyChange(status: .optedIn)

        // verify
        XCTAssertTrue(hitQueue.calledBeginProcessing)
        XCTAssertFalse(hitQueue.calledSuspend)
        XCTAssertFalse(hitQueue.calledClear)
    }

    /// Tests that when we pass opt-out that the hit queue clears hits and suspends
    func testOptOut() {
        // test
        hitQueue.handlePrivacyChange(status: .optedOut)

        // verify
        XCTAssertFalse(hitQueue.calledBeginProcessing)
        XCTAssertTrue(hitQueue.calledSuspend)
        XCTAssertTrue(hitQueue.calledClear)
    }

    /// Tests that when unknown is passed that we suspend the queue
    func testUnknown() {
        // test
        hitQueue.handlePrivacyChange(status: .unknown)

        // verify
        XCTAssertFalse(hitQueue.calledBeginProcessing)
        XCTAssertTrue(hitQueue.calledSuspend)
        XCTAssertFalse(hitQueue.calledClear)
    }
}
