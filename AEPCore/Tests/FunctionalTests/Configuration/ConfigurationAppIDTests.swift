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
        UserDefaults.clear()
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
