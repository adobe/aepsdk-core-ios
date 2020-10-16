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
@testable import AEPCoreMocks
import XCTest

class MobileCoreTrackingTests: XCTestCase {
    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        registerMockExtension(MockExtension.self)
    }
    
    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }
        
        semaphore.wait()
    }
    
    func testTrackAction() {
        // setup
        let expectation = XCTestExpectation(description: "Track Action dispatches generic tracking request content event")
        expectation.assertForOverFulfill = true
        let expectedContextData = ["testKey": "testVal"]
        let expectedAction = "myAction"
        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericTrack, source: EventSource.requestContent) { event in
            XCTAssertEqual(expectedAction, event.data?[CoreConstants.Keys.ACTION] as! String)
            XCTAssertEqual(expectedContextData, event.data?[CoreConstants.Keys.CONTEXT_DATA] as! [String: String])
            expectation.fulfill()
        }
        
        EventHub.shared.start()
        
        // test
        MobileCore.track(action: expectedAction, data: expectedContextData)
        
        // verify
        wait(for: [expectation], timeout: 1)
    }
    
    func testTrackState() {
        // setup
        let expectation = XCTestExpectation(description: "Track State dispatches generic tracking request content event")
        expectation.assertForOverFulfill = true
        let expectedContextData = ["testKey": "testVal"]
        let expectedState = "myState"
        
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericTrack, source: EventSource.requestContent) { event in
            XCTAssertEqual(expectedState, event.data?[CoreConstants.Keys.STATE] as! String)
            XCTAssertEqual(expectedContextData, event.data?[CoreConstants.Keys.CONTEXT_DATA] as! [String: String])
            expectation.fulfill()
        }
        
        EventHub.shared.start()
        
        // test
        MobileCore.track(state: expectedState, data: expectedContextData)
        
        // verify
        wait(for: [expectation], timeout: 1)
    }
}
