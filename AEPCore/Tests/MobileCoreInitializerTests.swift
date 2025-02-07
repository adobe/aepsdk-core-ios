//
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

        // Set ClassFinder func to return just two extensions
        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtension.self,
                MockExtensionTwo.self
            ]
        }

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

        // Set ClassFinder func to return MockExtension for first call
        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtension.self,
            ]
        }

        // First call
        MobileCore.initialize(options: InitOptions()) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        // Set ClassFinder func to return MockExtensionTwo for second call
        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtensionTwo.self,
            ]
        }

        // Second call, callback is not called
        MobileCore.initialize(options: InitOptions()) {
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

        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtensionTwo.self,
            ]
        }

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

        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtensionTwo.self,
            ]
        }

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

        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtensionTwo.self,
            ]
        }

        // test
        MobileCore.initialize(options: InitOptions(filePath: expectedFilePath))

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testInitializeNoConfigOptionSet() {
        func testInitializeCallsConfigWithFileInPath() {
            // setup
            let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
            expectation.assertForOverFulfill = true

            registerMockExtension(MockExtension.self)
            EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { _ in
                XCTFail("Event of type Configuration and source Request Content not expected.")
            }

            MobileCoreInitializer.shared.classFinder = { _ in
                return [
                    MockExtensionTwo.self,
                ]
            }

            // test
            MobileCore.initialize(options: InitOptions()) {
                expectation.fulfill()
            }

            // verify
            wait(for: [expectation], timeout: 1)
        }
    }

    func testInitializeSetsAppGroup() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        let expectedAppGroup = "testAppGroup"

        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtension.self,
            ]
        }

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
    func testInitializeEnablesAutomaticLifecycleTrackingForScreenDelegate() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            if let _ = event.data, let action = event.data![CoreConstants.Keys.ACTION] as? String {
                if (action == CoreConstants.Lifecycle.START) {
                    expectation.fulfill()
                }
            }
        }

        // The ClassFinder function is used to check if UIWindowSceneDelegate is available.
        // However, that check just verifies ClassFinder returns a non-zero list so the mocked
        // function below will pass the test.
        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtensionTwo.self
            ]
        }

        // After extension registration, for a SceneDelegate app, lifecycleStart is called immediately.
        MobileCore.initialize(options: InitOptions())

        // verify lifecycle start event dispatched
        wait(for: [expectation], timeout: 2)
    }

    func testInitializeEnablesAutomaticLifecycleTrackingForAppDelegate() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            if let _ = event.data, let action = event.data![CoreConstants.Keys.ACTION] as? String {
                if (action == CoreConstants.Lifecycle.START) {
                    expectation.fulfill()
                }
            }
        }

        // The ClassFinder function is used to check if UIWindowSceneDelegate is available.
        // However, that check just verifies ClassFinder returns a non-zero list.
        // Returing an empty list will trigger the use of UIWindowApplicationDelegate.
        MobileCoreInitializer.shared.classFinder = { _ in
            return []
        }

        // After extension registration, for an AppDelegate app,
        // lifecycleStart is called immediately if the application is not in the background.
        MobileCore.initialize(options: InitOptions())

        // verify lifecycle start event dispatched
        wait(for: [expectation], timeout: 2)
    }

    @available(iOS 13.0, tvOS 13.0, *) // test requires UIWindowSceneDelegate
    func testInitializeEnablesAutomaticLifecycleTrackingWithContextDataForSceneDelegate() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        let expectedLifecycleAdditionalContextData = ["key" : "value"]

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            if let _ = event.data, let action = event.data![CoreConstants.Keys.ACTION] as? String, let additionalData = event.data![CoreConstants.Keys.ADDITIONAL_CONTEXT_DATA] as? [String: String] {
                if (action == CoreConstants.Lifecycle.START) {
                    XCTAssertEqual(additionalData, expectedLifecycleAdditionalContextData)
                    expectation.fulfill()
                }
            }
        }

        // The ClassFinder function is used to check if UIWindowSceneDelegate is available.
        // However, that check just verifies ClassFinder returns a non-zero list so the mocked
        // function below will pass the test.
        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtensionTwo.self
            ]
        }

        let initOptions = InitOptions()
        initOptions.lifecycleAdditionalContextData = expectedLifecycleAdditionalContextData

        // After extension registration, for a SceneDelegate app, lifecycleStart is called immediately.
        MobileCore.initialize(options: initOptions)

        // verify lifecycle start event dispatched
        wait(for: [expectation], timeout: 2)
    }

    func testInitializeEnablesAutomaticLifecycleTrackingWithContextData() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        let expectedLifecycleAdditionalContextData = ["key" : "value"]

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { event in
            if let _ = event.data, let action = event.data![CoreConstants.Keys.ACTION] as? String, let additionalData = event.data![CoreConstants.Keys.ADDITIONAL_CONTEXT_DATA] as? [String: String] {
                if (action == CoreConstants.Lifecycle.START) {
                    XCTAssertEqual(additionalData, expectedLifecycleAdditionalContextData)
                    expectation.fulfill()
                }
            }
        }

        // The ClassFinder function is used to check if UIWindowSceneDelegate is available.
        // However, that check just verifies ClassFinder returns a non-zero list.
        // Returing an empty list will trigger the use of UIWindowApplicationDelegate.
        MobileCoreInitializer.shared.classFinder = { _ in
            return []
        }

        let initOptions = InitOptions()
        initOptions.lifecycleAdditionalContextData = expectedLifecycleAdditionalContextData

        // After extension registration, for an AppDelegate app,
        // lifecycleStart is called immediately if the application is not in the background.
        MobileCore.initialize(options: initOptions)

        // verify lifecycle start event dispatched
        wait(for: [expectation], timeout: 2)
    }

    func testInitializeDisablesAutomaticLifecycleTracking() {
        // setup
        let expectation = XCTestExpectation(description: "initialization completed in timely fashion")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericLifecycle, source: EventSource.requestContent) { _ in
            XCTFail("Event with type Generic Lifecycle and source Request Context not expected.")
        }

        MobileCoreInitializer.shared.classFinder = { _ in
            return [
                MockExtensionTwo.self,
            ]
        }

        let initOptions = InitOptions()
        initOptions.lifecycleAutomaticTracking = false

        // When enabled, lifecycleStart is called immediately after extension registration
        MobileCore.initialize(options: initOptions) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

}
