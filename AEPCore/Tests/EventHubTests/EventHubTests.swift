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

class EventHubTests: XCTestCase {
    private static let MOCK_EXTENSION_NAME = "mockExtension"

    var eventHub: EventHub!

    override func setUp() {
        eventHub = EventHub()
        MockExtension.reset()
        MockExtensionTwo.reset()
        registerMockExtension(MockExtension.self)
    }

    // MARK: Helper functions
    private func validateSharedState(_ extensionName: String, _ event: Event?, _ dictionaryValue: String) {
        XCTAssertEqual(eventHub.getSharedState(extensionName: extensionName, event: event)?.value![SharedStateTestHelper.DICT_KEY] as! String, dictionaryValue)
    }

    private func registerMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        eventHub.registerExtension(type) { (error) in
            XCTAssertNil(error)
            semaphore.signal()
        }

        semaphore.wait()
    }

    func testEventHubDispatchesEventToListener() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is invoked exactly once")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubDoesNotInvokeListenerWrongType() {
        // setup
        let expectation = XCTestExpectation(description: "Does not invoke listener when type doesn't match")
        expectation.isInverted = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .acquisition, source: testEvent.source) { (event) in
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubNeverDispatchesEventToListenerWithoutStart() {
        // setup
        let expectation = XCTestExpectation(description: "EventHub does not invoke listeners when not started")
        expectation.isInverted = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
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
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent)
        eventHub.start()

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubDispatchesEventToListenerAndIgnoresNonMatchingEvent() {
        // setup
        let expectation = XCTestExpectation(description: "Invokes listener with matching type and source, then ignores Event of non-matching type and source")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)
        let testEvent1 = Event(name: "testEvent1", type: .identity, source: .requestIdentity, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent1) // should not invoke listener

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubDispatchesEventsToListener() {
        // setup
        let expectation = XCTestExpectation(description: "Invokes listener with matching Events")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)
        let testEvent1 = Event(name: "testEvent1", type: testEvent.type, source: testEvent.source, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.type == testEvent.type && event.source == testEvent.source)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent1)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubDispatchesEventsToMultipleListeners() {
        // setup
        let expectation = XCTestExpectation(description: "Invokes first listener with matching Events")
        let expectation1 = XCTestExpectation(description: "Invokes second listener with matching Events")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        expectation1.expectedFulfillmentCount = 2
        expectation1.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.type == testEvent.type && event.source == testEvent.source)
            expectation.fulfill()
        }

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.type == testEvent.type && event.source == testEvent.source)
            expectation1.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation, expectation1], timeout: 0.5)
    }

    func testEventHubDispatchesEventsToCorrectListeners() {
        // setup
        let expectation = XCTestExpectation(description: "First listener is invoked by testEvent and not by testEvent1")
        let expectation1 = XCTestExpectation(description: "Second listener is invoked by testEvent1 and not by testEvent")
        expectation.assertForOverFulfill = true
        expectation1.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)
        let testEvent1 = Event(name: "testEvent1", type: .places, source: .responseContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent1.type, source: testEvent1.source) { (event) in
            XCTAssert(event.name == testEvent1.name)
            expectation1.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent) // should invoke first listener
        eventHub.dispatch(event: testEvent1) // should invoke second listener

        // verify
        wait(for: [expectation, expectation1], timeout: 0.5)
    }

    func testEventHubTestResponseListener() {
        // setup
        let expectation = XCTestExpectation(description: "Response listener is invoked exactly once")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)
        let testResponseEvent = testEvent.createResponseEvent(name: "testResponseEvent", type: testEvent.type, source: .responseContent, data: nil)

        // test
        // listens for a event of type analytics and source response content
        eventHub.registerResponseListener(triggerEvent: testEvent, timeout: 1) { (event) in
            XCTAssert(event?.name == testResponseEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testResponseEvent)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubTestResponseListenerRemovedAfterInvoked() {
        // setup
        let expectation = XCTestExpectation(description: "Response listener is invoked exactly once, and removed after receiving one response event")
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)
        let testResponseEvent = testEvent.createResponseEvent(name: "testResponseEvent", type: testEvent.type, source: .responseContent, data: nil)

        // test
        // listens for a event of type analytics and source response content
        eventHub.registerResponseListener(triggerEvent: testEvent, timeout: 1) { (event) in
            XCTAssert(event?.name == testResponseEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testResponseEvent)
        eventHub.dispatch(event: testResponseEvent)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubTestResponseListenerNotInvoked() {
        // setup
        let expectation = XCTestExpectation(description: "Response listener is not invoked by other request event")
        expectation.assertForOverFulfill = true
        let requestEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)
        let otherRequestEvent = Event(name: "testEvent1", type: .analytics, source: .requestContent, data: nil)
        let otherResponseEvent = otherRequestEvent.createResponseEvent(name: "testResponseEvent1", type: otherRequestEvent.type, source: .responseContent, data: nil)

        // test
        eventHub.registerResponseListener(triggerEvent: requestEvent, timeout: 0.25) { (event) in
            XCTAssertNil(event) // event should be nil since the response listener will have timed-out
            expectation.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: otherRequestEvent)
        eventHub.dispatch(event: otherResponseEvent)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubDispatchesEventsWithBlockingListener() {
        // setup
        let expectation = XCTestExpectation(description: "Invoke blocking listener with matching Event and ignored Event of non-matching type and source")
        let expectation1 = XCTestExpectation(description: "Long running listener does not")
        expectation.assertForOverFulfill = true
        expectation1.assertForOverFulfill = true
        registerMockExtension(MockExtensionTwo.self)
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)


        // test
        eventHub.getExtensionContainer(MockExtensionTwo.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            expectation.fulfill()
            // simulate a long running listener
            sleep(20)
        }

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            expectation1.fulfill()
        }

        eventHub.start()
        eventHub.dispatch(event: testEvent)

        // verify
        wait(for: [expectation, expectation1], timeout: 0.5)
    }

    func testEventHubDispatchesEventFromExtensionQueue() {
        // setup
        let expectation = XCTestExpectation(description: "Listener is called exactly once when invoked from extension queue")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        let testEvent = Event(name: "testEvent", type: .analytics, source: .requestContent, data: nil)

        // test
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: testEvent.type, source: testEvent.source) { (event) in
            XCTAssert(event.name == testEvent.name)
            expectation.fulfill()
        }

        eventHub.start()
        DispatchQueue(label: "com.adobe.mock.extension").async { self.eventHub.dispatch(event: testEvent) }

        // verify
        wait(for: [expectation], timeout: 0.5)
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
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: type, source: source) { (event) in
            XCTAssert(type == event.type && source == event.source)
            expectation.fulfill()
        }

        eventHub.start()

        for i in 0..<expectation.expectedFulfillmentCount {
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
        eventHub.registerExtension(MockExtensionTwo.self) { (error) in
            XCTAssertNil(error)
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
    
    /// Tests that when we share state that we use configuration's version as the top level version and include all the extensions
    /*
     Expected format:
     {
       "version" : "0.0.1",
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
        
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String == EventHubConstants.NAME { sharedStateExpectation.fulfill() }
        }
        
        // test
        registerMockExtension(MockExtensionTwo.self)
        eventHub.start()
        
        // verify
        wait(for: [sharedStateExpectation], timeout: 0.5)
        let sharedState = eventHub.getSharedState(extensionName: EventHubConstants.NAME, event: nil)!.value
        
        let mockExtension = MockExtension(runtime: TestableExtensionRuntime())
        let mockExtensionTwo = MockExtensionTwo(runtime: TestableExtensionRuntime())
        
        let coreVersion = sharedState?[EventHubConstants.EventDataKeys.VERSION] as! String
        let registeredExtensions = sharedState?[EventHubConstants.EventDataKeys.EXTENSIONS] as? [String: Any]
        let mockDetails = registeredExtensions?[mockExtension.friendlyName] as? [String: String]
        let mockDetailsTwo = registeredExtensions?[mockExtensionTwo.friendlyName] as? [String: Any]
        
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION, coreVersion) // should contain {version: coreVersion}
        XCTAssertEqual(MockExtension.extensionVersion, mockDetails?[EventHubConstants.EventDataKeys.VERSION])
        XCTAssertEqual(MockExtensionTwo.extensionVersion, mockDetailsTwo?[EventHubConstants.EventDataKeys.VERSION] as? String)
        XCTAssertEqual(mockExtensionTwo.metadata, mockDetailsTwo?[EventHubConstants.EventDataKeys.METADATA] as? [String: String])
    }

    func testEventHubRegisterExtensionSuccessQueuedBeforeStart() {
        // setup
        let expectation = XCTestExpectation(description: "Extension is registered successfully even if invoked before eventHub.start()")
        expectation.assertForOverFulfill = true
        
        MockExtensionTwo.registrationClosure = { expectation.fulfill() }

        // test
        eventHub.registerExtension(MockExtensionTwo.self) { (error) in
            XCTAssertNil(error)
        }
        eventHub.start()

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubRegisterSameExtensionTwiceFails() {
        // setup
        let expectation = XCTestExpectation(description: "Extension registration fails with EventHubError.duplicateExtensionName when registered twice")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
                
        // test
        eventHub.start()
        eventHub.registerExtension(MockExtensionTwo.self) { [weak self] (error) in
            XCTAssertNil(error)

            // register same extension twice
            self?.eventHub.registerExtension(MockExtensionTwo.self) { (error) in
                XCTAssertEqual(error, EventHubError.duplicateExtensionName)
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testEventHubRegistersExtensionWithSlowExtensionStillRegisters() {
        // setup
        let expectation = XCTestExpectation(description: "Extensions with poor performance upon registration do not block other extensions from registering")
        expectation.assertForOverFulfill = true
        
        MockExtensionTwo.registrationClosure = { expectation.fulfill() }
        
        // test
        eventHub.start()
        eventHub.registerExtension(SlowMockExtension.self) { (error) in
            // won't be invoked in time since SlowMockExtension has a poor performing constructor
        }

        eventHub.registerExtension(MockExtensionTwo.self) { (error) in
            XCTAssertNil(error)
        }

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    // Can somewhat test thread safety, however it is registering the same extension 100 times..
    func testEventHubRegisterManyExtensions() {
        // setup
        let expectation = XCTestExpectation(description: "EventHub successfully registers 100 different extensions")
        expectation.expectedFulfillmentCount = 100
        expectation.assertForOverFulfill = true

        // test
        eventHub.start()
        for i in 0..<expectation.expectedFulfillmentCount {
            let queue = DispatchQueue(label: "com.adobe.mock.extension.\(i)")
            queue.async {
                self.eventHub.registerExtension(MockExtensionTwo.self) { (error) in
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

    /// Tests that a registered extension can publish shared state versioned at an event
    func testGetSharedStateSimpleWithEvent() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "event", type: .analytics, source: .requestContent, data: nil)
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
        let event = Event(name: "event", type: .analytics, source: .requestContent, data: nil)
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
        let event = Event(name: "event", type: .analytics, source: .requestContent, data: nil)
        eventHub.dispatch(event: event)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: event)
        let event1 = Event(name: "event1", type: .analytics, source: .requestContent, data: nil)
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
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: nil)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "two")
    }

    /// Tests that multiple shared state updates function properly
    func testGetSharedStateSimpleCreateThreeTimes() {
        // setup
        eventHub.start()

        // test
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one")
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: nil)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "two")
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.THREE, event: nil)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "three")
    }

    /// Shared state is versioned at event correctly
    func testGetSharedStateAfterEventDispatched() {
        // setup
        eventHub.start()

        // test
        let event = Event(name: "test", type: .analytics, source: .requestContent, data: nil)
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
        let event = Event(name: "test", type: .analytics, source: .requestContent, data: nil)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)
        eventHub.dispatch(event: event)
        let event1 = Event(name: "test1", type: .analytics, source: .requestContent, data: nil)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.TWO, event: nil)
        eventHub.dispatch(event: event1)

        // verify
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event, "one")
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, event1, "two")
    }

    /// Tests that events are associated with current shared state when updated rapidly
    func testGetSharedStateUsesCorrectVersionManyEvents() {
        // setup
        eventHub.start()
        var events = [Event]()

        // test
        for i in 1...100 {
            let event = Event(name: "\(i)", type: .analytics, source: .requestContent, data: nil)
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
        for i in 1...expectation.expectedFulfillmentCount {
            let event = Event(name: "\(i)", type: .analytics, source: .requestContent, data: nil)
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

        let event = Event(name: "test", type: .acquisition, source: .requestContent, data: nil)
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
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
        wait(for: [expectation], timeout: 0.5)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "one")
    }

    /// Ensures that an extension who does not resolve their pending shared state has a nil shared state
    func testSharedStateEmptyWhenNoResolve() {
        // setup
        let expectation = XCTestExpectation(description: "Shared state is nil when pending shared state isn't resolved")
        expectation.assertForOverFulfill = true
        expectation.isInverted = true
        eventHub.start()

        let event = Event(name: "test", type: .acquisition, source: .requestContent, data: nil)
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }
        eventHub.dispatch(event: event)

        // test
        let _ = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event)


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

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }

        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: SharedStateTestHelper.ONE, event: nil)

        // test
        let event = Event(name: "test", type: .acquisition, source: .sharedState, data: nil)
        eventHub.dispatch(event: event)
        let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: event)
        pendingResolver(SharedStateTestHelper.TWO)

        wait(for: [expectation], timeout: 0.5)
        validateSharedState(EventHubTests.MOCK_EXTENSION_NAME, nil, "two")
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
         for i in 1...expectation.expectedFulfillmentCount {
             let event = Event(name: "\(i)", type: .analytics, source: .requestContent, data: nil)
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

    /// hasSharedState returns true when we have published a shared state
    func testEventHubHasSharedStatePublished() {
        // setup
        let expectation = XCTestExpectation(description: "hasSharedState returns true when we have published a shared state")
        expectation.assertForOverFulfill = true
        eventHub.start()

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }

        // test
        XCTAssertEqual(eventHub.getSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: nil)?.status, SharedStateStatus.none)
        eventHub.createSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, data: nil, event: nil)

        // verify
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(eventHub.getSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: nil)?.status, SharedStateStatus.set)
    }
    
    func testCreatePendingSharedStateNilEvent() {
        // setup
        let expectation = XCTestExpectation(description: "Pending shared state resolved correctly")
        expectation.assertForOverFulfill = true
        eventHub.start()

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .hub, source: .sharedState) { (event) in
            XCTAssertEqual(event.name, EventHubConstants.STATE_CHANGE)
            if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as! String == EventHubTests.MOCK_EXTENSION_NAME {
                expectation.fulfill()
            }
        }

        // test
        let pendingResolver = eventHub.createPendingSharedState(extensionName: EventHubTests.MOCK_EXTENSION_NAME, event: nil)
        pendingResolver(SharedStateTestHelper.ONE)


        // verify
        wait(for: [expectation], timeout: 0.5)
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
            if event.type == .target && event.source == .requestContent {
                return Event(name: "event", type: .analytics, source: .requestContent, data: nil)
            }
            return event
        }
        eventHub.start()

        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .target, source: .requestContent) { (event) in
            targetRequestContentExpectation.fulfill()
        }
        eventHub.getExtensionContainer(MockExtension.self)?.registerListener(type: .analytics, source: .requestContent) { (event) in
            analyticsRequestContentExpectation.fulfill()
        }

        // test
        eventHub.dispatch(event: Event(name: "event", type: .target, source: .requestContent, data: nil))


        // verify
        wait(for: [targetRequestContentExpectation,analyticsRequestContentExpectation], timeout: 0.5)
    }
    
    /// Tests that we can register an Objective-C extension
    func testRegisterObjcExtension() {
        // setup
        let expectation = XCTestExpectation(description: "Objective-C Extension is registered successfully after eventHub.start()")
        expectation.assertForOverFulfill = true

        // test
        eventHub.start()
        eventHub.registerExtension(MockObjcExtension.self) { (error) in
            expectation.fulfill()
            XCTAssertNil(error)
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }
}
