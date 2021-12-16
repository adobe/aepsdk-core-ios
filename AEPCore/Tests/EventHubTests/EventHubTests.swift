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
@testable import AEPCoreMocks

class EventHubTests: XCTestCase {
    private static let MOCK_EXTENSION_NAME = "com.adobe.mockExtension"

    var eventHub: EventHub!

    override func setUp() {
        eventHub = EventHub()
        MockExtension.reset()
        MockExtensionTwo.reset()
        registerMockExtension(MockExtension.self)
    }

    // MARK: Helper functions

    private func validateSharedState(_ extensionName: String, _ event: Event?, _ dictionaryValue: String, _ sharedStateType: SharedStateType = .standard) {
        XCTAssertEqual(eventHub.getSharedState(extensionName: extensionName, event: event, sharedStateType: sharedStateType)?.value![SharedStateTestHelper.DICT_KEY] as! String, dictionaryValue)
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        eventHub.registerExtension(type) { error in
            XCTAssertNil(error)
            semaphore.signal()
        }

        semaphore.wait()
    }

    func testEventHubDispatchesEventToListener() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is invoked exactly once")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubDoesNotInvokeListenerWrongType() {
        // setup
        let expectation = XCTestExpectation(description: "Does not invoke listener when type doesn't match")
        expectation.isInverted = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.acquisition, source: testEvent.source) { _ in
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubNeverDispatchesEventToListenerWithoutStart() {
        // setup
        let expectation = XCTestExpectation(description: "EventHub does not invoke listeners when not started")
        expectation.isInverted = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { _ in
            expectation.fulfill()
        }

        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 0.25)
    }

    func testEventHubQueuesEventsBeforeStart() {
        let expectation = XCTestExpectation(description: "Invokes listener even when event is dispatched before start")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent)
        eventHub.start()

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubDispatchesEventToListenerAndIgnoresNonMatchingEvent() {
        // setup
        let expectation = XCTestExpectation(description: "Invokes listener with matching type and source, then ignores Event of non-matching type and source")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let testEvent1 = Event(name: "testEvent1", type: EventType.identity, source: EventSource.requestIdentity, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent1) // should not invoke listener

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubDispatchesEventsToListener() {
        // setup
        let expectation = XCTestExpectation(description: "Invokes listener with matching Events")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let testEvent1 = Event(name: "testEvent1", type: testEvent.type, source: testEvent.source, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.type == testEvent.type && event.source == testEvent.source)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent1)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubDispatchesEventsToMultipleListeners() {
        // setup
        let expectation = XCTestExpectation(description: "Invokes first listener with matching Events")
        let expectation1 = XCTestExpectation(description: "Invokes second listener with matching Events")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        expectation1.expectedFulfillmentCount = 2
        expectation1.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.type == testEvent.type && event.source == testEvent.source)
            expectation.fulfill()
        }

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.type == testEvent.type && event.source == testEvent.source)
            expectation1.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation, expectation1], timeout: 1)
    }

    func testEventHubDispatchesEventsToCorrectListeners() {
        // setup
        let expectation = XCTestExpectation(description: "First listener is invoked by testEvent and not by testEvent1")
        let expectation1 = XCTestExpectation(description: "Second listener is invoked by testEvent1 and not by testEvent")
        expectation.assertForOverFulfill = true
        expectation1.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let testEvent1 = Event(name: "testEvent1", type: EventType.places, source: EventSource.responseContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent1.type, source: testEvent1.source) { event in
            XCTAssert(event.name == testEvent1.name)
            expectation1.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent) // should invoke first listener
        eventHub.dispatch(event: testEvent1) // should invoke second listener

        // verify
        wait(for: [expectation, expectation1], timeout: 1)
    }

    func testEventHubTestRegisterEventListener() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is invoked exactly once")
        expectation.assertForOverFulfill = true
        let event = Event(name: "Test", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.registerEventListener(type: EventType.analytics, source: EventSource.requestContent) { event in
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: event)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubTestRegisterEventListenerUnMatchedEvent() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is not invoked")
        expectation.isInverted = true
        let event = Event(name: "Test", type: "wrong", source: "wrong", data: nil)

        // test
        eventHub.registerEventListener(type: EventType.analytics, source: EventSource.requestContent) { event in
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: event)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubTestRegisterEventListenerWhenEventHubPlaceholderExtensionIsNotExist() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is not invoked")
        expectation.isInverted = true
        let event = Event(name: "Test", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        eventHub.unregisterExtension(EventHubPlaceholderExtension.self){_ in }

        // test
        eventHub.registerEventListener(type: EventType.analytics, source: EventSource.requestContent) { event in
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: event)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubTestRegisterEventListenerNotInvokedForPairedResponseEvent() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is not invoked for paired response event")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        let requestEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let responseEvent = Event(name: "testResponseEvent1", type: EventType.analytics, source: EventSource.responseContent, data: nil)
        let pairedResponseEvent = requestEvent.createResponseEvent(name: "testPairedResponseEvent1", type: EventType.analytics, source: EventSource.responseContent, data: nil)

        // test
        eventHub.registerEventListener(type: EventType.analytics, source: EventSource.responseContent) { event in
            XCTAssertEqual(EventSource.responseContent, event.source)
            XCTAssertNil(event.responseID)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: responseEvent)
        eventHub.dispatch(event: pairedResponseEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubTestRegisterEventListenerWildcardCalledForAllEvents() {
        // setup
        let expectation = XCTestExpectation(description: "Wildcard Listener is invoked for all events")
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 2
        let requestEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let responseEvent = Event(name: "testResponseEvent1", type: EventType.analytics, source: EventSource.responseContent, data: nil)
        let pairedResponseEvent = requestEvent.createResponseEvent(name: "testPairedResponseEvent1", type: EventType.analytics, source: EventSource.responseContent, data: nil)

        // test
        eventHub.registerEventListener(type: EventType.wildcard, source: EventSource.wildcard) { event in
            if event.source == EventSource.responseContent {
                expectation.fulfill()
            }
        }

        eventHub.start()
        eventHub.dispatch(event: responseEvent)
        eventHub.dispatch(event: pairedResponseEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubTestResponseListener() {
        // setup
        let expectation = XCTestExpectation(description: "Response listener is invoked exactly once")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let testResponseEvent = testEvent.createResponseEvent(name: "testResponseEvent", type: testEvent.type, source: EventSource.responseContent, data: nil)

        // test
        // listens for a event of type analytics and source response content
        eventHub.registerResponseListener(triggerEvent: testEvent, timeout: 1) { event in
            XCTAssert(event?.name == testResponseEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testResponseEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubTestResponseListenerRemovedAfterInvoked() {
        // setup
        let expectation = XCTestExpectation(description: "Response listener is invoked exactly once, and removed after receiving one response event")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let testResponseEvent = testEvent.createResponseEvent(name: "testResponseEvent", type: testEvent.type, source: EventSource.responseContent, data: nil)

        // test
        // listens for a event of type analytics and source response content
        eventHub.registerResponseListener(triggerEvent: testEvent, timeout: 1) { event in
            XCTAssert(event?.name == testResponseEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testResponseEvent)
        eventHub.dispatch(event: testResponseEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubTestResponseListenerNotInvoked() {
        // setup
        let expectation = XCTestExpectation(description: "Response listener is not invoked by other request event")
        expectation.assertForOverFulfill = true
        let requestEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let otherRequestEvent = Event(name: "testEvent1", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let otherResponseEvent = otherRequestEvent.createResponseEvent(name: "testResponseEvent1", type: otherRequestEvent.type, source: EventSource.responseContent, data: nil)

        // test
        eventHub.registerResponseListener(triggerEvent: requestEvent, timeout: 0.25) { event in
            XCTAssertNil(event) // event should be nil since the response listener will have timed-out
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: otherRequestEvent)
        eventHub.dispatch(event: otherResponseEvent)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubDispatchesEventsWithBlockingListener() {
        // setup
        let expectation = XCTestExpectation(description: "Invoke blocking listener with matching Event and ignored Event of non-matching type and source")
        let expectation1 = XCTestExpectation(description: "Long running listener does not")
        expectation.assertForOverFulfill = true
        expectation1.assertForOverFulfill = true
        registerMockExtension(MockExtensionTwo.self)
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtensionTwo.self)?.registerListener(type: testEvent.type, source: testEvent.source) { _ in
            expectation.fulfill()
            // simulate a long running listener
            sleep(20)
        }

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { _ in
            expectation1.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation, expectation1], timeout: 1)
    }

    func testEventHubDispatchesEventFromExtensionQueue() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is called exactly once when invoked from extension queue")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { event in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        DispatchQueue(label: "com.adobe.mock.extension").async { self.eventHub.dispatch(event: testEvent) }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubDispatchesEventFromManyExtensionQueues() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is invoked exactly 100 times when 100 events are dispatched from 100 different queues")
        expectation.expectedFulfillmentCount = 100
        expectation.assertForOverFulfill = true
        let type = EventType.analytics
        let source = EventSource.requestContent
        let eventNamePrefix = "testEvent-"

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: type, source: source) { event in
            XCTAssert(type == event.type && source == event.source)
            expectation.fulfill()
        }

        eventHub.start()

        for i in 0 ..< expectation.expectedFulfillmentCount {
            let queue = DispatchQueue(label: "com.adobe.mock.extension.\(i)")
            let testEvent = Event(name: eventNamePrefix + "\(i)", type: type, source: source, data: nil)
            queue.async { self.eventHub.dispatch(event: testEvent) }
        }

        // verify
        wait(for: [expectation], timeout: 5.0)
    }

    func testEventHubRegisterExtensionSuccess() {
        // setup
        let expectation = XCTestExpectation(description: "Extension is registered successfully after eventHub.start()")
        expectation.assertForOverFulfill = true

        MockExtensionTwo.registrationClosure = { expectation.fulfill() }
        // test
        eventHub.start()
        eventHub.registerExtension(MockExtensionTwo.self) { error in
            XCTAssertNil(error)
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that an extension that is registered can be unregistered without an error
    func testEventHubUnregisterExtensionSuccess() {
        // setup
        let expectation = XCTestExpectation(description: "Extension is unregistered successfully after eventHub.start()")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        registerMockExtension(MockExtensionTwo.self)

        MockExtensionTwo.unregistrationClosure = { expectation.fulfill() }
        // test
        eventHub.start()
        eventHub.unregisterExtension(MockExtensionTwo.self) { error in
            expectation.fulfill()
            XCTAssertNil(error)
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that an extension that is not registered cannot be unregistered
    func testEventHubUnregisterExtensionFails() {
        // setup
        let expectation = XCTestExpectation(description: "Extension is unregistration fails as MockExtensionTwo is not registered")
        expectation.assertForOverFulfill = true

        // test
        eventHub.start()
        eventHub.unregisterExtension(MockExtensionTwo.self) { error in
            expectation.fulfill()
            XCTAssertEqual(EventHubError.extensionNotRegistered, error)
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// An extension can be registered, then unregistered, then registered again
    func testEventHubUnregisterExtensionThenRegister() {
        // setup
        registerMockExtension(MockExtensionTwo.self)
        let expectation = XCTestExpectation(description: "Extension is unregistered successfully after eventHub.start()")
        expectation.assertForOverFulfill = true
        let registerExpectation = XCTestExpectation(description: "Extension is registered successfully after being unregistered")
        registerExpectation.assertForOverFulfill = true

        MockExtensionTwo.unregistrationClosure = { expectation.fulfill() }
        MockExtensionTwo.registrationClosure = { registerExpectation.fulfill() }

        // test
        eventHub.start()
        eventHub.unregisterExtension(MockExtensionTwo.self) { error in
            XCTAssertNil(error)
            self.eventHub.registerExtension(MockExtensionTwo.self) { (error) in
                XCTAssertNil(error)
            }
        }

        // verify
        wait(for: [expectation, registerExpectation], timeout: 1)
    }

    /// Tests that after an extension is unregistered that it cannot receive new events
    func testEventHubUnregisteredExtensionDoesNotReceiveEvents() {
        // setup
        let expectation = XCTestExpectation(description: "Mock extension should only receive one event")
        expectation.assertForOverFulfill = true
        registerMockExtension(MockExtensionTwo.self)

        MockExtensionTwo.eventReceivedClosure = { event in
            if event.type == EventType.acquisition { expectation.fulfill() }
        }

        // test
        eventHub.start()
        eventHub.dispatch(event: Event(name: "First event", type: EventType.acquisition, source: EventSource.none, data: nil))
        eventHub.unregisterExtension(MockExtensionTwo.self) { error in
            XCTAssertNil(error)
            // dispatch event after MockExtensionTwo has been unregistered, this should not be received by MockExtensionTwo
            self.eventHub.dispatch(event: Event(name: "Second event", type: EventType.acquisition, source: EventSource.none, data: nil))
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that when we share state that we use configuration's version as the top level version and include all the extensions
    /*
     Expected format:
     {
       "version" : "0.0.1",
       "wrapper" : {
         "type" : "F",
         "friendlyName" : "Flutter"
       }
       "extensions" : {
         "mockExtension" : {
           "version" : "0.0.1"
         },
         "mockExtensionTwo" : {
           "version" : "0.0.1"
         }
       }
     }
     */
    func testEventHubRegisterExtensionSharesState() {
        // setup
        let sharedStateExpectation = XCTestExpectation(description: "Shared state should be shared by event hub once")
        sharedStateExpectation.assertForOverFulfill = true

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String == EventHubConstants.NAME { sharedStateExpectation.fulfill() }
        }

        // test
        registerMockExtension(MockExtensionTwo.self)

        let wrapperType = WrapperType.flutter
        eventHub.setWrapperType(wrapperType)
        eventHub.start()

        // verify
        wait(for: [sharedStateExpectation], timeout: 1)
        let sharedState = eventHub.getSharedState(extensionName: EventHubConstants.NAME, event: nil)!.value

        let mockExtension = MockExtension(runtime: TestableExtensionRuntime())
        let mockExtensionTwo = MockExtensionTwo(runtime: TestableExtensionRuntime())

        let coreVersion = sharedState?[EventHubConstants.EventDataKeys.VERSION] as! String
        let registeredExtensions = sharedState?[EventHubConstants.EventDataKeys.EXTENSIONS] as? [String: Any]
        let mockDetails = registeredExtensions?[mockExtension.name] as? [String: String]
        let mockDetailsTwo = registeredExtensions?[mockExtensionTwo.name] as? [String: Any]
        let wrapper = sharedState?[EventHubConstants.EventDataKeys.WRAPPER] as? [String: Any]

        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION, coreVersion) // should contain {version: coreVersion}
        XCTAssertEqual(MockExtension.extensionVersion, mockDetails?[EventHubConstants.EventDataKeys.VERSION])
        XCTAssertEqual(MockExtensionTwo.extensionVersion, mockDetailsTwo?[EventHubConstants.EventDataKeys.VERSION] as? String)
        XCTAssertEqual(mockExtensionTwo.metadata, mockDetailsTwo?[EventHubConstants.EventDataKeys.METADATA] as? [String: String])
        XCTAssertEqual(wrapperType.rawValue, wrapper?[EventHubConstants.EventDataKeys.TYPE] as? String)
        XCTAssertEqual(wrapperType.friendlyName, wrapper?[EventHubConstants.EventDataKeys.FRIENDLY_NAME] as? String)
    }

    func testEventHubShareEventHubStateBeforeStart() {
        // setup
        let sharedStateExpectation = XCTestExpectation(description: "Shared state should NOT be shared by event hub")
        sharedStateExpectation.isInverted = true // shared state should not be published by event hub before start

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String == EventHubConstants.NAME { sharedStateExpectation.fulfill() }
        }

        // test
        eventHub.shareEventHubSharedState()

        // verify
        wait(for: [sharedStateExpectation], timeout: 1)
    }

    func testEventHubShareEventHubStateAfterStart() {
        // setup
        let sharedStateExpectation = XCTestExpectation(description: "Shared state should be shared by event hub")
        sharedStateExpectation.assertForOverFulfill = true
        sharedStateExpectation.expectedFulfillmentCount = 2 // one from the start call and one from shareEventHubSharedState

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String == EventHubConstants.NAME { sharedStateExpectation.fulfill() }
        }

        // test
        eventHub.start()
        eventHub.shareEventHubSharedState()

        // verify
        wait(for: [sharedStateExpectation], timeout: 1)
    }

    func testEventHubRegisterAndUnregisterExtensionSharesState() {
        // setup
        let sharedStateExpectation = XCTestExpectation(description: "Shared state should be shared by event hub once")
        sharedStateExpectation.expectedFulfillmentCount = 2
        sharedStateExpectation.assertForOverFulfill = true

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String == EventHubConstants.NAME { sharedStateExpectation.fulfill() }
        }

        // test
        registerMockExtension(MockExtensionTwo.self)
        eventHub.start()
        eventHub.unregisterExtension(MockExtensionTwo.self, completion: { (_) in })

        // verify
        wait(for: [sharedStateExpectation], timeout: 1)
        let sharedState = eventHub.getSharedState(extensionName: EventHubConstants.NAME, event: nil)!.value

        let mockExtension = MockExtension(runtime: TestableExtensionRuntime())

        let coreVersion = sharedState?[EventHubConstants.EventDataKeys.VERSION] as! String
        let registeredExtensions = sharedState?[EventHubConstants.EventDataKeys.EXTENSIONS] as? [String: Any]
        let mockDetails = registeredExtensions?[mockExtension.name] as? [String: String]

        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION, coreVersion) // should contain {version: coreVersion}
        XCTAssertEqual(MockExtension.extensionVersion, mockDetails?[EventHubConstants.EventDataKeys.VERSION])
    }

    func testEventHubRegisterExtensionSuccessQueuedBeforeStart() {
        // setup
        let expectation = XCTestExpectation(description: "Extension is registered successfully even if invoked before eventHub.start()")
        expectation.assertForOverFulfill = true

        MockExtensionTwo.registrationClosure = { expectation.fulfill() }

        // test
        eventHub.registerExtension(MockExtensionTwo.self) { error in
            XCTAssertNil(error)
        }
        eventHub.start()

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubRegisterSameExtensionTwiceFails() {
        // setup
        let expectation = XCTestExpectation(description: "Extension registration fails with EventHubError.duplicateExtensionName when registered twice")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        // test
        eventHub.start()
        eventHub.registerExtension(MockExtensionTwo.self) { [weak self] error in
            XCTAssertNil(error)

            // register same extension twice
            self?.eventHub.registerExtension(MockExtensionTwo.self) { error in
                XCTAssertEqual(error, EventHubError.duplicateExtensionName)
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testEventHubRegistersExtensionWithSlowExtensionStillRegisters() {
        // setup
        let expectation = XCTestExpectation(description: "Extensions with poor performance upon registration do not block other extensions from registering")
        expectation.assertForOverFulfill = true

        MockExtensionTwo.registrationClosure = { expectation.fulfill() }

        // test
        eventHub.start()
        eventHub.registerExtension(SlowMockExtension.self) { _ in
            // won't be invoked in time since SlowMockExtension has a poor performing constructor
        }

        eventHub.registerExtension(MockExtensionTwo.self) { error in
            XCTAssertNil(error)
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    // Can somewhat test thread safety, however it is registering the same extension 100 times..
    func testEventHubRegisterManyExtensions() {
        // setup
        let expectation = XCTestExpectation(description: "EventHub successfully registers 100 different extensions")
        expectation.expectedFulfillmentCount = 100
        expectation.assertForOverFulfill = true

        // test
        eventHub.start()
        for i in 0 ..< expectation.expectedFulfillmentCount {
            let queue = DispatchQueue(label: "com.adobe.mock.extension.\(i)")
            queue.async {
                self.eventHub.registerExtension(MockExtensionTwo.self) { _ in
                    expectation.fulfill()
                }
            }
        }

        // verify
        wait(for: [expectation], timeout: 5.0)
    }

    func testEventHubDeinit() {
        var hub: EventHub? = EventHub()
        hub = nil
        XCTAssert(hub == nil)
    }

    // MARK: WrapperType Tests
    /// Tests the default value of wrapper type is None
    func testDefaultWrapperType() {
        XCTAssertEqual(eventHub.getWrapperType(), WrapperType.none)
    }

    /// Tests updating the wrapper type before start call.
    func testUpdateWrapperTypeBeforeStart() {
        eventHub.setWrapperType(WrapperType.flutter)
        XCTAssertEqual(eventHub.getWrapperType(), WrapperType.flutter)

        eventHub.setWrapperType(WrapperType.reactNative)
        XCTAssertEqual(eventHub.getWrapperType(), WrapperType.reactNative)

        eventHub.setWrapperType(WrapperType.cordova)
        XCTAssertEqual(eventHub.getWrapperType(), WrapperType.cordova)
    }

    /// Tests updating the wrapper type after start call.
    func testUpdateWrapperTypeAfterStart() {
        eventHub.setWrapperType(WrapperType.flutter)
        XCTAssertEqual(eventHub.getWrapperType(), WrapperType.flutter)

        eventHub.start()

        // Updates to wrapper type fail after start() call
        eventHub.setWrapperType(WrapperType.reactNative)
        XCTAssertEqual(eventHub.getWrapperType(), WrapperType.flutter)

        eventHub.setWrapperType(WrapperType.cordova)
        XCTAssertEqual(eventHub.getWrapperType(), WrapperType.flutter)
    }

    // MARK: SharedState Tests

    /// Ensures an extension that is not registered cannot publish shared state
    func testCreateSharedStateExtensionNotRegistered() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: "mockExtensionTwo", data: SharedStateTestHelper.ONE, event: nil)

        // verify
        XCTAssertNil(eventHub.getSharedState(extensionName: "notRegistered", event: nil))
    }

    /// Tests that a registered extension can publish shared state
    func testGetSharedStateSimple() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one")
    }

    /// Tests that a registered extension can publish shared state and case is ignored
    func testGetSharedStateCaseInsensitive() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME.uppercased(), data: SharedStateTestHelper.ONE, event: nil)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME.lowercased(), nil, "one")
    }

    /// Tests that a registered extension can publish shared state versioned at an event
    func testGetSharedStateSimpleWithEvent() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "event", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")
    }

    /// Tests that you cannot override an existing shared state version
    func testGetSharedStateSimpleWithEventNotOverride() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "event", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event)

        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: event) // already set shared state for this version, should fail

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")
    }

    /// Tests that shared states are correctly versioned at the event they were created with
    func testGetSharedStateSimpleWithEventMultiple() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "event", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event)
        let event1 = Event(name: "event1", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event1)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: event1)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event1, "two")
    }

    /// Tests that shared state for an extension is updated at the latest
    func testGetSharedStateSimpleCreateTwice() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "Test event", type: EventType.analytics, source: EventSource.none, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event)
        let event1 = Event(name: "Test event", type: EventType.analytics, source: EventSource.none, data: nil)
        eventHub.dispatch(event: event1)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: event1)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event1, "two")
    }

    /// Tests that multiple shared state updates function properly
    func testGetSharedStateSimpleCreateThreeTimes() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "Test event", type: EventType.analytics, source: EventSource.none, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")

        let event1 = Event(name: "Test event", type: EventType.analytics, source: EventSource.none, data: nil)
        eventHub.dispatch(event: event1)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: event1)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event1, "two")

        let event2 = Event(name: "Test event", type: EventType.analytics, source: EventSource.none, data: nil)
        eventHub.dispatch(event: event2)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.THREE, event: event2)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event2, "three")
    }

    /// Shared state is versioned at event correctly
    func testGetSharedStateAfterEventDispatched() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")
    }

    /// Ensures that events dispatched are associated with the correct shared state versions
    func testGetSharedStateUsesCorrectVersion() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event)
        let event1 = Event(name: "test1", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event1)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: event1)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event1, "two")
    }

    func testGetSharedStateNilEvent() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one")
    }

    func testGetSharedStateNilEventTwice() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: nil)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "two")
    }

    func testGetSharedStateNilEventVersionsAtLatest() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)
        let event1 = Event(name: "test1", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event1)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: event1)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "two")
    }

    func testGetSharedStateUnversionedEventVersionsAtLatest() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)
        let event1 = Event(name: "test1", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event1)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: event1)

        // verify
        let unversionedEvent = Event(name: "unversioned", type: EventType.custom, source: EventSource.none, data: nil)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, unversionedEvent, "two")

        // test pt. 2
        let event2 = Event(name: "test2", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event2)

        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.THREE, event: event2)

        // verify pt. 2
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, unversionedEvent, "three")
    }

    /// Tests that events are associated with current shared state when updated rapidly
    func testGetSharedStateUsesCorrectVersionManyEvents() {
        // setup
        eventHub.start()
        var events = [Event]()

        // test
        for i in 1 ... 100 {
            let event = Event(name: "\(i)", type: EventType.analytics, source: EventSource.requestContent, data: nil)
            events.append(event)
            eventHub.dispatch(event: event)
            eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: [SharedStateTestHelper.DICT_KEY: "\(i)"], event: event)
        }

        // verify
        for event in events {
            validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, event.name)
        }
    }

    /// Tests that events are associated with current shared state when updated rapidly from multiple queues
    func testGetSharedStateUsesCorrectVersionManyEventsManyQueues() {
        // setup
        let expectation = XCTestExpectation(description: "EventHub successfully updates 100 different shared states on many queues")
        expectation.expectedFulfillmentCount = 100
        expectation.assertForOverFulfill = true
        eventHub.start()
        var events = [Event]()

        // test
        for i in 1 ... expectation.expectedFulfillmentCount {
            let event = Event(name: "\(i)", type: EventType.analytics, source: EventSource.requestContent, data: nil)
            events.append(event)
            DispatchQueue(label: "Event queue \(i)").sync {
                self.eventHub.dispatch(event: event)
                self.eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: [SharedStateTestHelper.DICT_KEY: "\(i)"], event: event)
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 5.0)
        for event in events {
            validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, event.name)
        }
    }

    /// Tests that we can create and resolve a pending shared state
    func testCreatePendingAndResolvePendingSimple() {
        // setup
        let expectation = XCTestExpectation(description: "Pending shared state resolved correctly")
        expectation.assertForOverFulfill = true
        eventHub.start()

        let event = Event(name: "test", type: EventType.acquisition, source: EventSource.requestContent, data: nil)
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }
        eventHub.dispatch(event: event)

        // test
        let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event)
        pendingResolver(SharedStateTestHelper.ONE)

        // verify
        wait(for: [expectation], timeout: 1)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one")
    }

    /// Tests that we can create and resolve a pending shared state and case is ignored
    func testCreatePendingAndResolvePendingSimpleCaseInsensitive() {
        // setup
        let expectation = XCTestExpectation(description: "Pending shared state resolved correctly")
        expectation.assertForOverFulfill = true
        eventHub.start()

        let event = Event(name: "test", type: EventType.acquisition, source: EventSource.requestContent, data: nil)
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
                expectation.fulfill()
            }
        }
        eventHub.dispatch(event: event)

        // test
        let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME.uppercased(), event: event)
        pendingResolver(SharedStateTestHelper.ONE)

        // verify
        wait(for: [expectation], timeout: 1)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME.lowercased(), nil, "one")
    }

    /// Tests that we can create and resolve a pending XDM shared state
    func testCreatePendingAndResolveXDMPendingSimple() {
        // setup
        let expectation = XCTestExpectation(description: "XDM Pending shared state resolved correctly")
        expectation.assertForOverFulfill = true
        eventHub.start()

        let event = Event(name: "test", type: EventType.acquisition, source: EventSource.requestContent, data: nil)
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                XCTAssertEqual(event.name, EventHubConstants.XDM_STATE_CHANGE)
                expectation.fulfill()
            }
        }
        eventHub.dispatch(event: event)

        // test
        let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event, sharedStateType: .xdm)
        pendingResolver(SharedStateTestHelper.ONE)

        // verify
        wait(for: [expectation], timeout: 1)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one", .xdm)
    }

    /// Ensures that an extension who does not resolve their pending shared state has a nil shared state
    func testSharedStateEmptyWhenNoResolve() {
        // setup
        let expectation = XCTestExpectation(description: "Shared state is nil when pending shared state isn't resolved")
        expectation.assertForOverFulfill = true
        expectation.isInverted = true
        eventHub.start()

        let event = Event(name: "test", type: EventType.acquisition, source: EventSource.requestContent, data: nil)
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }
        eventHub.dispatch(event: event)

        // test
        _ = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event)

        // verify
        wait(for: [expectation], timeout: 0.25)
        XCTAssertNil(eventHub.getSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event)?.value)
    }

    /// Test: create shared state -> create pending shared state -> resolve pending shared state
    func testCreatePendingAfterValidState() {
        // setup
        let expectation = XCTestExpectation(description: "create shared state -> create pending shared state -> resolve pending shared state")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        eventHub.start()

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }

        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)

        // test
        let event = Event(name: "test", type: EventType.acquisition, source: EventSource.sharedState, data: nil)
        eventHub.dispatch(event: event)
        let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event)
        pendingResolver(SharedStateTestHelper.TWO)

        wait(for: [expectation], timeout: 1)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "two")
    }

    /// Tests that we can create and resolve a pending shared state from many queues
    func testCreatePendingManyEventsManyQueues() {
        // setup
        let expectation = XCTestExpectation(description: "EventHub successfully updates 100 different shared states")
        expectation.expectedFulfillmentCount = 100
        expectation.assertForOverFulfill = true
        eventHub.start()
        var events = [Event]()

        // test
        for i in 1 ... expectation.expectedFulfillmentCount {
            let event = Event(name: "\(i)", type: EventType.analytics, source: EventSource.requestContent, data: nil)
            events.append(event)
            DispatchQueue(label: "Event queue \(i)").sync {
                self.eventHub.dispatch(event: event)
                let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event)
                pendingResolver([SharedStateTestHelper.DICT_KEY: "\(i)"])
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 5.0)
        for event in events {
            validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, event.name)
        }
    }

    /// hasSharedState returns false when we haven't published a shared state
    func testEventHubHasSharedStateNotPublished() {
        // setup
        eventHub.start()

        // test & verify
        XCTAssertEqual(eventHub.getSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: nil)?.status, SharedStateStatus.none)
    }

    /// Setting shared state for first version is considered set
    func testEventHubHasSharedStatePublished() {
        // setup
        let expectation = XCTestExpectation(description: "Creating shared state dispatches an event")
        expectation.assertForOverFulfill = true
        eventHub.start()

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                XCTAssertEqual(self.eventHub.getSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: nil)?.status, SharedStateStatus.set)
                expectation.fulfill()
            }
        }

        // test
        XCTAssertEqual(eventHub.getSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: nil)?.status, SharedStateStatus.none)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: nil, event: nil)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testCreatePendingSharedStateNilEvent() {
        // setup
        let expectation = XCTestExpectation(description: "Pending shared state resolved correctly")
        expectation.assertForOverFulfill = true
        eventHub.start()

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
            XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }

        // test
        let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: nil)
        pendingResolver(SharedStateTestHelper.ONE)

        // verify
        wait(for: [expectation], timeout: 1)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one")
    }

    // use event preprocessor to return a new event
    func testRegisterPreprocessor() {
        // setup
        let targetRequestContentExpectation = XCTestExpectation(description: "Received hub shared state event")
        targetRequestContentExpectation.isInverted = true

        let analyticsRequestContentExpectation = XCTestExpectation(description: "Received hub shared state event")
        analyticsRequestContentExpectation.assertForOverFulfill = true

        eventHub.registerPreprocessor { event in
            if event.type == EventType.target, event.source == EventSource.requestContent {
                return Event(name: "event", type: EventType.analytics, source: EventSource.requestContent, data: nil)
            }
            return event
        }
        eventHub.start()

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.target, source: EventSource.requestContent) { _ in
            targetRequestContentExpectation.fulfill()
        }
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.analytics, source: EventSource.requestContent) { _ in
            analyticsRequestContentExpectation.fulfill()
        }

        // test
        eventHub.dispatch(event: Event(name: "event", type: EventType.target, source: EventSource.requestContent, data: nil))

        // verify
        wait(for: [targetRequestContentExpectation, analyticsRequestContentExpectation], timeout: 1)
    }

    // MARK: XDM SharedState Tests

    /// Tests that a registered extension can publish shared state
    func testGetXDMSharedStateSimple() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil, sharedStateType: .xdm)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one", .xdm)
    }

    /// Tests that a registered extension can publish shared state versioned at an event
    func testGetXDMSharedStateSimpleWithEvent() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "event", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event, sharedStateType: .xdm)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one", .xdm)
    }
}
