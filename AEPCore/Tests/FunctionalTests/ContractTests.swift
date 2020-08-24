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

class ContractTest: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
        EventHub.reset()
        ContractExtensionOne.reset()
        ContractExtensionTwo.reset()

    }


    // MARK: - EventHub

    /// Tests the init is called before onRegister
    func testInitThenOnRegister() {
        // setup
        let extensionOneInitExpectation = XCTestExpectation()
        let extensionTwoInitExpectation = XCTestExpectation()
        let extensionOneRegisteredExpectation = XCTestExpectation()
        let extensionTwoRegisteredExpectation = XCTestExpectation()
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

    /// Tests the start callback gets called after all the extension finish registriation
    func testStartCallbackCalledAfterRegistrationComplete() {
        // setup
        let extensionOneRegisteredExpectation = XCTestExpectation()
        let extensionTwoRegisteredExpectation = XCTestExpectation()
        let startExpectation = XCTestExpectation()
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

    /// Tests the registration of extensions running on separat threads
    func testExtensionRegistrationRunningOnSeparateThreads() {
        // setup
        let startExpectation = XCTestExpectation()
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
        let startExpectation = XCTestExpectation()
        let sharedStateEventExpectation = XCTestExpectation()
        ContractExtensionOne.eventReceivedClosure = { event in
            switch event.name{
            case "STATE_CHANGE_EVENT":
                sharedStateEventExpectation.fulfill()
            default:
                XCTAssertFalse(true)
            }
        }

        // test
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation, sharedStateEventExpectation], timeout: 0.5, enforceOrder: true)
    }

    /// Tests the events dispatched before start callback will be received by extension after start
    func testEventsDispatchedBeforeStart() {
        // setup
        let startExpectation = XCTestExpectation()
        let firstEventExpectation = XCTestExpectation()
        let secondEventExpectation = XCTestExpectation()
        let sharedStateEventExpectation = XCTestExpectation()
        ContractExtensionOne.eventReceivedClosure = { event in
            switch event.name{
            case "first":
                firstEventExpectation.fulfill()
            case "second":
                secondEventExpectation.fulfill()
            case "STATE_CHANGE_EVENT":
                sharedStateEventExpectation.fulfill()
            default:
                XCTAssertFalse(true)
            }
        }

        // test
        MobileCore.dispatch(event: Event(name: "first", type: "test", source: "test", data: nil))
        MobileCore.dispatch(event: Event(name: "second", type: "test", source: "test", data: nil))
        MobileCore.registerExtensions([ContractExtensionOne.self]) {
            startExpectation.fulfill()
        }

        // verify
        wait(for: [startExpectation, firstEventExpectation, secondEventExpectation, sharedStateEventExpectation], timeout: 0.5)
    }

    /// Tests the lilsterns from different extension are running on separate threads
    func testListenersFromDifferetnExtensiosnRunOnDifferentThread() {
        // setup
        let startExpectation = XCTestExpectation()
        let eventsExpectation = XCTestExpectation()
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
        wait(for: [startExpectation], timeout: 0.5)
        // verify that it takes less than 0.3 second
        wait(for: [eventsExpectation], timeout: 0.3)
    }

    /// Tests the lilsterns from the same extension are running on the same threads
    func testListenersFromOneExtensiosnRunOnSameThread() {
        // setup

        let startExpectation = XCTestExpectation()
        let eventsExpectation = XCTestExpectation()
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
        wait(for: [startExpectation], timeout: 0.5)
        let startTime = Date()
        wait(for: [eventsExpectation], timeout: 1)
        let interval =  Date().timeIntervalSince(startTime)
        // verify that it takes 0.6 second to process three events
        XCTAssertTrue(interval > 0.6)
    }
}
