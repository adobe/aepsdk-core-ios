/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
@testable import AEPLifecycle
import AEPServices
import AEPServicesMocks
import XCTest

class LifecycleV2StateManagerTests: XCTestCase {

    static let PAUSE_UPDATE_TIMEOUT = LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC + 0.20
    
    var stateManager: LifecycleV2StateManager!
    
    override func setUp() {        
        stateManager = LifecycleV2StateManager(logger: MockLogger())
    }
    
    func testUpdateStateUpdatesOnceWithConsecutiveStarts() {
        let times = 5
        var updates = [Bool]()
        
        let expectation = XCTestExpectation(description: "LifecycleV2StateManager invokes callback with update flag")
        expectation.expectedFulfillmentCount = times
        
        let callback = { (updated: Bool) in
            updates.append(updated)
            expectation.fulfill()
        }
        
        for _ in 1...times {
            stateManager.update(state: .START, callback: callback)
        }
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertTrue(updates[0])
        for i in 1..<times {
            XCTAssertFalse(updates[i])
        }
    }
    
    func testUpdateStateUpdatesOnceWithConsecutivePauses() {
        let times = 5
        var updates = [Bool]()
        
        let expectation = XCTestExpectation(description: "LifecycleV2StateManager invokes callback with update flag")
        expectation.expectedFulfillmentCount = times + 1
        
        let callback = { (updated: Bool) in
            updates.append(updated)
            expectation.fulfill()
        }
        
        stateManager.update(state: .START, callback: callback)
        for _ in 1...times {
            stateManager.update(state: .PAUSE, callback: callback)
        }
        
        wait(for: [expectation], timeout: Self.PAUSE_UPDATE_TIMEOUT)
        
        XCTAssertTrue(updates[0])
        XCTAssertTrue(updates[times])
        for i in 1..<times - 1 {
            XCTAssertFalse(updates[i])
        }
    }
    
    func testUpdateStateUpdatesOnceWithConsecutiveStartPauseStart() {
        var updates = [Bool]()
        
        let expectation = XCTestExpectation(description: "LifecycleV2StateManager invokes callback with update flag")
        expectation.expectedFulfillmentCount = 5
        
        let callback = { (updated: Bool) in
            updates.append(updated)
            expectation.fulfill()
        }
        
        stateManager.update(state: .START, callback: callback)
        stateManager.update(state: .PAUSE, callback: callback)
        stateManager.update(state: .START, callback: callback)
        stateManager.update(state: .PAUSE, callback: callback)
        stateManager.update(state: .START, callback: callback)
        
        wait(for: [expectation], timeout: Self.PAUSE_UPDATE_TIMEOUT)
        
        XCTAssertTrue(updates[0])
        for i in 1...4 {
            XCTAssertFalse(updates[i])
        }
    }
    
    func testUpdateStateUpdatesCorrectlyWithConsecutiveStartPause() {
        var updates = [Bool]()
        
        var expectation = XCTestExpectation(description: "LifecycleV2StateManager invokes callback with update flag")
        expectation.expectedFulfillmentCount = 2
        
        let callback = { (updated: Bool) in
            updates.append(updated)
            expectation.fulfill()
        }
        
        stateManager.update(state: .START, callback: callback)
        stateManager.update(state: .PAUSE, callback: callback)
        
        wait(for: [expectation], timeout: Self.PAUSE_UPDATE_TIMEOUT)
        
        XCTAssertTrue(updates[0])
        XCTAssertTrue(updates[1])
        
        updates = [Bool]()
        expectation = XCTestExpectation(description: "LifecycleV2StateManager invokes callback with update flag")
        expectation.expectedFulfillmentCount = 2
        stateManager.update(state: .START, callback: callback)
        stateManager.update(state: .PAUSE, callback: callback)
        
        wait(for: [expectation], timeout: Self.PAUSE_UPDATE_TIMEOUT)
        
        XCTAssertTrue(updates[0])
        XCTAssertTrue(updates[1])
    }
}
