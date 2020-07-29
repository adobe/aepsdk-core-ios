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

class MobileCoreTests: XCTestCase {
    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        MockExtensionTwo.reset()
    }
    
    private func registerMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { (error) in
            XCTAssertNil(error)
            semaphore.signal()
        }

        semaphore.wait()
    }
    
    func testLegacyRegisterAndStart() {
        let expectation = XCTestExpectation(description: "callback invoked")
        expectation.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        MockExtension.registerExtension()
        MobileCore.start { }
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testLegacyRegisterAndStartMultiple() {
        let expectation = XCTestExpectation(description: "mock extension registered")
        expectation.assertForOverFulfill = true
        let expectation2 = XCTestExpectation(description: "mock extension 2 registered")
        expectation2.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        MockExtension.registerExtension()
        MockExtensionTwo.registrationClosure = { expectation2.fulfill() }
        MockExtensionTwo.registerExtension()
        MobileCore.start { }
        wait(for: [expectation, expectation2], timeout: 0.5)
    }
    
    func testLegacyRegisterEventDispatchSimple() {
        let expectation = XCTestExpectation(description: "callback invoked")
        expectation.assertForOverFulfill = true
        let eventName = "test-event"
        MockExtension.eventReceivedClosure = {
            if $0.name == eventName { expectation.fulfill() }
        }
        MockExtension.registerExtension()
        MobileCore.start { }
        EventHub.shared.dispatch(event: Event(name: eventName, type: .analytics, source: .requestContent, data: nil))
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLegacyRegisterExtensionsDispatchEventBeforeRegister() {
        let expectation = XCTestExpectation(description: "callback invoked")
        expectation.assertForOverFulfill = true
        let eventName = "test-event"
        EventHub.shared.dispatch(event: Event(name: eventName, type: .analytics, source: .requestContent, data: nil))
        MockExtension.eventReceivedClosure = { if $0.name == eventName { expectation.fulfill() } }
        MockExtension.registerExtension()
        
        MobileCore.start { }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLegacyRegisterMultipleExtensionsSimpleEventDispatch() {
        let expectation = XCTestExpectation(description: "callback invoked")
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 2
        let eventName = "test-event"
        MockExtension.eventReceivedClosure = {
            if $0.name == eventName { expectation.fulfill() }
        }
        MockExtensionTwo.eventReceivedClosure = {
            if $0.name == eventName { expectation.fulfill() }
        }
        
        MockExtension.registerExtension()
        MockExtensionTwo.registerExtension()
        MobileCore.start { }
        EventHub.shared.dispatch(event: Event(name: eventName, type: .analytics, source: .requestContent, data: nil))
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLegacyRegisterMultipleExtensionsDispatchEventBeforeRegister() {
        let eventName = "test-event"
        let expectation = XCTestExpectation(description: "callback invoked")
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 2

        MockExtension.eventReceivedClosure = {
            if $0.name == eventName { expectation.fulfill() }
        }
        MockExtensionTwo.eventReceivedClosure = {
            if $0.name == eventName { expectation.fulfill() }
        }
        MockExtension.registerExtension()
        MockExtensionTwo.registerExtension()
        EventHub.shared.dispatch(event: Event(name: eventName, type: .analytics, source: .requestContent, data: nil))
        MobileCore.start { }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLegacyRegisterSameExtensionTwice() {
        MockExtension.registerExtension()
        let expectation = XCTestExpectation(description: "callback invoked")
        expectation.assertForOverFulfill = true
        
        MockExtension.registrationClosure = { expectation.fulfill() }
        MobileCore.start {
        }
        wait(for: [expectation], timeout: 0.5)

        let expectation2 = XCTestExpectation(description: ("callback invoked 2nd time"))
        expectation2.assertForOverFulfill = true
        expectation2.isInverted = true
        
        MockExtension.registrationClosure = { expectation2.fulfill() }
        MockExtension.registerExtension()
        MobileCore.start {
        }
        
        wait(for: [expectation2], timeout: 0.5)
        
    }
    
    func testRegisterExtensionsSimple() {
        let expectation = XCTestExpectation(description: ("registration completed in timely fashion"))
        expectation.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        // test
        MobileCore.registerExtensions([MockExtension.self])
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testRegisterExtensionsSimpleMultiple() {
        let expectation = XCTestExpectation(description: ("registration completed in timely fashion"))
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        MockExtensionTwo.registrationClosure = { expectation.fulfill() }
        
        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])
            
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testRegisterExtensionsWithSlowExtension() {
        let expectation = XCTestExpectation(description: ("registration completed in timely fashion when long running extension is in play"))
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        MockExtensionTwo.registrationClosure = { expectation.fulfill() }

        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self, SlowMockExtension.self])
            
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testRegisterExtensionsSimpleEventDispatch() {
        let expectation = XCTestExpectation(description: ("expected event seen"))
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }
        
        // test
        MobileCore.registerExtensions([MockExtension.self])
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testRegisterExtensionsDispatchEventBeforeRegister() {
        // setup
        let expectation = XCTestExpectation(description: ("expected event seen"))
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        
        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }

        // test
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        MobileCore.registerExtensions([MockExtension.self])
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testRegisterMultipleExtensionsSimpleEventDispatch() {
        // setup
        let expectation = XCTestExpectation(description: ("expected event seen"))
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        
        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }

        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testRegisterMultipleExtensionsDispatchEventBeforeRegister() {
        // setup
        let expectation = XCTestExpectation(description: ("expected event seen"))
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        
        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }
        MockExtensionTwo.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }

        // test
        EventHub.shared.dispatch(event: Event(name: "test-event", type: .analytics, source: .requestContent, data: nil))
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])
        
        // verify
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRegisterSameExtensionTwice() {
        // setup
        let expectation = XCTestExpectation(description: ("extension should not register twice"))
        expectation.assertForOverFulfill = true
        
        MockExtension.registrationClosure = { expectation.fulfill() }
        
        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtension.self])
        MobileCore.start {
            
        }
            
        // verify
        wait(for: [expectation], timeout: 0.25)
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
        }

        wait(for: [registerExpectation], timeout: 1.0)
            
        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: expectedEvent.type, source: expectedEvent.source) { (event) in
            XCTAssertEqual(event.id, expectedEvent.id)
            eventExpectation.fulfill()
        }
        
        EventHub.shared.start()
        
        // test
        MobileCore.dispatch(event: expectedEvent)
        
        // verify
        wait(for: [eventExpectation], timeout: 1.0)
    }
    
    /// Tests that the response callback is invoked when the trigger event is dispatched
    func testDispatchEventWithResponseCallbackSimple() {
        // setup
        let expectedEvent = Event(name: "test", type: .analytics, source: .requestContent, data: nil)
        let expectedResponseEvent = expectedEvent.createResponseEvent(name: "test-response", type: .analytics, source: .responseContent, data: nil)
        let responseExpectation = XCTestExpectation(description: "Should receive the response event in the response callback")
        responseExpectation.assertForOverFulfill = true
        EventHub.shared.start()
        
        // test
        MobileCore.dispatch(event: expectedEvent) { (responseEvent) in
            XCTAssertEqual(responseEvent?.id, expectedResponseEvent.id)
            responseExpectation.fulfill()
        }
        // dispatch the response event which should trigger the callback above
        MobileCore.dispatch(event: expectedResponseEvent)
        
        // verify
        wait(for: [responseExpectation], timeout: 1.0)
    }
    
}
