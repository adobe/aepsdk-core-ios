/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPCoreMocks
@testable import AEPLifecycle
import AEPServices
import AEPServicesMocks
import XCTest

/// Functional tests for the Lifecycle extension
class LifecycleV2FunctionalTests: XCTestCase {
    var mockSystemInfoService: MockSystemInfoService!
    var mockRuntime: TestableExtensionRuntime!
    var lifecycle: Lifecycle!
    var dataStore: NamedCollectionDataStore!

    private let expectedEnvironmentInfo = [
        "carrier": "test-carrier",
        "operatingSystemVersion": "test-os-version",
        "operatingSystem": "test-os-name",
        "type": "application",
        "_dc": ["language": "en-US"]
    ] as [String : Any]

    let expectedDeviceInfo = [
        "manufacturer": "apple",
        "model": "test-device-name",
        "modelNumber": "test-device-model",
        "type": "mobile",
        "screenHeight": 100,
        "screenWidth": 100
    ] as [String : Any]

    var expectedOSValue: String {
        return "\(mockSystemInfoService.getOperatingSystemName()) \(mockSystemInfoService.getOperatingSystemVersion())"
    }

    override func setUp() {
        setupMockSystemInfoService()
        dataStore = NamedCollectionDataStore(name: "com.adobe.module.lifecycle")
        mockRuntime = TestableExtensionRuntime()
        lifecycle = Lifecycle(runtime: mockRuntime)
        lifecycle.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        mockRuntime.ignoreEvent(type: EventType.lifecycle, source: EventSource.responseContent)
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func waitForProcessing(interval: TimeInterval = 0.5) {
        let expectation = XCTestExpectation()
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + interval - 0.1) {
            expectation.fulfill()
        }
        wait(for:[expectation], timeout: interval)
    }

    private func setupMockSystemInfoService() {
        mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.runMode = "Application"
        mockSystemInfoService.mobileCarrierName = "test-carrier"
        mockSystemInfoService.applicationName = "test-app-name"
        mockSystemInfoService.applicationBuildNumber = "12345"
        mockSystemInfoService.applicationVersionNumber = "123"
        mockSystemInfoService.deviceName = "test-device-name"
        mockSystemInfoService.deviceModelNumber = "test-device-model"
        mockSystemInfoService.operatingSystemName = "test-os-name"
        mockSystemInfoService.operatingSystemVersion = "test-os-version"
        mockSystemInfoService.activeLocaleName = "en-US"
        mockSystemInfoService.displayInformation = (100, 100)
        mockSystemInfoService.appVersion = "1.0.0"

        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }

    /// Tests device related info
    func testLifecycleV2_appLaunch() {
        // setup
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))
        let expectedApplicationInfo = [
            "name": "test-app-name",
            "version": "1.0.0 (123)",
            "isInstall": true,
            "isLaunch": true
        ] as [String : Any]

        let expectedFreeFormData = [
            "key1": "value1",
            "key2": "value2"
        ]
        // test
        mockRuntime.simulateComingEvents(createStartEvent(additionalData: expectedFreeFormData))
        waitForProcessing()

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) //application launch and lifecycle start
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)

        // event data
        let dispatchedLaunchEvent = mockRuntime.dispatchedEvents[0]
        let xdm = dispatchedLaunchEvent.data?["xdm"] as? [String:Any] ?? [:]
        let data = dispatchedLaunchEvent.data?["data"] as? [String:String] ?? [:]

        XCTAssertEqual("Lifecycle Application Launch", dispatchedLaunchEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedLaunchEvent.type)
        XCTAssertEqual(EventSource.applicationLaunch, dispatchedLaunchEvent.source)
        XCTAssertEqual(expectedFreeFormData, data)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["environment"] as? [String : Any] ?? [:]).isEqual(to: expectedEnvironmentInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["device"] as? [String : Any] ?? [:]).isEqual(to: expectedDeviceInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
    }

    func testLifecycleV2_appClose() {
        // setup
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))
        let expectedApplicationInfo = [
            "closeType": "close",
            "isClose": true,
            "sessionLength": 1
        ] as [String : Any]

        // test
        // appplication launch install hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()
        sleep(1) // app close after 1 sec
        // application close
        mockRuntime.simulateComingEvents(createPauseEvent())
        waitForProcessing(interval: 2.5)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) //application launch and lifecycle start
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)

        // event data
        let dispatchedCloseEvent = mockRuntime.dispatchedEvents[1]
        let xdm = dispatchedCloseEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Lifecycle Application Close", dispatchedCloseEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedCloseEvent.type)
        XCTAssertEqual(EventSource.applicationClose, dispatchedCloseEvent.source)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
    }

    func testLifecycleV2_appUpgrade() {
        // setup
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))
        let expectedApplicationInfo = [
            "name": "test-app-name",
            "version": "1.0.1 (123)",
            "isUpgrade": true,
            "isLaunch": true
        ] as [String : Any]

        // test
        // appplication launch install hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()
        // application close
        mockRuntime.simulateComingEvents(createPauseEvent())
        waitForProcessing(interval: 2.5)

        // Update app version
        mockSystemInfoService.appVersion = "1.0.1"
        // application launch upgrade hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()

        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count) //application launch and lifecycle start
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)

        // event data
        let dispatchedUpgradeEvent = mockRuntime.dispatchedEvents[2]
        let xdm = dispatchedUpgradeEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Lifecycle Application Launch", dispatchedUpgradeEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedUpgradeEvent.type)
        XCTAssertEqual(EventSource.applicationLaunch, dispatchedUpgradeEvent.source)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["environment"] as? [String : Any] ?? [:]).isEqual(to: expectedEnvironmentInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["device"] as? [String : Any] ?? [:]).isEqual(to: expectedDeviceInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
    }

    func testLifecycleV2_appLaunch_noInstall_noUpgrade() {
        // setup
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))
        let expectedApplicationInfo = [
            "name": "test-app-name",
            "version": "1.0.0 (123)",
            "isLaunch": true
        ] as [String : Any]

        // test
        // appplication launch install hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()
        // application close
        mockRuntime.simulateComingEvents(createPauseEvent())
        waitForProcessing(interval: 2.5)

        // application launch upgrade hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()

        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count) //application launch and lifecycle start
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)

        // event data
        let dispatchedUpgradeEvent = mockRuntime.dispatchedEvents[2]
        let xdm = dispatchedUpgradeEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Lifecycle Application Launch", dispatchedUpgradeEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedUpgradeEvent.type)
        XCTAssertEqual(EventSource.applicationLaunch, dispatchedUpgradeEvent.source)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["environment"] as? [String : Any] ?? [:]).isEqual(to: expectedEnvironmentInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["device"] as? [String : Any] ?? [:]).isEqual(to: expectedDeviceInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
    }

    func testLifecycleV2_appCrash() {
        // setup
        let expectedApplicationInfo = [
            "closeType": "unknown",
            "isClose": true,
            "sessionLength": 2
        ] as [String : Any]
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout": 1], .set))

        let mockRuntimeSession2 = TestableExtensionRuntime()
        mockRuntimeSession2.ignoreEvent(type: EventType.lifecycle, source: EventSource.responseContent)
        mockRuntimeSession2.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout": 1], .set))

        // test
        // start event, no pause event
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()

        // simulate a new start
        let lifecycleSession2 = Lifecycle(runtime: mockRuntimeSession2)
        lifecycleSession2.onRegistered()
        mockRuntimeSession2.simulateComingEvents(createStartEvent())
        waitForProcessing()

        // verify
        XCTAssertEqual(2, mockRuntimeSession2.dispatchedEvents.count)
        let dispatchedCloseCrashEvent = mockRuntimeSession2.dispatchedEvents[0]
        let xdm = dispatchedCloseCrashEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Lifecycle Application Close", dispatchedCloseCrashEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedCloseCrashEvent.type)
        XCTAssertEqual(EventSource.applicationClose, dispatchedCloseCrashEvent.source)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
    }


    private func createStartEvent(additionalData: [String: Any] = [:]) -> Event {
        let data: [String: Any] = ["action": "start",
                                   "additionalcontextdata": additionalData]
        return Event(name: "Lifecycle Start", type: EventType.genericLifecycle, source: EventSource.requestContent, data: data)
    }

    private func createPauseEvent() -> Event {
        let data: [String: Any] = ["action": "pause"]
        return Event(name: "Lifecycle Start", type: EventType.genericLifecycle, source: EventSource.requestContent, data: data)
    }
}
