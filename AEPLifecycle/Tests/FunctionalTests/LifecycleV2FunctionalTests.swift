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
import AEPTestUtils
@testable import AEPLifecycle
import AEPServices
@testable import AEPServicesMocks
import XCTest

/// Functional tests for the Lifecycle extension
class LifecycleV2FunctionalTests: XCTestCase {

    static let PAUSE_UPDATE_TIMEOUT = LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC + 0.20

    var mockSystemInfoService: MockSystemInfoService!
    var mockRuntime: TestableExtensionRuntime!
    var lifecycle: Lifecycle!
    var dataStore: NamedCollectionDataStore!

    private let expectedEnvironmentInfo = [
        "carrier": "test-carrier",
        "operatingSystemVersion": "test-os-version",
        "operatingSystem": "test-os-name",
        "type": "application",
        "_dc": ["language": "es-US"]
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
        NamedCollectionDataStore.clear()
    }

    private func waitForProcessing(interval: TimeInterval = 0.5) {
        let expectation = XCTestExpectation()
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + interval - 0.05) {
            expectation.fulfill()
        }
        wait(for:[expectation], timeout: interval)
    }

    private func setupMockSystemInfoService() {
        mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.runMode = "Application"
        mockSystemInfoService.mobileCarrierName = "test-carrier"
        mockSystemInfoService.applicationName = "test-app-name"
        mockSystemInfoService.applicationBuildNumber = "build-number"
        mockSystemInfoService.applicationVersionNumber = "version-number"
        mockSystemInfoService.deviceName = "test-device-name"
        mockSystemInfoService.deviceModelNumber = "test-device-model"
        mockSystemInfoService.operatingSystemName = "test-os-name"
        mockSystemInfoService.operatingSystemVersion = "test-os-version"
        mockSystemInfoService.activeLocaleName = "en-US"
        mockSystemInfoService.systemLocaleName = "es-US"
        mockSystemInfoService.displayInformation = (100, 100)
        mockSystemInfoService.appVersion = "1.0.0"

        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }

    /// Tests device related info
    func testLifecycleV2_appInstall() {
        // setup
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))
        let expectedApplicationInfo = [
            "name": "test-app-name",
            "version": "version-number (build-number)",
            "isInstall": true,
            "isLaunch": true,
            "_dc": ["language": "en-US"]
        ] as [String : Any]

        let expectedFreeFormData = [
            "key1": "value1",
            "key2": "value2"
        ]

        let event = createStartEvent(additionalData: expectedFreeFormData)
        // test
        mockRuntime.simulateComingEvents(event)
        waitForProcessing()

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count) //application launch

        // event data
        let dispatchedLaunchEvent = mockRuntime.dispatchedEvents[0]
        let xdm = dispatchedLaunchEvent.data?["xdm"] as? [String:Any] ?? [:]
        let data = dispatchedLaunchEvent.data?["data"] as? [String:String] ?? [:]

        XCTAssertEqual("Application Launch (Foreground)", dispatchedLaunchEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedLaunchEvent.type)
        XCTAssertEqual(EventSource.applicationLaunch, dispatchedLaunchEvent.source)
        XCTAssertEqual(expectedFreeFormData, data)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["environment"] as? [String : Any] ?? [:]).isEqual(to: expectedEnvironmentInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["device"] as? [String : Any] ?? [:]).isEqual(to: expectedDeviceInfo))
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
        XCTAssertEqual(event.id, dispatchedLaunchEvent.parentID)
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
        let startEvent = createStartEvent()
        mockRuntime.simulateComingEvents(startEvent)
        waitForProcessing(interval: 1.1) // app close after 1 sec
        // application close
        let pauseEvent = createPauseEvent()
        mockRuntime.simulateComingEvents(pauseEvent)
        waitForProcessing(interval: Self.PAUSE_UPDATE_TIMEOUT)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count) //application launch, application close

        // event data
        let dispatchedStartEvent = mockRuntime.dispatchedEvents[0]
        let dispatchedCloseEvent = mockRuntime.dispatchedEvents[1]
        let xdm = dispatchedCloseEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Application Close (Background)", dispatchedCloseEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedCloseEvent.type)
        XCTAssertEqual(EventSource.applicationClose, dispatchedCloseEvent.source)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
        XCTAssertEqual(startEvent.id, dispatchedStartEvent.parentID)
        XCTAssertEqual(pauseEvent.id, dispatchedCloseEvent.parentID)
    }

    func testLifecycleV2_appUpgrade() {
        // setup
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))
        let expectedApplicationInfo = [
            "name": "test-app-name",
            "version": "version-number (next-build-number)",
            "isUpgrade": true,
            "isLaunch": true,
            "_dc": ["language": "en-US"]
        ] as [String : Any]

        // test
        // appplication launch install hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()
        // application close
        mockRuntime.simulateComingEvents(createPauseEvent())
        waitForProcessing(interval: Self.PAUSE_UPDATE_TIMEOUT)

        // Update app version
        mockSystemInfoService.applicationBuildNumber = "next-build-number"
        // application launch upgrade hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()

        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count) //application launch, application close, application launch

        // event data
        let dispatchedUpgradeEvent = mockRuntime.dispatchedEvents[2]
        let xdm = dispatchedUpgradeEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Application Launch (Foreground)", dispatchedUpgradeEvent.name)
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
            "version": "version-number (build-number)",
            "isLaunch": true,
            "_dc": ["language": "en-US"]
        ] as [String : Any]

        // test
        // appplication launch install hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()
        // application close
        mockRuntime.simulateComingEvents(createPauseEvent())
        waitForProcessing(interval: Self.PAUSE_UPDATE_TIMEOUT)

        // application launch upgrade hit
        mockRuntime.simulateComingEvents(createStartEvent())
        waitForProcessing()

        // verify
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count) //application launch, application close, application launch

        // event data
        let dispatchedUpgradeEvent = mockRuntime.dispatchedEvents[2]
        let xdm = dispatchedUpgradeEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Application Launch (Foreground)", dispatchedUpgradeEvent.name)
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
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))

        let mockRuntimeSession2 = TestableExtensionRuntime()
        mockRuntimeSession2.ignoreEvent(type: EventType.lifecycle, source: EventSource.responseContent)
        mockRuntimeSession2.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))

        // test
        // start event, no pause event
        let startEvent = createStartEvent()
        mockRuntime.simulateComingEvents(startEvent)
        waitForProcessing()

        // simulate a new start
        let lifecycleSession2 = Lifecycle(runtime: mockRuntimeSession2)
        lifecycleSession2.onRegistered()
        let startEvent2 = createStartEvent()
        mockRuntimeSession2.simulateComingEvents(startEvent2)
        waitForProcessing()

        // verify
        XCTAssertEqual(2, mockRuntimeSession2.dispatchedEvents.count) //application close (crash), application launch
        let dispatchedCloseCrashEvent = mockRuntimeSession2.dispatchedEvents[0]
        let xdm = dispatchedCloseCrashEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Application Close (Background)", dispatchedCloseCrashEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedCloseCrashEvent.type)
        XCTAssertEqual(EventSource.applicationClose, dispatchedCloseCrashEvent.source)
        XCTAssertEqual(dispatchedCloseCrashEvent.parentID, startEvent2.id)
        XCTAssertNotNil(xdm["timestamp"] as? String)
        XCTAssertTrue(NSDictionary(dictionary: xdm["application"] as? [String : Any] ?? [:]).isEqual(to: expectedApplicationInfo))
    }

    func testLifecycleV2_appCrash_closeTSMissing() throws {
        // setup
        let expectedApplicationInfo = [
            "closeType": "unknown",
            "isClose": true,
            "sessionLength": 0
        ] as [String : Any]
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))

        let mockRuntimeSession2 = TestableExtensionRuntime()
        mockRuntimeSession2.ignoreEvent(type: EventType.lifecycle, source: EventSource.responseContent)
        mockRuntimeSession2.simulateSharedState(for: "com.adobe.module.configuration", data: ([:], .set))

        // test
        // start event, no pause event
        let startEvent = createStartEvent()
        mockRuntime.simulateComingEvents(startEvent)
        waitForProcessing()

        // Remove persisted close date before starting new session
        dataStore.remove(key: LifecycleV2Constants.DataStoreKeys.APP_CLOSE_DATE)
        waitForProcessing()

        // simulate a new start
        let lifecycleSession2 = Lifecycle(runtime: mockRuntimeSession2)
        lifecycleSession2.onRegistered()
        let start2Event = createStartEvent()
        mockRuntimeSession2.simulateComingEvents(start2Event)
        waitForProcessing()

        // verify
        XCTAssertEqual(2, mockRuntimeSession2.dispatchedEvents.count) //application close (crash), application launch
        let dispatchedCloseCrashEvent = mockRuntimeSession2.dispatchedEvents[0]
        let xdm = dispatchedCloseCrashEvent.data?["xdm"] as? [String:Any] ?? [:]
        XCTAssertEqual("Application Close (Background)", dispatchedCloseCrashEvent.name)
        XCTAssertEqual(EventType.lifecycle, dispatchedCloseCrashEvent.type)
        XCTAssertEqual(EventSource.applicationClose, dispatchedCloseCrashEvent.source)

        let closeDate = xdm["timestamp"] as? String ?? ""
        let expectedCloseDate = Date(timeIntervalSince1970: start2Event.timestamp.timeIntervalSince1970 - 1).asISO8601String()
        XCTAssertNotNil(closeDate)
        XCTAssertEqual(expectedCloseDate, closeDate)
        XCTAssertEqual(dispatchedCloseCrashEvent.parentID, start2Event.id)
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

private extension Date {
    func asISO8601String() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.init(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.string(from: self)
    }
}
