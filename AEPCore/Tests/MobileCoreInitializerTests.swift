/*
 Copyright 2025 Adobe. All rights reserved.
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
@testable import AEPServices

class MobileCoreInitializerTests: XCTestCase {
    override func setUp() {
        NamedCollectionDataStore.clear()
        MobileCore.resetSDK()
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

    func testInitializeRegistersExtensionsAutomatically() {
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        // Set ExtensionFinder func to return just two extensions
        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return [
                MockExtension.self,
                MockExtensionTwo.self
            ]
        })

        // test
        MobileCore.initialize(options: InitOptions()) {
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)

        let eventHubState = EventHub.shared.getSharedState(extensionName: EventHubConstants.NAME, event: nil)?.value

        guard let registeredExtensions = eventHubState?["extensions"] as? [String: Any] else {
            XCTFail("Found no registered extensions!")
            return
        }

        let expectedExtensions = [
            "com.adobe.module.configuration",
            "com.adobe.mockExtension",
            "com.adobe.mockExtensionTwo"
        ]

        XCTAssertEqual(registeredExtensions.count, expectedExtensions.count)

        for e in expectedExtensions {
            XCTAssertTrue(registeredExtensions.keys.contains { $0 == e })
        }
    }

    func testInitializeIgnoredSecondTime() {
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        var finderExecutionCount = 0
        // Set ExtensionFinder func to return MockExtension for first call and MockExtensionTwo for second call
        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            finderExecutionCount += 1
            if finderExecutionCount == 1 {
                return [MockExtension.self]
            } else {
                return [MockExtensionTwo.self]
            }
        })

        let options = InitOptions()        

        // First call
        MobileCore.initialize(options: options) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)

        // Second call, callback is not called
        MobileCore.initialize(options: options) {
            XCTFail("Completion closure should not be called from subsequent calls to initialize().")
        }

        sleep(1) // wait as callback to second initialize call is not called

        let eventHubState = EventHub.shared.getSharedState(extensionName: EventHubConstants.NAME, event: nil)?.value

        guard let registeredExtensions = eventHubState?["extensions"] as? [String: Any] else {
            XCTFail("Found no registered extensions!")
            return
        }

        // Expect only extensions from first call to be registered
        XCTAssertEqual(registeredExtensions.count, 2)
        XCTAssertTrue(registeredExtensions.keys.contains { $0 == "com.adobe.module.configuration" })
        XCTAssertTrue(registeredExtensions.keys.contains { $0 == "com.adobe.mockExtension" })
        XCTAssertFalse(registeredExtensions.keys.contains { $0 == "com.adobe.mockExtensionTwo" })
    }

    func testInitializeCallsConfigWithAppId() {
        let expectation = XCTestExpectation(description: "Configure with app id dispatches a configuration request content with the app id")
        expectation.assertForOverFulfill = true
        let expectedAppId = "test-app-id"

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let appid = event.data![ConfigurationConstants.Keys.JSON_APP_ID] as? String {
                XCTAssertEqual(expectedAppId, appid)
                expectation.fulfill()
            }
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return [
                MockExtensionTwo.self,
            ]
        })

        // test
        MobileCore.initialize(appId: expectedAppId)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testInitializeCallsConfigWithAppIdUsingOptions() {
        let expectation = XCTestExpectation(description: "Configure with app id dispatches a configuration request content with the app id")
        expectation.assertForOverFulfill = true
        let expectedAppId = "test-app-id"

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let appid = event.data![ConfigurationConstants.Keys.JSON_APP_ID] as? String {
                XCTAssertEqual(expectedAppId, appid)
                expectation.fulfill()
            }
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return [
                MockExtensionTwo.self,
            ]
        })

        // test
        MobileCore.initialize(options: InitOptions(appId: expectedAppId))

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testInitializeCallsConfigWithFileInPath() {
        // setup
        let expectation = XCTestExpectation(description: "Configure with file path dispatches a configuration request content with the file path")
        expectation.assertForOverFulfill = true
        let expectedFilePath = "test-file-path"

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            if let _ = event.data, let path = event.data![ConfigurationConstants.Keys.JSON_FILE_PATH] as? String {
                XCTAssertEqual(expectedFilePath, path)
                expectation.fulfill()
            }
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return [
                MockExtensionTwo.self,
            ]
        })

        // test
        MobileCore.initialize(options: InitOptions(filePath: expectedFilePath))

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testInitializeNoConfigOptionSet() {        
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { _ in
            XCTFail("Event of type Configuration and source Request Content not expected.")
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return [
                MockExtensionTwo.self,
            ]
        })

        // test
        MobileCore.initialize(options: InitOptions()) {
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)        
    }

    func testInitializeSetsAppGroup() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        let expectedAppGroup = "testAppGroup"

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return [
                MockExtension.self,
            ]
        })

        let initOptions = InitOptions()
        initOptions.appGroup = expectedAppGroup

        // test
        MobileCore.initialize(options: initOptions) {
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(expectedAppGroup, ServiceProvider.shared.namedKeyValueService.getAppGroup())
    }

    @available(iOS 13.0, tvOS 13.0, *) // test requires UIWindowSceneDelegate
    func testInitializeEnablesAutomaticLifecycleTrackingForSceneDelegate() {
        // setup
        let expectation = XCTestExpectation(description: "lifecycle events received")
        expectation.expectedFulfillmentCount = 3 // 1 initial start + 1 foreground start + 1 background pause
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)

        var capturedEvents: [Event] = []
        var capturedNotificationHandlers: [NSNotification.Name: (Notification) -> Void] = [:]

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            capturedEvents.append(event)
            expectation.fulfill()
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return []
        }, bundleInfoProvider: { $0 == "UIApplicationSceneManifest" ? [:] : nil },
        notificationObserver: { name, object, queue, handler in
            // Capture handlers for both foreground and background notifications
            if let notificationName = name {
                capturedNotificationHandlers[notificationName] = handler
            }
            return NSObject()
        })

        // After extension registration, for a SceneDelegate app, lifecycleStart is called immediately.
        MobileCore.initialize(options: InitOptions())

        Thread.sleep(forTimeInterval: 0.5)

        // Verify only the expected notifications are registered
        let expectedNotifications: Set<NSNotification.Name> = [
            UIScene.willEnterForegroundNotification,
            UIScene.didEnterBackgroundNotification
        ]
        let actualNotifications = Set(capturedNotificationHandlers.keys)
        XCTAssertEqual(actualNotifications, expectedNotifications, "Only UIScene foreground and background notifications should be registered")

        // Simulate scene foreground notification
        if let foregroundHandler = capturedNotificationHandlers[UIScene.willEnterForegroundNotification] {
            let foregroundNotification = Notification(name: UIScene.willEnterForegroundNotification)
            foregroundHandler(foregroundNotification)
        }

        // Simulate scene background notification
        if let backgroundHandler = capturedNotificationHandlers[UIScene.didEnterBackgroundNotification] {
            let backgroundNotification = Notification(name: UIScene.didEnterBackgroundNotification)
            backgroundHandler(backgroundNotification)
        }

        // verify lifecycle start event dispatched
        wait(for: [expectation], timeout: 2)

        // Check total count = 3
        XCTAssertEqual(capturedEvents.count, 3, "Should have exactly 3 lifecycle events")

        // Filter and check START events = 2
        let startEvents = capturedEvents.filter { event in
            event.data![CoreConstants.Keys.ACTION] as? String == CoreConstants.Lifecycle.START
        }
        XCTAssertEqual(startEvents.count, 2, "Should have exactly 2 START events")

        // Filter and check PAUSE events = 1
        let pauseEvents = capturedEvents.filter { event in
            event.data![CoreConstants.Keys.ACTION] as? String == CoreConstants.Lifecycle.PAUSE
        }
        XCTAssertEqual(pauseEvents.count, 1, "Should have exactly 1 PAUSE event")
    }

    func testInitializeEnablesAutomaticLifecycleTrackingForAppDelegate() {
        // setup
        let expectation = XCTestExpectation(description: "lifecycle events received")
        expectation.expectedFulfillmentCount = 3 // 1 initial start + 1 foreground start + 1 background pause
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)

        var capturedEvents: [Event] = []
        var capturedNotificationHandlers: [NSNotification.Name: (Notification) -> Void] = [:]

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            capturedEvents.append(event)
            expectation.fulfill()
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return []
        }, bundleInfoProvider: { _ in nil },
        notificationObserver: { name, object, queue, handler in
            // Capture handlers for both foreground and background notifications
            if let notificationName = name {
                capturedNotificationHandlers[notificationName] = handler
            }
            return NSObject()
        })

        // After extension registration, for an AppDelegate app, lifecycleStart is called immediately.
        MobileCore.initialize(options: InitOptions())

        Thread.sleep(forTimeInterval: 0.5)

        // Verify only the expected notifications are registered
        let expectedNotifications: Set<NSNotification.Name> = [
            UIApplication.willEnterForegroundNotification,
            UIApplication.didEnterBackgroundNotification
        ]
        let actualNotifications = Set(capturedNotificationHandlers.keys)
        XCTAssertEqual(actualNotifications, expectedNotifications, "Only UIApplication foreground and background notifications should be registered")

        // Simulate application foreground notification
        if let foregroundHandler = capturedNotificationHandlers[UIApplication.willEnterForegroundNotification] {
            let foregroundNotification = Notification(name: UIApplication.willEnterForegroundNotification)
            foregroundHandler(foregroundNotification)
        }

        // Simulate application background notification
        if let backgroundHandler = capturedNotificationHandlers[UIApplication.didEnterBackgroundNotification] {
            let backgroundNotification = Notification(name: UIApplication.didEnterBackgroundNotification)
            backgroundHandler(backgroundNotification)
        }

        // verify lifecycle events dispatched
        wait(for: [expectation], timeout: 2)

        // Check total count = 3
        XCTAssertEqual(capturedEvents.count, 3, "Should have exactly 3 lifecycle events")

        // Filter and check START events = 2
        let startEvents = capturedEvents.filter { event in
            event.data![CoreConstants.Keys.ACTION] as? String == CoreConstants.Lifecycle.START
        }
        XCTAssertEqual(startEvents.count, 2, "Should have exactly 2 START events")

        // Filter and check PAUSE events = 1
        let pauseEvents = capturedEvents.filter { event in
            event.data![CoreConstants.Keys.ACTION] as? String == CoreConstants.Lifecycle.PAUSE
        }
        XCTAssertEqual(pauseEvents.count, 1, "Should have exactly 1 PAUSE event")
    }
    @available(iOS 13.0, tvOS 13.0, *)
    func testInitializeEnablesAutomaticLifecycleTrackingWithContextDataForSceneDelegate() {
        // setup
        let expectation = XCTestExpectation(description: "lifecycle start events received")
        expectation.expectedFulfillmentCount = 2 // 1 initial start + 1 foreground start
        expectation.assertForOverFulfill = true

        let expectedLifecycleAdditionalContextData = ["key" : "value"]

        registerMockExtension(MockExtension.self)

        var capturedStartEvents: [Event] = []
        var capturedNotificationHandlers: [NSNotification.Name: (Notification) -> Void] = [:]

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            capturedStartEvents.append(event)
            expectation.fulfill()            
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return []
        }, bundleInfoProvider: { $0 == "UIApplicationSceneManifest" ? [:] : nil },
        notificationObserver: { name, object, queue, handler in
            // Capture handlers for notifications
            if let notificationName = name {
                capturedNotificationHandlers[notificationName] = handler
            }
            return NSObject()
        })

        let initOptions = InitOptions()
        initOptions.lifecycleAdditionalContextData = expectedLifecycleAdditionalContextData

        // After extension registration, for a SceneDelegate app, lifecycleStart is called immediately.
        MobileCore.initialize(options: initOptions)

        Thread.sleep(forTimeInterval: 0.5)

        // Simulate only foreground notification
        if let foregroundHandler = capturedNotificationHandlers[UIScene.willEnterForegroundNotification] {
            let foregroundNotification = Notification(name: UIScene.willEnterForegroundNotification)
            foregroundHandler(foregroundNotification)
        }

        // verify lifecycle start events dispatched
        wait(for: [expectation], timeout: 2)

        // Check that we captured exactly 2 START events with context data
        XCTAssertEqual(capturedStartEvents.count, 2, "Should have exactly 2 START events with context data")

        // Verify both events have the expected context data
        for event in capturedStartEvents {
            XCTAssertEqual(event.data![CoreConstants.Keys.ACTION] as? String, CoreConstants.Lifecycle.START)
            XCTAssertEqual(event.data![CoreConstants.Keys.ADDITIONAL_CONTEXT_DATA] as? [String: String], expectedLifecycleAdditionalContextData)
        }
    }
    func testInitializeEnablesAutomaticLifecycleTrackingWithContextData() {
        // setup
        let expectation = XCTestExpectation(description: "lifecycle start events received")
        expectation.expectedFulfillmentCount = 2 // 1 initial start + 1 foreground start
        expectation.assertForOverFulfill = true

        let expectedLifecycleAdditionalContextData = ["key" : "value"]

        registerMockExtension(MockExtension.self)

        var capturedStartEvents: [Event] = []
        var capturedNotificationHandlers: [NSNotification.Name: (Notification) -> Void] = [:]

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            capturedStartEvents.append(event)
            expectation.fulfill()            
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: {
            return []
        }, bundleInfoProvider: { _ in nil },
        notificationObserver: { name, object, queue, handler in
            // Capture handlers for notifications
            if let notificationName = name {
                capturedNotificationHandlers[notificationName] = handler
            }
            return NSObject()
        })

        let initOptions = InitOptions()
        initOptions.lifecycleAdditionalContextData = expectedLifecycleAdditionalContextData

        // After extension registration, for an AppDelegate app, lifecycleStart is called immediately.
        MobileCore.initialize(options: initOptions)

        Thread.sleep(forTimeInterval: 0.5)

        // Simulate only foreground notification
        if let foregroundHandler = capturedNotificationHandlers[UIApplication.willEnterForegroundNotification] {
            let foregroundNotification = Notification(name: UIApplication.willEnterForegroundNotification)
            foregroundHandler(foregroundNotification)
        }

        // verify lifecycle start events dispatched
        wait(for: [expectation], timeout: 2)

        // Check that we captured exactly 2 START events with context data
        XCTAssertEqual(capturedStartEvents.count, 2, "Should have exactly 2 START events with context data")

        // Verify both events have the expected context data
        for event in capturedStartEvents {
            XCTAssertEqual(event.data![CoreConstants.Keys.ACTION] as? String, CoreConstants.Lifecycle.START)
            XCTAssertEqual(event.data![CoreConstants.Keys.ADDITIONAL_CONTEXT_DATA] as? [String: String], expectedLifecycleAdditionalContextData)
        }
    }
    func testInitializeDisablesAutomaticLifecycleTracking() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { _ in
            XCTFail("Event with type Generic Lifecycle and source Request Context not expected.")
        }

        MobileCore.mobileCoreInitializer = MobileCoreInitializer(extensionFinder: { return [] } , notificationObserver: { _, _, _, _ in
            XCTFail("Lifecycle notification listeners are not expected.")
            return NSObject()
        } )

        let initOptions = InitOptions()
        initOptions.lifecycleAutomaticTrackingEnabled = false

        // When enabled, lifecycleStart is called immediately after extension registration
        MobileCore.initialize(options: initOptions) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

}
