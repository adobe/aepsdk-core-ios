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

class MobileCoreTests: XCTestCase {
    override func setUp() {
        MobileCore.setWrapperType(type: .none) // reset wrapper type before each test
        MobileCore.setLogLevel(level: .error) // reset log level to error before each test
        EventHub.reset()
        MockExtension.reset()
        MockExtensionTwo.reset()
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { error in
            XCTAssertNil(error)
            semaphore.signal()
        }

        semaphore.wait()
    }

    func testRegisterExtensionsSimple() {
        let expectation = XCTestExpectation(description: "registration completed in timely fashion")
        expectation.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        // test
        MobileCore.registerExtensions([MockExtension.self])

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// Tests that a single extension can be registered
    func testRegisterExtensionSimple() {
        let expectation = XCTestExpectation(description: "registration completed in timely fashion")
        expectation.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        EventHub.shared.start()

        // test
        MobileCore.registerExtension(MockExtension.self)

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testRegisterExtensionsSimpleMultiple() {
        let expectation = XCTestExpectation(description: "registration completed in timely fashion")
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
        let expectation = XCTestExpectation(description: "registration completed in timely fashion when long running extension is in play")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        MockExtension.registrationClosure = { expectation.fulfill() }
        MockExtensionTwo.registrationClosure = { expectation.fulfill() }

        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self, SlowMockExtension.self])

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// Tests that a registered extension can be unregistered
    func testUnRegisterExtensionsSimple() {
        let expectation = XCTestExpectation(description: "unregistration completed in timely fashion")
        expectation.assertForOverFulfill = true
        MockExtension.unregistrationClosure = { expectation.fulfill() }
        MobileCore.registerExtensions([MockExtension.self])

        // test
        MobileCore.unregisterExtension(MockExtension.self)


        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testRegisterExtensionsSimpleEventDispatch() {
        let expectation = XCTestExpectation(description: "expected event seen")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }

        // test
        MobileCore.registerExtensions([MockExtension.self])
        EventHub.shared.dispatch(event: Event(name: "test-event", type: EventType.analytics, source: EventSource.requestContent, data: nil))

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testRegisterExtensionsDispatchEventBeforeRegister() {
        // setup
        let expectation = XCTestExpectation(description: "expected event seen")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }

        // test
        EventHub.shared.dispatch(event: Event(name: "test-event", type: EventType.analytics, source: EventSource.requestContent, data: nil))
        MobileCore.registerExtensions([MockExtension.self])

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testRegisterMultipleExtensionsSimpleEventDispatch() {
        // setup
        let expectation = XCTestExpectation(description: "expected event seen")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }

        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])
        EventHub.shared.dispatch(event: Event(name: "test-event", type: EventType.analytics, source: EventSource.requestContent, data: nil))

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    func testRegisterMultipleExtensionsDispatchEventBeforeRegister() {
        // setup
        let expectation = XCTestExpectation(description: "expected event seen")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        MockExtension.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }
        MockExtensionTwo.eventReceivedClosure = { if $0.name == "test-event" { expectation.fulfill() } }

        // test
        EventHub.shared.dispatch(event: Event(name: "test-event", type: EventType.analytics, source: EventSource.requestContent, data: nil))
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self])

        // verify
        wait(for: [expectation], timeout: 1.0)
    }

    func testRegisterSameExtensionTwice() {
        // setup
        let expectation = XCTestExpectation(description: "extension should not register twice")
        expectation.assertForOverFulfill = true

        MockExtension.registrationClosure = { expectation.fulfill() }

        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtension.self])

        // verify
        wait(for: [expectation], timeout: 0.25)
    }

    func testDispatchEventSimple() {
        // setup
        let expectedEvent = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)

        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should receive the event when dispatched through the event hub")
        eventExpectation.assertForOverFulfill = true

        EventHub.shared.registerExtension(MockExtension.self) { _ in
            registerExpectation.fulfill()
        }

        wait(for: [registerExpectation], timeout: 1.0)

        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: expectedEvent.type, source: expectedEvent.source) { event in
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
        let expectedEvent = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let expectedResponseEvent = expectedEvent.createResponseEvent(name: "test-response", type: EventType.analytics, source: EventSource.responseContent, data: nil)
        let responseExpectation = XCTestExpectation(description: "Should receive the response event in the response callback")
        responseExpectation.assertForOverFulfill = true
        EventHub.shared.start()

        // test
        MobileCore.dispatch(event: expectedEvent) { responseEvent in
            XCTAssertEqual(responseEvent?.id, expectedResponseEvent.id)
            responseExpectation.fulfill()
        }
        // dispatch the response event which should trigger the callback above
        MobileCore.dispatch(event: expectedResponseEvent)

        // verify
        wait(for: [responseExpectation], timeout: 1.0)
    }

    // MARK: setWrapperType(...) tests

    /// No wrapper tag should be appended when the setWrapperType API is never invoked
    func testSetWrapperTypeNeverCalled() {
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION, MobileCore.extensionVersion)
    }

    // Tests that no wrapper tag is appended when the wrapper type is none
    func testSetWrapperTypeNone() {
        MobileCore.setWrapperType(type: .none)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION, MobileCore.extensionVersion)
    }

    /// Tests that the React Native wrapper tag is appended
    func testSetWrapperTypeReactNative() {
        MobileCore.setWrapperType(type: .reactNative)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-R", MobileCore.extensionVersion)
    }

    /// Tests that the Flutter wrapper tag is appended
    func testSetWrapperTypeFlutter() {
        MobileCore.setWrapperType(type: .flutter)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-F", MobileCore.extensionVersion)
    }

    /// Tests that the Cordova wrapper tag is appended
    func testSetWrapperTypeCordova() {
        MobileCore.setWrapperType(type: .cordova)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-C", MobileCore.extensionVersion)
    }

    /// Tests that the Unity wrapper tag is appended
    func testSetWrapperTypeUnity() {
        MobileCore.setWrapperType(type: .unity)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-U", MobileCore.extensionVersion)
    }

    /// Tests that the Xamarin wrapper tag is appended
    func testSetWrapperTypeXamarin() {
        MobileCore.setWrapperType(type: .xamarin)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-X", MobileCore.extensionVersion)
    }

    // MARK: setLogLevel(...) tests

    /// Tests that the log level in the Log class is updated to debug
    func testSetLogLevelTrace() {
        MobileCore.setLogLevel(level: .trace)
        XCTAssertEqual(Log.logFilter, .trace)
    }

    /// Tests that the log level in the Log class is updated to debug
    func testSetLogLevelDebug() {
        MobileCore.setLogLevel(level: .debug)
        XCTAssertEqual(Log.logFilter, .debug)
    }

    /// Tests that the log level in the Log class is updated to warning
    func testSetLogLevelWarning() {
        MobileCore.setLogLevel(level: .warning)
        XCTAssertEqual(Log.logFilter, .warning)
    }

    /// Tests that the log level in the Log class is updated to error
    func testSetLogLevelError() {
        MobileCore.setLogLevel(level: .error)
        XCTAssertEqual(Log.logFilter, .error)
    }

    // MARK: setAppGroup(...) tests

    /// Tests that the app group can be set to nil
    func testSetAppGroupNil() {
        MobileCore.setAppGroup(group: nil)

        // verify
        let keyValueService = ServiceProvider.shared.namedKeyValueService as? UserDefaultsNamedCollection
        XCTAssertNil(keyValueService?.appGroup)
    }

    /// Tests that the app group can be set
    func testSetAppGroup() {
        // setup
        let appGroup = "test.app.group"

        // test
        MobileCore.setAppGroup(group: appGroup)

        // verify
        let keyValueService = ServiceProvider.shared.namedKeyValueService as? UserDefaultsNamedCollection
        XCTAssertEqual(appGroup, keyValueService?.appGroup)
    }
}
