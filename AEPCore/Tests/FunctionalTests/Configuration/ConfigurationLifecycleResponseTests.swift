//
//  ConfigurationLifecycleResponseTests.swift
//  AEPCoreTests
//
//  Created by Christopher Hoffman on 9/17/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

@testable import AEPCore
import XCTest
import AEPCoreMocks
import AEPServices
import AEPServicesMocks
import XCTest

class ConfigurationLifecycleResponseTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var configuration: Configuration!

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    /// Tests that no configuration event is dispatched when a lifecycle response content event and no appId is stored in persistence
    func testHandleLifecycleResponseEmptyAppId() {
        // setup
        let lifecycleEvent = Event(name: "Lifecycle response content", type: EventType.lifecycle, source: EventSource.responseContent, data: nil)

        // test
        mockRuntime.simulateComingEvents(lifecycleEvent)

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    /// Tests that configuration event is dispatched when a lifecycle response content event and an valid appId is stored in persistence
    func testHandleLifecycleResponseValidAppidFromPersistance() {
        // setup
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: "testappid")
        let lifecycleEvent = Event(name: "Lifecycle response content", type: EventType.lifecycle, source: EventSource.responseContent, data: nil)

        // test
        mockRuntime.simulateComingEvents(appIdEvent)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        mockRuntime.simulateComingEvents(lifecycleEvent)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.requestContent, mockRuntime.firstEvent?.source)
        XCTAssertEqual("testappid", mockRuntime.firstEvent?.data?["config.appId"] as? String)
    }

    func testHandleLifecycleResponseValidAppidFromManifest() {
        let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.property = "testappid"
        ServiceProvider.shared.systemInfoService = mockSystemInfoService

        let lifecycleEvent = Event(name: "Lifecycle response content", type: EventType.lifecycle, source: EventSource.responseContent, data: nil)

        // test
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        mockRuntime.simulateComingEvents(lifecycleEvent)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.requestContent, mockRuntime.firstEvent?.source)
        XCTAssertEqual("testappid", mockRuntime.firstEvent?.data?["config.appId"] as? String)

        mockSystemInfoService.property = nil
    }

}
