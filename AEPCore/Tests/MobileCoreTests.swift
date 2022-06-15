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
        MobileCore.setWrapperType(.none) // reset wrapper type before each test
        MobileCore.setLogLevel(.error) // reset log level to error before each test
        EventHub.reset()
        MockExtension.reset()
        MockExtensionTwo.reset()
        MockLegacyExtension.reset()
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
        MobileCore.registerExtensions([MockExtension.self, Configuration.self])

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testRegisterExtensionsLegacy() {
        let expectation = XCTestExpectation(description: "registration completed in timely fashion")
        expectation.assertForOverFulfill = true

        // test
        MobileCore.registerExtensions([MockLegacyExtension.self, NotAnExtension.self]) {
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(MockLegacyExtension.invokedRegisterExtension)
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
        wait(for: [expectation], timeout: 1)
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
        wait(for: [expectation], timeout: 1)
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
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that a registered extension can be unregistered
    func testUnRegisterExtensionsSimple() {
        let expectation = XCTestExpectation(description: "unregistration completed in timely fashion")
        expectation.assertForOverFulfill = true
        MockExtension.unregistrationClosure = { expectation.fulfill() }
        // Need to make sure register extensions has completed and wait on that before unregistering and verifying.
        let semaphore = DispatchSemaphore(value: 0)
        MobileCore.registerExtensions([MockExtension.self]) {
            semaphore.signal()
        }
        semaphore.wait()
        MobileCore.unregisterExtension(MockExtension.self)
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
        wait(for: [expectation], timeout: 1)
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
        wait(for: [expectation], timeout: 1)
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
        wait(for: [expectation], timeout: 1)
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

    func testGetRegisteredExtensions() {
        // setup
        let expectation = XCTestExpectation(description: "extensions are registered")
        expectation.assertForOverFulfill = true

        let expected = """
        {
            "com.adobe.mockExtension" : {
              "version" : "0.0.1",
              "friendlyName" : "mockExtension"
            },
            "com.adobe.module.configuration" : {
              "version" : "3.7.0",
              "friendlyName" : "Configuration"
            },
            "com.adobe.mockExtensionTwo" : {
              "metadata" : {
                "testMetaKey" : "testMetaVal"
              },
              "version" : "0.0.1",
              "friendlyName" : "mockExtensionTwo"
            }
        }
        """
        let expectedDict = jsonStrToDict(jsonStr: expected)

        // test
        MobileCore.registerExtensions([MockExtension.self, MockExtensionTwo.self], {
            EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.hub, source: EventSource.sharedState) { event in
                if event.data?[EventHubConstants.EventDataKeys.Configuration.EVENT_STATE_OWNER] as? String == EventHubConstants.NAME {
                    let registered = MobileCore.getRegisteredExtensions()
                    let registeredDict = self.jsonStrToDict(jsonStr: registered)?["extensions"] as? Dictionary<String, Any>
                    let equal = NSDictionary(dictionary: registeredDict!).isEqual(to: expectedDict!)
                    XCTAssertTrue(equal)
                    expectation.fulfill()

                }
            }
        })

        // verify
        wait(for: [expectation], timeout: 1)
    }

    private func jsonStrToDict(jsonStr: String) -> [String: Any]? {
        if let data = jsonStr.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
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

    /// Tests that the event listener only receive the events it is registered for
    func testRegisterEventListener() {
        // setup
        let expectedEvent1 = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let expectedEvent2 = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let unexpectedEvent = Event(name: "test", type: "wrong", source: "wrong", data: nil)
        let responseExpectation = XCTestExpectation(description: "Should receive the event")
        responseExpectation.expectedFulfillmentCount = 2
        MobileCore.registerExtensions([])

        // test
        MobileCore.registerEventListener(type: EventType.analytics, source: EventSource.requestContent) { event in
            responseExpectation.fulfill()
        }
        // dispatch the events
        MobileCore.dispatch(event: expectedEvent1)
        MobileCore.dispatch(event: unexpectedEvent)
        MobileCore.dispatch(event: expectedEvent2)

        // verify
        wait(for: [responseExpectation], timeout: 3.0)
    }

    /// Tests that the event listeners listening for same events can all receives the events
    func testRegisterEventListenerMultipleLisenersForSameEvents() {
        // setup
        let expectedEvent1 = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let expectedEvent2 = Event(name: "test", type: EventType.analytics, source: EventSource.requestContent, data: nil)
        let unexpectedEvent = Event(name: "test", type: "wrong", source: "wrong", data: nil)
        let responseExpectation1 = XCTestExpectation(description: "Should receive the events")
        responseExpectation1.expectedFulfillmentCount = 2
        let responseExpectation2 = XCTestExpectation(description: "Should receive the events")
        responseExpectation2.expectedFulfillmentCount = 2
        MobileCore.registerExtensions([])

        // test
        MobileCore.registerEventListener(type: EventType.analytics, source: EventSource.requestContent) { event in
            responseExpectation1.fulfill()
        }

        MobileCore.registerEventListener(type: EventType.analytics, source: EventSource.requestContent) { event in
            responseExpectation2.fulfill()
        }
        // dispatch the events
        MobileCore.dispatch(event: expectedEvent1)
        MobileCore.dispatch(event: unexpectedEvent)
        MobileCore.dispatch(event: expectedEvent2)

        // verify
        wait(for: [responseExpectation1,responseExpectation2], timeout: 3.0)
    }

    // MARK: setWrapperType(...) tests

    /// No wrapper tag should be appended when the setWrapperType API is never invoked
    func testSetWrapperTypeNeverCalled() {
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION, MobileCore.extensionVersion)
    }

    // Tests that no wrapper tag is appended when the wrapper type is none
    func testSetWrapperTypeNone() {
        MobileCore.setWrapperType(.none)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION, MobileCore.extensionVersion)
    }

    /// Tests that the React Native wrapper tag is appended
    func testSetWrapperTypeReactNative() {
        MobileCore.setWrapperType(.reactNative)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-R", MobileCore.extensionVersion)
    }

    /// Tests that the Flutter wrapper tag is appended
    func testSetWrapperTypeFlutter() {
        MobileCore.setWrapperType(.flutter)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-F", MobileCore.extensionVersion)
    }

    /// Tests that the Cordova wrapper tag is appended
    func testSetWrapperTypeCordova() {
        MobileCore.setWrapperType(.cordova)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-C", MobileCore.extensionVersion)
    }

    /// Tests that the Unity wrapper tag is appended
    func testSetWrapperTypeUnity() {
        MobileCore.setWrapperType(.unity)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-U", MobileCore.extensionVersion)
    }

    /// Tests that the Xamarin wrapper tag is appended
    func testSetWrapperTypeXamarin() {
        MobileCore.setWrapperType(.xamarin)
        XCTAssertEqual(ConfigurationConstants.EXTENSION_VERSION + "-X", MobileCore.extensionVersion)
    }

    // MARK: setLogLevel(...) tests

    /// Tests that the log level in the Log class is updated to debug
    func testSetLogLevelTrace() {
        MobileCore.setLogLevel(.trace)
        XCTAssertEqual(Log.logFilter, .trace)
    }

    /// Tests that the log level in the Log class is updated to debug
    func testSetLogLevelDebug() {
        MobileCore.setLogLevel(.debug)
        XCTAssertEqual(Log.logFilter, .debug)
    }

    /// Tests that the log level in the Log class is updated to warning
    func testSetLogLevelWarning() {
        MobileCore.setLogLevel(.warning)
        XCTAssertEqual(Log.logFilter, .warning)
    }

    /// Tests that the log level in the Log class is updated to error
    func testSetLogLevelError() {
        MobileCore.setLogLevel(.error)
        XCTAssertEqual(Log.logFilter, .error)
    }

    // MARK: setAppGroup(...) tests

    /// Tests that the app group can be set to nil
    func testSetAppGroupNil() {
        MobileCore.setAppGroup(nil)

        // verify
        let keyValueService = ServiceProvider.shared.namedKeyValueService as? UserDefaultsNamedCollection
        XCTAssertNil(keyValueService?.appGroup)
    }

    /// Tests that the app group can be set
    func testSetAppGroup() {
        // setup
        let appGroup = "test.app.group"

        // test
        MobileCore.setAppGroup(appGroup)

        // verify
        let keyValueService = ServiceProvider.shared.namedKeyValueService as? UserDefaultsNamedCollection
        XCTAssertEqual(appGroup, keyValueService?.appGroup)
    }

    // MARK: collectMessageInfo(...) tests

    /// When message info is empty no event should be dispatched
    func testCollectMessageInfoEmpty() {
        // setup
        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should NOT receive an event")
        eventExpectation.assertForOverFulfill = true
        eventExpectation.isInverted = true

        EventHub.shared.registerExtension(MockExtension.self) { _ in
            registerExpectation.fulfill()
        }

        wait(for: [registerExpectation], timeout: 1.0)

        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericData, source: EventSource.os) { event in
            eventExpectation.fulfill()
        }

        EventHub.shared.start()

        // test
        MobileCore.collectMessageInfo([:])

        // verify
        wait(for: [eventExpectation], timeout: 1.0)
    }

    /// When message info is not empty we should dispatch an event
    func testCollectMessageInfoWithData() {
        // setup
        let messageInfo = ["testKey": "testVal"]

        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should receive the event when dispatched through the event hub")
        eventExpectation.assertForOverFulfill = true

        EventHub.shared.registerExtension(MockExtension.self) { _ in
            registerExpectation.fulfill()
        }

        wait(for: [registerExpectation], timeout: 1.0)

        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericData, source: EventSource.os) { event in
            XCTAssertEqual(event.data as! [String : String], messageInfo)
            eventExpectation.fulfill()
        }

        EventHub.shared.start()

        // test
        MobileCore.collectMessageInfo(messageInfo)

        // verify
        wait(for: [eventExpectation], timeout: 1.0)
    }

    // MARK: collectLaunchInfo(...) tests

    /// When launch info is empty no event should be dispatched
    func testCollectLaunchInfoEmpty() {
        // setup
        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should NOT receive an event")
        eventExpectation.assertForOverFulfill = true
        eventExpectation.isInverted = true

        EventHub.shared.registerExtension(MockExtension.self) { _ in
            registerExpectation.fulfill()
        }

        wait(for: [registerExpectation], timeout: 1.0)

        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericData, source: EventSource.os) { event in
            eventExpectation.fulfill()
        }

        EventHub.shared.start()

        // test
        MobileCore.collectLaunchInfo([:])

        // verify
        wait(for: [eventExpectation], timeout: 1.0)
    }

    /// When message info is not empty we should dispatch an event
    func testCollectLaunchInfoWithData() {
        // setup
        let launchInfo = [
            "key_str":"stringValue",
            "adb_deeplink":"abc://myawesomeapp?some=param&some=other_param",
            "adb_m_id":"awesomePushMessage",
            "adb_m_l_id":"happyBirthdayNotification"
        ] as [String : String]

        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should receive the event when dispatched through the event hub")
        eventExpectation.assertForOverFulfill = true

        EventHub.shared.registerExtension(MockExtension.self) { _ in
            registerExpectation.fulfill()
        }

        wait(for: [registerExpectation], timeout: 1.0)

        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericData, source: EventSource.os) { event in
            XCTAssertEqual(event.data as! [String: String], [
                "key_str":"stringValue",
                "deeplink":"abc://myawesomeapp?some=param&some=other_param",
                "pushmessageid":"awesomePushMessage",
                "notificationid":"happyBirthdayNotification"
            ])
            eventExpectation.fulfill()
        }

        EventHub.shared.start()

        // test
        MobileCore.collectLaunchInfo(launchInfo)

        // verify
        wait(for: [eventExpectation], timeout: 1.0)
    }

    // MARK: collectPii(...) tests

    /// When data is empty no event should be dispatched
    func testCollectPiiDataEmpty() {
        // setup
        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should NOT receive an event")
        eventExpectation.assertForOverFulfill = true
        eventExpectation.isInverted = true

        EventHub.shared.registerExtension(MockExtension.self) { _ in
            registerExpectation.fulfill()
        }

        wait(for: [registerExpectation], timeout: 1.0)

        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericPii, source: EventSource.requestContent) { event in
            eventExpectation.fulfill()
        }

        EventHub.shared.start()

        // test
        MobileCore.collectPii([:])

        // verify
        wait(for: [eventExpectation], timeout: 1.0)
    }

    /// When data is not nil we should dispatch an event
    func testCollectPiiWithData() {
        // setup
        let data = ["testKey": "testVal"]

        let registerExpectation = XCTestExpectation(description: "MockExtension should register successfully")
        registerExpectation.assertForOverFulfill = true
        let eventExpectation = XCTestExpectation(description: "Should receive the event when dispatched through the event hub")
        eventExpectation.assertForOverFulfill = true

        EventHub.shared.registerExtension(MockExtension.self) { _ in
            registerExpectation.fulfill()
        }

        wait(for: [registerExpectation], timeout: 1.0)

        // register listener after registration
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericPii, source: EventSource.requestContent) { event in
            XCTAssertEqual(event.data as! [String : [String: String]], [CoreConstants.Signal.EventDataKeys.CONTEXT_DATA: data])
            eventExpectation.fulfill()
        }

        EventHub.shared.start()

        // test
        MobileCore.collectPii(data)

        // verify
        wait(for: [eventExpectation], timeout: 1.0)
    }
}
