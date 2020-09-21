//
//  ConfigurationAppIDTests.swift
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

class ConfigurationAppIDTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var configuration: Configuration!
    
    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: configureWith(appId) tests
    
    /// When network service returns a valid response configure with appId succeeds
    func testConfigureWithAppId() {
        // setup
        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .success)
        ServiceProvider.shared.networkService = mockNetworkService
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: "valid-app-id")
        
        // test
        mockRuntime.simulateComingEvents(appIdEvent)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
        
        XCTAssertEqual(16, mockRuntime.firstEvent?.data?.count)
        XCTAssertEqual(16, mockRuntime.firstSharedState?.count)
    }
    
    /// Tests that we can re-try network requests, and it will succeed when the network comes back online
    func testConfigureWithAppIdNetworkDownThenComesOnline() {
        // setup
        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .error)
        ServiceProvider.shared.networkService = mockNetworkService
        
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: "valid-app-id")
        let invalidAppIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: "invalid-app-id")
        // test
        mockRuntime.simulateComingEvents(invalidAppIdEvent)
        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .success) // setup a valid network response
        mockRuntime.simulateComingEvents(appIdEvent)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
        
        XCTAssertEqual(16, mockRuntime.firstEvent?.data?.count)
        XCTAssertEqual(16, mockRuntime.firstSharedState?.count)
    }

    static func createConfigAppIdEvent(appId: String) -> Event {
        return Event(name: "Configure with AppId", type: EventType.configuration, source: EventSource.requestContent,
                     data: ["config.appId": appId])
    }
}
