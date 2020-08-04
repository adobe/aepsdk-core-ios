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
import AEPServices
import AEPServicesMock
import AEPCoreMocks

/// Functional tests for the Lifecycle extension
class ConfigurationFunctionalTests: XCTestCase {
    var mockSystemInfoService: MockSystemInfoService!
    var mockRuntime: TestableExtensionRuntime!
    var configuration: Configuration!

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }
    
    // MARK: update shared state tests
    
    /// Tests the happy path with for updating the config with a dict
    func testUpdateConfigurationWithDict() {
        // setup
        let configUpdate = ["global.privacy": PrivacyStatus.optedOut.rawValue]
        
        // test
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: configUpdate))

        // test
        MobileCore.updateConfigurationWith(configDict: configUpdate)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(dispatchedEvent.type, EventType.configuration)
        XCTAssertEqual(dispatchedEvent.source, EventSource.responseContent)
        XCTAssertEqual("optedout", dispatchedEvent.data?["global.privacy"] as? String)
        
        let sharedState = mockRuntime.createdSharedStates[0]
        XCTAssertEqual("optedout", sharedState?["global.privacy"] as? String)
    }
    
    /// Tests the happy path with updating the config multiple times with a same dict
    func testUpdateConfigurationWithDictTwice() {
        // setup
        let configUpdate = ["global.privacy": "optedin"]

        // test
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: configUpdate))
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: configUpdate))

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
    }
    
    /// Tests the happy path with updating the config multiple times with a new value
    func testUpdateConfigurationWithDictTwiceWithNewValue() {

        // test
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: ["global.privacy": "optedin"]))
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: ["global.privacy": "optedout"]))

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        
        XCTAssertEqual("optedin", mockRuntime.dispatchedEvents[0].data?["global.privacy"] as? String)
        XCTAssertEqual("optedout", mockRuntime.dispatchedEvents[1].data?["global.privacy"] as? String)
        
        XCTAssertEqual("optedin", mockRuntime.createdSharedStates[0]?["global.privacy"] as? String)
        XCTAssertEqual("optedout", mockRuntime.createdSharedStates[1]?["global.privacy"] as? String)
    }
    
    /// Tests the happy path with updating the config multiple times with new keys
    func testUpdateConfigurationWithDictWithNewKeys() {

        // test
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: ["global.privacy": "optedin"]))
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: ["analytics.server": "server"]))

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        
        XCTAssertEqual(1, mockRuntime.dispatchedEvents[0].data?.count)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents[1].data?.count)
        XCTAssertEqual("server", mockRuntime.dispatchedEvents[1].data?["analytics.server"] as? String)
        
        XCTAssertEqual(1, mockRuntime.createdSharedStates[0]?.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates[1]?.count)
        XCTAssertEqual("server", mockRuntime.createdSharedStates[1]?["analytics.server"] as? String)
    }

    /// Tests the case where the update dict is empty, and should not dispatch a configuration response content event
    func testUpdateConfigurationWithEmptyDict() {
        // test
        mockRuntime.simulateComingEvents(createConfigUpdateEvent(configDict: [:]))

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
    }
    
        // MARK: getPrivacyStatus(...) tests
    
        /// Ensures that get response event even when config is empty
        func testGetPrivacyStatusWhenConfigureIsEmpty() {
            // setup
            let event = createGetPrivacyStatusEvent()
            
            // test
            mockRuntime.simulateComingEvents(event)
            
            // verify
            XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
            XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
            XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
            XCTAssertEqual(0, mockRuntime.firstEvent?.data?.count)
            XCTAssertEqual(event.id, mockRuntime.firstEvent?.responseID)
        }
    
        /// Happy path for get privacy status
        func testGetPrivacyStatusSimpleOptIn() {
            // setup
            let configUpdateEvent = createConfigUpdateEvent(configDict:  ["global.privacy": "optedOut"])
            let getPrivacyStatusEvent = createGetPrivacyStatusEvent()
            
            // test
            mockRuntime.simulateComingEvents(configUpdateEvent)
            mockRuntime.resetDispatchedEventAndCreatedSharedStates()
            mockRuntime.simulateComingEvents(getPrivacyStatusEvent)

            // verify
            XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
            XCTAssertEqual(1, mockRuntime.firstEvent?.data?.count)
            XCTAssertEqual("optedOut", mockRuntime.firstEvent?.data?["global.privacy"] as? String)
            XCTAssertEqual(getPrivacyStatusEvent.id, mockRuntime.firstEvent?.responseID)
        }
    

    
        // MARK: Lifecycle response event tests
    
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
    func testHandleLifecycleResponseValidAppid() {
        // setup
        let appIdEvent = createConfigAppIdEvent(appId: "testappid")
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
    
    
        // MARK: configureWith(filePath) tests
    
        /// Tests the happy path when passing in a valid path to a bundled config
        func testLoadBundledConfig() {
            // setup
            let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!
            let filePathEvent = createConfigFilePathEvent(filePath: path)
    
            // test
            mockRuntime.simulateComingEvents(filePathEvent)
    
            // verify
            XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
            XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
            XCTAssertEqual(EventType.configuration, mockRuntime.firstEvent?.type)
            XCTAssertEqual(EventSource.responseContent, mockRuntime.firstEvent?.source)
            
            XCTAssertEqual(16, mockRuntime.firstEvent?.data?.count)
            XCTAssertEqual(16, mockRuntime.firstSharedState?.count)
        }
    
        /// Tests the API call where the path to the config is invalid
        func testLoadInvalidPathBundledConfig() {
            // setup
            let filePathEvent = createConfigFilePathEvent(filePath: "Invalid/Path/ADBMobileConfig.json")
    
            // test
            mockRuntime.simulateComingEvents(filePathEvent)
    
            // verify
            XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
            XCTAssertEqual( 1, mockRuntime.createdSharedStates.count, "Configuration still should update shared state")
            
            XCTAssertEqual(0, mockRuntime.firstSharedState?.count)
        }
    
        /// Test that programmatic config is applied over the (failed) loaded json
        func testLoadInvalidBundledConfigWithProgrammaticApplied() {
            // setup
            let filePathEvent = createConfigFilePathEvent(filePath: "Invalid/Path/ADBMobileConfig.json")
            let configUpdateEvent = createConfigUpdateEvent(configDict:  ["global.privacy": "optedOut"])

            // test
            mockRuntime.simulateComingEvents(filePathEvent, configUpdateEvent)
            
            // verify
                    XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
                    XCTAssertEqual( 2, mockRuntime.createdSharedStates.count)
            
            XCTAssertEqual(1, mockRuntime.firstEvent?.data?.count)
            
            XCTAssertEqual(0, mockRuntime.firstSharedState?.count)
            XCTAssertEqual(1, mockRuntime.secondSharedState?.count)
           
        }
    
        // MARK: configureWith(appId) tests
    
        /// When network service returns a valid response configure with appId succeeds
        func testConfigureWithAppId() {
            // setup
            let mockNetworkService = MockConfigurationDownloaderNetworkService(responseType: .success)
            ServiceProvider.shared.networkService = mockNetworkService
            let appIdEvent = createConfigAppIdEvent(appId:  "valid-app-id")

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
            
            let appIdEvent = createConfigAppIdEvent(appId:  "valid-app-id")
            let invalidAppIdEvent = createConfigAppIdEvent(appId:  "invalid-app-id")
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
    
    
    func createConfigAppIdEvent(appId: String) -> Event{
        return Event(name: "Configure with AppId", type: EventType.configuration, source: EventSource.requestContent,
                          data: ["config.appId": appId])
    }
    
    func createConfigFilePathEvent(filePath: String) -> Event{
        return Event(name: "Configure with file path", type: EventType.configuration, source: EventSource.requestContent,
                          data: ["config.filePath": filePath])
    }
    
    func createConfigUpdateEvent(configDict: [String: Any]) -> Event{
        return Event(name: "Configure with file path", type: EventType.configuration, source: EventSource.requestContent,
                          data: ["config.update": configDict])
    }
    
    func createGetPrivacyStatusEvent() -> Event{
        return Event(name: "Privacy Status Request", type: EventType.configuration, source: EventSource.requestContent, data: ["config.getData": true])
        
    }

}
