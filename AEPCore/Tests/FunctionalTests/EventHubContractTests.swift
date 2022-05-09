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
@testable import AEPServices
@testable import AEPCoreMocks

class EventHubContractTest: XCTestCase {
    override func setUp() {
        EventHub.reset()  
        ContractExtensionOne.reset()
        ContractExtensionTwo.reset()
    }

    override func tearDown() {

    }


    // MARK: - EventHub Registration

    /// Tests init is called before onRegister
    func testInitThenOnRegister() {
        // setup
        let extensionOneInitExpectation = XCTestExpectation(description: "Extension one init is invoked")
        let extensionTwoInitExpectation = XCTestExpectation(description: "Extension two init is invoked")
        let extensionOneRegisteredExpectation = XCTestExpectation(description: "Extension one onRegistered is invoked")
        let extensionTwoRegisteredExpectation = XCTestExpectation(description: "Extension two onRegistered is invoked")
        ContractExtensionOne.onInitClosure = {
            extensionOneInitExpectation.fulfill()
        }
        ContractExtensionOne.registrationClosure = {
            extensionOneRegisteredExpectation.fulfill()
        }

        ContractExtensionTwo.onInitClosure = {
            extensionTwoInitExpectation.fulfill()
        }
        ContractExtensionTwo.registrationClosure = {
            extensionTwoRegisteredExpectation.fulfill()
        }

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self, ContractExtensionTwo.self]) {
        }

        // verify
        wait(for: [extensionOneInitExpectation, extensionOneRegisteredExpectation], timeout: 0.5, enforceOrder: true)

        wait(for: [extensionTwoInitExpectation, extensionTwoRegisteredExpectation], timeout: 0.5, enforceOrder: true)

    }

    /// Tests the start callback gets called after all the extension finish registration
    func testStartCallbackCalledAfterRegistrationComplete() {
        // setup
        let extensionOneRegisteredExpectation = XCTestExpectation(description: "Extension one onRegistered is invoked")
        let extensionTwoRegisteredExpectation = XCTestExpectation(description: "Extension two onRegistered is invoked")
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        ContractExtensionOne.registrationClosure = {
            extensionOneRegisteredExpectation.fulfill()
        }

        ContractExtensionTwo.registrationClosure = {
            Thread.sleep(forTimeInterval:0.05 )
            extensionTwoRegisteredExpectation.fulfill()
        }

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self, ContractExtensionTwo.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [extensionOneRegisteredExpectation, extensionTwoRegisteredExpectation, startExpectation], timeout: 0.5, enforceOrder: true)


    }

    /// Tests the registration of extensions running on separate threads
    func testExtensionRegistrationRunningOnSeparateThreads() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        ContractExtensionOne.onInitClosure = {
            Thread.sleep(forTimeInterval:0.2 )
        }
        ContractExtensionOne.registrationClosure = {
            Thread.sleep(forTimeInterval:0.2 )
        }

        ContractExtensionTwo.onInitClosure = {
            Thread.sleep(forTimeInterval:0.2 )
        }
        ContractExtensionTwo.registrationClosure = {
            Thread.sleep(forTimeInterval:0.2 )
        }

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self, ContractExtensionTwo.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation], timeout: 0.5, enforceOrder: true)


    }

    /// Tests the shared state event of eventhub dispatched after start
    func testFirstEventBeSharedStateEventOfEventHub() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let sharedStateEventExpectation = XCTestExpectation(description: "Event Hub shared stated event is received")
        ContractExtensionOne.eventReceivedClosure = { event in
            switch event.name{
            case "Shared state change":
                sharedStateEventExpectation.fulfill()
            default:
                XCTFail("Failed with event: " + event.name)
            }
        }

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation, sharedStateEventExpectation], timeout: 0.5, enforceOrder: true)
    }


    // MARK: - Event order

    /// Tests the events dispatched before start callback will be received by extension after start
    func testEventsDispatchedBeforeStart() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let firstEventExpectation = XCTestExpectation(description: "First event is received")
        let secondEventExpectation = XCTestExpectation(description: "Second event is received")
        let sharedStateEventExpectation = XCTestExpectation(description: "Event Hub shared stated event is received")
        ContractExtensionOne.eventReceivedClosure = { event in
            switch event.name{
            case "first":
                firstEventExpectation.fulfill()
            case "second":
                secondEventExpectation.fulfill()
            case "Shared state change":
                sharedStateEventExpectation.fulfill()
            default:
                XCTFail("Failed with event: " + event.name)
            }
        }

        // test
        MobileCore.dispatch(event: Event(name: "first", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "second", type: "test", source: "test", data: nil))
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation, firstEventExpectation, secondEventExpectation, sharedStateEventExpectation], timeout: 1)
    }

    // MARK: - Extension dispatch queue

    /// Tests the lilsterns from different extension are running on separate threads
    func testListenersFromDifferetnExtensiosnRunOnDifferentThread() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let eventsExpectation = XCTestExpectation(description: "Both two extensions finish processing")
        eventsExpectation.expectedFulfillmentCount = 2
        ContractExtensionOne.eventReceivedClosure = { event in
            Thread.sleep(forTimeInterval:0.2 )
            eventsExpectation.fulfill()
        }

        ContractExtensionTwo.eventReceivedClosure = { event in
            Thread.sleep(forTimeInterval:0.2 )
            eventsExpectation.fulfill()
        }

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self, ContractExtensionTwo.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation], timeout: 1)
        // verify that it takes less than 0.3 second
        wait(for: [eventsExpectation], timeout: 0.3)
    }

    /// Tests the lilsterns from the same extension are running on the same threads
    func testListenersFromOneExtensiosnRunOnSameThread() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let eventsExpectation = XCTestExpectation(description: "Receive all the 3 events")
        eventsExpectation.expectedFulfillmentCount = 3
        ContractExtensionOne.eventReceivedClosure = { event in
            if(event.type == "test"){
                Thread.sleep(forTimeInterval:0.2 )
                eventsExpectation.fulfill()
            }
        }

        // test
        MobileCore.dispatch(event: Event(name: "first", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "second", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "three", type: "test", source: "test", data: nil))
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation], timeout: 1)
        let startTime = Date()
        wait(for: [eventsExpectation], timeout: 1)
        let interval =  Date().timeIntervalSince(startTime)
        // verify that it takes 0.6 second to process three events
        XCTAssertTrue(interval > 0.6)
    }

    // MARK: - Shared State

    /// Tests nil is returned when getting a shared state for an extension which is not registered.
    func testSharedStateOfUnknownExtension() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation], timeout: 1)
        let sharedState = ContractExtensionOne.runtime?.getSharedState(extensionName: "unknownExtension", event: nil, barrier: true)
        XCTAssertNil(sharedState)
    }

    /// Tests nil is returned when getting a shared state for an extension which is not registered.
    func testSharedStateOfExtensionWithNoSharedState() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation], timeout: 1)
        let sharedState = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: nil, barrier: true)
        XCTAssertEqual(SharedStateStatus.none, sharedState?.status)
    }

    /// Tests extension can set the shared state for EN2 after setting shared state for EN1.
    func testSetSharedStateInOrder() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"first"], event: event1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"second"], event: event2)

        // verify
        let sharedStateForEvent1 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent1?.value as? [String:String])

        let sharedStateForEvent2 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true)
        XCTAssertEqual(["event":"second"], sharedStateForEvent2?.value as? [String:String])
    }

    /// Tests once an extension has set the shared state for EN2, it will not be allowed to set the shared state for EN1.
    func testSetSharedStateInWrongOrder() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"second"], event: event2)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"first"], event: event1)

        // verify
        let sharedStateForEvent1 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true)
        // shared state retrieved for event1 is the shared stated set for event2
        XCTAssertEqual(["event":"second"], sharedStateForEvent1?.value as? [String:String])

        let sharedStateForEvent2 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true)
        XCTAssertEqual(["event":"second"], sharedStateForEvent2?.value as? [String:String])
    }

    /// Tests if the last shared state ExtensionA has been set is for EN1 with ShareStateEN1 (no matter .set or .pending), ShareStateEN1 is returned when getting shared state of ExtensionA for EN1, or EN2 or any events after.
    func testGetSharedStateWhenSharedStateIsSetForAEarlierEvent() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        let event3 = Event(name: "three", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        MobileCore.dispatch(event: event3)

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"first"], event: event1)

        // verify
        let sharedStateForEvent1 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent1?.value as? [String:String])

        let sharedStateForEvent2 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent2?.value as? [String:String])

        let sharedStateForEvent3 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event3, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent3?.value as? [String:String])

    }

    /// Tests if ExtensionA has set shared state for EN1 with ShareStateEN1 and for EN4 with ShareStateEN4, ShareStateEN1 is returned when getting shared state of ExtensionA for EN1, EN2 and EN3.
    func testGetSharedStateWhenAnotherSharedStateSetForALaterEvent() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        let event3 = Event(name: "three", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        MobileCore.dispatch(event: event3)

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"first"], event: event1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"three"], event: event3)

        // verify
        let sharedStateForEvent1 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent1?.value as? [String:String])

        let sharedStateForEvent2 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent2?.value as? [String:String])

        let sharedStateForEvent3 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event3, barrier: true)
        XCTAssertEqual(["event":"three"], sharedStateForEvent3?.value as? [String:String])
    }

    func testSharedStateWithResolutionGetsLatestValid() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        let event3 = Event(name: "three", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        MobileCore.dispatch(event: event3)

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"first"], event: event1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"two"], event: event2)
        let resolver = ContractExtensionOne.runtime?.createPendingSharedState(event: event3)

        // verify
        let sharedStateForEvent1 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true, resolution: .lastSet)
        XCTAssertEqual(["event":"first"], sharedStateForEvent1?.value as? [String:String])
        XCTAssertEqual(SharedStateStatus.set, sharedStateForEvent1?.status)

        let sharedStateForEvent2 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true, resolution: .lastSet)
        XCTAssertEqual(["event":"two"], sharedStateForEvent2?.value as? [String:String])
        XCTAssertEqual(SharedStateStatus.set, sharedStateForEvent2?.status)

        let sharedStateForEvent3 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event3, barrier: true, resolution: .lastSet)
        XCTAssertEqual(["event":"two"], sharedStateForEvent3?.value as? [String:String])
        XCTAssertEqual(SharedStateStatus.set, sharedStateForEvent3?.status)

        resolver?(["event": "three"])

        let sharedStateForEvent3New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event3, barrier: true, resolution: .lastSet)
        XCTAssertEqual(["event":"three"], sharedStateForEvent3New?.value as? [String:String])
        XCTAssertEqual(SharedStateStatus.set, sharedStateForEvent3?.status)
    }

    func testResolvingSharedStateWithResolutionGetsLatestValid() {
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        let resolver = ContractExtensionOne.runtime?.createPendingSharedState(event: event1)

        let sharedStateForEvent1 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true, resolution: .lastSet)
        XCTAssertEqual(SharedStateStatus.none, sharedStateForEvent1?.status)

        let sharedStateForEvent2 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true, resolution: .lastSet)
        XCTAssertEqual(SharedStateStatus.none, sharedStateForEvent2?.status)

        resolver?(["event": "first"])

        let sharedStateForEvent1New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true, resolution: .lastSet)
        XCTAssertEqual(["event":"first"], sharedStateForEvent1New?.value as? [String:String])
        XCTAssertEqual(SharedStateStatus.set, sharedStateForEvent1New?.status)

        let sharedStateForEvent2New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true, resolution: .lastSet)
        XCTAssertEqual(["event":"first"], sharedStateForEvent2New?.value as? [String:String])
        XCTAssertEqual(SharedStateStatus.set, sharedStateForEvent2New?.status)
    }

    /// Tests createPendingSharedState and then resolve it
    func testResolvePendingSharedState() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        let event3 = Event(name: "three", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        MobileCore.dispatch(event: event3)

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        let resolver = ContractExtensionOne.runtime?.createPendingSharedState(event: event1)

        // verify
        let sharedStateForEvent1 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true)
        XCTAssertEqual(SharedStateStatus.pending, sharedStateForEvent1?.status)

        let sharedStateForEvent2 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true)
        XCTAssertEqual(SharedStateStatus.pending, sharedStateForEvent2?.status)

        let sharedStateForEvent3 = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event3, barrier: true)
        XCTAssertEqual(SharedStateStatus.pending, sharedStateForEvent3?.status)

        // test
        resolver?(["event":"first"])

        // verify
        let sharedStateForEvent1New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent1New?.value as? [String:String])

        let sharedStateForEvent2New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent2New?.value as? [String:String])

        let sharedStateForEvent3New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event3, barrier: true)
        XCTAssertEqual(["event":"first"], sharedStateForEvent3New?.value as? [String:String])

    }

    /// Tests if the first shared state set by ExtensionA is for EN1 with ShareStateEN1, ShareStateEN1 is returned when getting shared state of ExtensionA for E1, E2 E3 and any event triggered before EN1.
    func testGetSharedStateIfOnlySetSharedStateForEventThree() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let event1 = Event(name: "first", type: "test", source: "test", data: nil)
        let event2 = Event(name: "second", type: "test", source: "test", data: nil)
        let event3 = Event(name: "three", type: "test", source: "test", data: nil)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event2)
        MobileCore.dispatch(event: event3)

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1)
        ContractExtensionOne.runtime?.createSharedState(data: ["event":"three"], event: event3)

        // verify
        let sharedStateForEvent1New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event1, barrier: true)
        XCTAssertEqual(["event":"three"], sharedStateForEvent1New?.value as? [String:String])

        let sharedStateForEvent2New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event2, barrier: true)
        XCTAssertEqual(["event":"three"], sharedStateForEvent2New?.value as? [String:String])

        let sharedStateForEvent3New = ContractExtensionOne.runtime?.getSharedState(extensionName: "com.adobe.ContractExtensionOne", event: event3, barrier: true)
        XCTAssertEqual(["event":"three"], sharedStateForEvent3New?.value as? [String:String])

    }

    // MARK: - stop and start
    /// Tests when the stopEvents API is called, the extension will pause handling events
    func testStopEvents() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let firstEventExpectation = XCTestExpectation(description: "First event is received")
        let secondEventInvertedExpectation = XCTestExpectation(description: "Second event should not be received")
        secondEventInvertedExpectation.isInverted = true
        let thirdEventInvertedExpectation = XCTestExpectation(description: "Third event should not be received")
        thirdEventInvertedExpectation.isInverted = true
        ContractExtensionOne.eventReceivedClosure = { event in
            switch event.name{
            case "first":
                firstEventExpectation.fulfill()
                ContractExtensionOne.runtime?.stopEvents()
            case "second":
                secondEventInvertedExpectation.fulfill()
            case "three":
                thirdEventInvertedExpectation.fulfill()
            default:
                return
            }
        }

        // test
        MobileCore.dispatch(event: Event(name: "first", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "second", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "three", type: "test", source: "test", data: nil))
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation, firstEventExpectation, secondEventInvertedExpectation,thirdEventInvertedExpectation], timeout: 1)
    }

    /// Tests start events resume the event processing
    func testStartEvents() {
        // setup
        let startExpectation = XCTestExpectation(description: "Start callback is invoked")
        let firstEventExpectation = XCTestExpectation(description: "First event is received")
        let secondEventExpectation = XCTestExpectation(description: "Second event is received")
        let thirdEventExpectation = XCTestExpectation(description: "Third event is received")
        ContractExtensionOne.eventReceivedClosure = { event in
            switch event.name{
            case "first":
                firstEventExpectation.fulfill()
                ContractExtensionOne.runtime?.stopEvents()
            case "second":
                secondEventExpectation.fulfill()
            case "three":
                thirdEventExpectation.fulfill()
            default:
                return
            }
        }

        // test
        MobileCore.dispatch(event: Event(name: "first", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "second", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "three", type: "test", source: "test", data: nil))
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation, firstEventExpectation], timeout: 1)

        ContractExtensionOne.runtime?.startEvents()
        wait(for: [secondEventExpectation,thirdEventExpectation], timeout: 1)
    }

}
