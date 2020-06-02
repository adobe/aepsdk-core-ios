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

class AEPCoreTests: XCTestCase {

    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        MockExtensionTwo.reset()
    }
    
    func testLegacyRegisterAndStart() {
        var callbackCalled = false
        MockExtension.registerExtension()
        AEPCore.start {
            callbackCalled = true
        }
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertTrue(callbackCalled)
    }
    
    func testLegacyRegisterAndStartMultiple() {
        var callbackCalled = false
        MockExtension.registerExtension()
        MockExtensionTwo.registerExtension()
        AEPCore.start {
            callbackCalled = true
        }
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtensionTwo.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertTrue(MockExtensionTwo.calledOnRegistered)
        XCTAssertTrue(callbackCalled)
    }
    
    func testLegacyRegisterEventDispatchSimple() {
        var callbackCalled = false
        MockExtension.registerExtension()
        AEPCore.start {
           callbackCalled = true
        }
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        sleep(1)
        XCTAssertTrue(callbackCalled)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, "test-event")
    }
    
    func testLegacyRegisterExtensionsDispatchEventBeforeRegister() {
        var callbackCalled = false
        let eventName = "test-event"
        EventHub.shared.dispatch(event: Event(name: eventName, type: .analytics, source: .requestContent, data: nil))
        MockExtension.registerExtension()
        AEPCore.start {
            callbackCalled = true
        }
        
        sleep(1)
        XCTAssertTrue(callbackCalled)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, eventName)
    }
    
    func testLegacyRegisterMultipleExtensionsSimpleEventDispatch() {
        MockExtension.registerExtension()
        MockExtensionTwo.registerExtension()
        var callbackCalled = false
        AEPCore.start {
            callbackCalled = true
        }
        let eventName = "test-event"
        EventHub.shared.dispatch(event: Event(name: eventName, type: .analytics, source: .requestContent, data: nil))
        
        sleep(1)
        XCTAssertTrue(callbackCalled)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertTrue(MockExtensionTwo.calledInit)
        XCTAssertTrue(MockExtensionTwo.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, eventName)
    }
    
    func testLegacyRegisterMultipleExtensionsDispatchEventBeforeRegister() {
        let eventName = "test-event"
        var callbackCalled = false
        EventHub.shared.dispatch(event: Event(name: eventName, type: .analytics, source: .requestContent, data: nil))
        MockExtension.registerExtension()
        MockExtensionTwo.registerExtension()
        AEPCore.start {
            callbackCalled = true
        }
        
        sleep(1)
        XCTAssertTrue(callbackCalled)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertTrue(MockExtensionTwo.calledInit)
        XCTAssertTrue(MockExtensionTwo.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, eventName)
    }
    
    func testLegacyRegisterSameExtensionTwice() {
        MockExtension.registerExtension()
        var callbackCalled = false
        AEPCore.start {
            callbackCalled = true
        }
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        
        MockExtension.reset()
        callbackCalled = false
        MockExtension.registerExtension()
        AEPCore.start {
            callbackCalled = true
        }
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertFalse(MockExtension.calledOnRegistered)
        
    }
    
    func testRegisterExtensionsSimple() {
        // test
        AEPCore.registerExtensions([MockExtension.self])
            
        // verify
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
    }
    
    func testRegisterExtensionsSimpleMultiple() {
        // test
        AEPCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])
            
        // verify
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertTrue(MockExtensionTwo.calledInit)
        XCTAssertTrue(MockExtensionTwo.calledOnRegistered)
    }
    
    func testRegisterExtensionsWithSlowExtension() {
        // test
        AEPCore.registerExtensions([MockExtension.self, MockExtensionTwo.self, SlowMockExtension.self])
            
        // verify
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertTrue(MockExtensionTwo.calledInit)
        XCTAssertTrue(MockExtensionTwo.calledOnRegistered)
    }
    
    func testRegisterExtensionsSimpleEventDispatch() {
        // test
        AEPCore.registerExtensions([MockExtension.self])
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        
        // verify
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, "test-event")
    }
    
    func testRegisterExtensionsDispatchEventBeforeRegister() {
        // test
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        AEPCore.registerExtensions([MockExtension.self])
        
        // verify
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, "test-event")
    }
    
    func testRegisterMultipleExtensionsSimpleEventDispatch() {
        // test
        AEPCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        
        // verify
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, "test-event")
    }
    
    func testRegisterMultipleExtensionsDispatchEventBeforeRegister() {
        // test
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        AEPCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])
        
        // verify
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        XCTAssertEqual(MockExtension.receivedEvents.first!.name, "test-event")
    }
    
    func testRegisterSameExtensionTwice() {
        // test
        AEPCore.registerExtensions([MockExtension.self])
            
        // verify pt. 1
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertTrue(MockExtension.calledOnRegistered)
        
        MockExtension.reset()
        
        AEPCore.registerExtensions([MockExtension.self])
            
        // verify pt. 2
        sleep(1)
        XCTAssertTrue(MockExtension.calledInit)
        XCTAssertFalse(MockExtension.calledOnRegistered)
    }
    
    func testDispatchEventSimple() {
        // setup
        let expectedEvent = Event(name: "test", type: .analytics, source: .requestContent, data: nil)
        
        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should receive the event when dispatched through the event hub")
        eventExpectation.assertForOverFulfill = true
        
        EventHub.shared.registerExtension(MockExtension.self) { (error) in
            registerExpectation.fulfill()
            
            // register listener after registration
            EventHub.shared.registerListener(parentExtension: MockExtension.self, type: expectedEvent.type, source: expectedEvent.source) { (event) in
                XCTAssertEqual(event.id, expectedEvent.id)
                eventExpectation.fulfill()
            }
        }
        
        EventHub.shared.start()
        
        // test
        AEPCore.dispatch(event: expectedEvent)
        
        // verify
        wait(for: [registerExpectation, eventExpectation], timeout: 1.0)
    }
    
    // test is disabled until configuration extension is merged
    func testDispatchEventWithResponseCallbackSimple() {
        // setup
        let expectedEvent = Event(name: "test", type: .analytics, source: .requestContent, data: nil)
        let expectedResponseEvent = expectedEvent.createResponseEvent(name: "test-response", type: .analytics, source: .responseContent, data: nil)
        
        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let responseExpectation = XCTestExpectation(description: "Should receive the response event in the response callback")
        responseExpectation.assertForOverFulfill = true
        
        EventHub.shared.registerExtension(MockExtension.self) { (error) in
            registerExpectation.fulfill()
        }
        
        EventHub.shared.start()
        
        // test
        AEPCore.dispatch(event: expectedEvent) { (responseEvent) in
            XCTAssertEqual(responseEvent.id, expectedResponseEvent.id)
        }
        // dispatch the response event which should trigger the callback above
        AEPCore.dispatch(event: expectedResponseEvent)
        
        // verify
        wait(for: [registerExpectation, responseExpectation], timeout: 1.0)
    }

}
