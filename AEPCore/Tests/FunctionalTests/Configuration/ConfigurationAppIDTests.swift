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

@testable import AEPCore
import XCTest
import AEPCoreMocks
import AEPServices
import AEPServicesMocks
import XCTest

class ConfigurationAppIDTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var configuration: Configuration!

    var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
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

    func testConfigureWithEmptyAppIdRemovesFromPersistence() {
        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .success)
        ServiceProvider.shared.networkService = mockNetworkService
        let validAppId = "valid-app-id"
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: validAppId)

        // test
        mockRuntime.simulateComingEvents(appIdEvent)

        // Should be in storage
        XCTAssertEqual(validAppId, mockDataStore.dict[ConfigurationConstants.DataStoreKeys.PERSISTED_APPID] as? String)

        let appIdEvent2 = ConfigurationAppIDTests.createConfigAppIdEvent(appId: "")

        mockRuntime.simulateComingEvents(appIdEvent2)

        // Should have been removed from storage
        XCTAssertNil(mockDataStore.dict[ConfigurationConstants.DataStoreKeys.PERSISTED_APPID] as Any?)
    }

    func testInternalConfigureWithAppIdIsDroppedIfAppIdDiffersFromPersistedAppId() {
        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .success)
        ServiceProvider.shared.networkService = mockNetworkService
        let validAppId = "valid-app-id"
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: validAppId)

        // test
        mockRuntime.simulateComingEvents(appIdEvent)

        // Should be in storage
        XCTAssertEqual(validAppId, mockDataStore.dict[ConfigurationConstants.DataStoreKeys.PERSISTED_APPID] as? String)

        let appIdEvent2 = ConfigurationAppIDTests.createConfigAppIdEvent(appId: "valid-app-id2", isInternal: true)
        mockRuntime.simulateComingEvents(appIdEvent2)

        // appIdEvent2 should be dropped.
        XCTAssertEqual(validAppId, mockDataStore.dict[ConfigurationConstants.DataStoreKeys.PERSISTED_APPID] as? String)
    }

    func testInternalConfigureWithAppIdIsNotDroppedIfNoPersistedAppIdExists() {
        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .success)
        ServiceProvider.shared.networkService = mockNetworkService
        let validAppId = "valid-app-id"
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: validAppId, isInternal: true)

        // test
        mockRuntime.simulateComingEvents(appIdEvent)

        // Should be in storage
        XCTAssertEqual(validAppId, mockDataStore.dict[ConfigurationConstants.DataStoreKeys.PERSISTED_APPID] as? String)
    }

    // Tests that when we hit the retry queue, we properly send a configuration request event
    func testConfigureWithAppIdNetworkDown() {
        let mocknetworkService = MockConfigurationDownloaderNetworkService(responseType: .error)
        ServiceProvider.shared.networkService = mocknetworkService
        let appId = "app-id"
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: appId)

        mockRuntime.simulateComingEvents(appIdEvent)

        // Sleep for the retryInterval
        sleep(6)
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.requestContent, mockRuntime.firstEvent?.source)

        XCTAssertEqual(2, mockRuntime.firstEvent?.data?.count)
        XCTAssertTrue(mockRuntime.firstEvent?.data?[CoreConstants.Keys.IS_INTERNAL_EVENT] as! Bool)
        XCTAssertEqual(appId, mockRuntime.firstEvent?.data?[CoreConstants.Keys.JSON_APP_ID] as! String)
    }

    func testConfigureWithAppIdFirstOnlineThenOffline() {
        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .success)
        ServiceProvider.shared.networkService = mockNetworkService
        let validAppId = "valid-app-id"
        let invalidAppId = "invalid-app-id"
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: validAppId)
        let invalidAppIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: invalidAppId)
        // test
        mockRuntime.simulateComingEvents(appIdEvent)

        // simulate offline
        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .error)
        mockRuntime.simulateComingEvents(invalidAppIdEvent)

        // Sleep for the retryInterval
        sleep(6)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
        XCTAssertEqual(EventType.configuration, mockRuntime.secondEvent?.type)
        XCTAssertEqual(EventSource.requestContent, mockRuntime.secondEvent?.source)

        XCTAssertEqual(16, mockRuntime.firstEvent?.data?.count)
        XCTAssertEqual(16, mockRuntime.firstSharedState?.count)
        XCTAssertEqual(2, mockRuntime.secondEvent?.data?.count)
        XCTAssertTrue(mockRuntime.secondEvent?.data?[CoreConstants.Keys.IS_INTERNAL_EVENT] as! Bool)
        XCTAssertEqual(invalidAppId, mockRuntime.secondEvent?.data?[CoreConstants.Keys.JSON_APP_ID] as! String)
        XCTAssertEqual(16, mockRuntime.secondSharedState?.count)
    }

    /// Tests that we can re-try network requests, and it will succeed when the network comes back online
    func testConfigureWithAppIdNetworkDownThenComesOnline() {
        // setup
        let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .error)
        ServiceProvider.shared.networkService = mockNetworkService
        let validAppId = "valid-app-id"
        let invalidAppId = "invalid-app-id"
        let appIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: validAppId)
        let invalidAppIdEvent = ConfigurationAppIDTests.createConfigAppIdEvent(appId: invalidAppId)

        // test
        mockRuntime.simulateComingEvents(invalidAppIdEvent)

        // Sleep for retryInterval
        sleep(6)

        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .success) // setup a valid network response
        mockRuntime.simulateComingEvents(appIdEvent)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
        XCTAssertEqual(EventSource.requestContent, mockRuntime.firstEvent?.source)
        XCTAssertEqual(EventType.configuration, mockRuntime.secondEvent?.type)
        XCTAssertEqual(EventSource.responseContent, mockRuntime.secondEvent?.source)

        XCTAssertEqual(2, mockRuntime.firstEvent?.data?.count)
        XCTAssertTrue(mockRuntime.firstEvent?.data?[CoreConstants.Keys.IS_INTERNAL_EVENT] as! Bool)
        XCTAssertEqual(invalidAppId, mockRuntime.firstEvent?.data?[CoreConstants.Keys.JSON_APP_ID] as! String)
        XCTAssertEqual(0, mockRuntime.firstSharedState?.count)
        XCTAssertEqual(16, mockRuntime.secondEvent?.data?.count)
        XCTAssertEqual(16, mockRuntime.secondSharedState?.count)
    }

    static func createConfigAppIdEvent(appId: String, isInternal: Bool = false) -> Event {
        return Event(name: "Configure with AppId", type: EventType.configuration, source: EventSource.requestContent,
                     data: isInternal ? ["config.appId": appId, "config.isinternalevent": isInternal] : ["config.appId": appId])
    }
}
