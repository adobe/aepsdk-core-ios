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

/// Functional tests for the Configuration extension
class LifecycleFunctionalTests: XCTestCase {
    var mockSystemInfoService: MockSystemInfoService!
    
    override func setUp() {
        AEPServiceProvider.shared.namedKeyValueService = MockDataStore()
        setupMockSystemInfoService()
        MockExtension.reset()
        EventHub.reset()
        EventHub.shared.start()
        registerExtension(MockExtension.self)
        registerExtension(AEPConfiguration.self)
        registerExtension(AEPLifecycle.self)
    }
    
    // helpers
    private func registerExtension<T: Extension> (_ type: T.Type) {
        let expectation = XCTestExpectation(description: "Extension should register")
        EventHub.shared.registerExtension(type) { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }
    
    private func setupMockSystemInfoService() {
        mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.runMode = "Application"
        mockSystemInfoService.mobileCarrierName = "Test Carrier"
        mockSystemInfoService.applicationName = "Test app name"
        mockSystemInfoService.applicationBuildNumber = "12345"
        mockSystemInfoService.applicationVersionNumber = "1.1.1"
        mockSystemInfoService.deviceName = "Test device name"
        mockSystemInfoService.operatingSystemName = "Test OS"
        mockSystemInfoService.activeLocaleName = "en-US"
        mockSystemInfoService.displayInformation = (100, 100)
       
        
        AEPServiceProvider.shared.systemInfoService = mockSystemInfoService
    }
    
    private func assertContextData(contextData: [String: Any], launches: Int, additionalContextData: [String: Any]?) {
        XCTAssertEqual(mockSystemInfoService.mobileCarrierName, contextData[LifecycleMetrics.CodingKeys.carrierName.stringValue] as? String)
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.deviceResolution.stringValue])
        XCTAssertEqual(String(launches), contextData[LifecycleMetrics.CodingKeys.launches.stringValue] as? String)
        XCTAssertEqual(mockSystemInfoService.runMode, contextData[LifecycleMetrics.CodingKeys.runMode.stringValue] as? String)
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.installEvent.stringValue])
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.launchEvent.stringValue])
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.monthlyEngagedEvent.stringValue])
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.dailyEngagedEvent.stringValue])
        XCTAssertEqual(mockSystemInfoService.activeLocaleName, contextData[LifecycleMetrics.CodingKeys.locale.stringValue] as? String)
        XCTAssertEqual(mockSystemInfoService.activeLocaleName, contextData[LifecycleMetrics.CodingKeys.locale.stringValue] as? String)
        XCTAssertEqual(mockSystemInfoService.operatingSystemName, contextData[LifecycleMetrics.CodingKeys.operatingSystem.stringValue] as? String)
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.appId.stringValue])
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.hourOfTheDay.stringValue])
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.dayOfTheWeek.stringValue])
        XCTAssertEqual(mockSystemInfoService.deviceName, contextData[LifecycleMetrics.CodingKeys.deviceName.stringValue] as? String)
        XCTAssertNotNil(contextData[LifecycleMetrics.CodingKeys.installDate.stringValue])
        
        // TODO: Verify format for session data and additional context data
    }
    
    // MARK: lifecycleStart(...) tests
    
    /// Tests simple start API call
    func testLifecycleStartSimple() {
        // setup
        let additionalContextData = ["testKey": "testVal"]
        let sharedStateExpectation = XCTestExpectation(description: "Lifecycle start dispatches a lifecycle shared state")
        sharedStateExpectation.expectedFulfillmentCount = 2 // for config shared state and lifecycle shared state
        let lifecycleResponseExpectation = XCTestExpectation(description: "Lifecycle start dispatches a lifecycle response event")
        lifecycleResponseExpectation.assertForOverFulfill = true
        
        EventHub.shared.createSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, data: [:], event: nil)
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .lifecycle, source: .responseContent) { (event) in
            XCTAssertEqual(0, event.data?[LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_START_TIMESTAMP] as? Int)
            XCTAssertEqual(0, event.data?[LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_PAUSE_TIMESTAMP] as? Int)
            XCTAssertEqual(LifecycleConstants.MAX_SESSION_LENGTH_SECONDS, event.data?[LifecycleConstants.EventDataKeys.MAX_SESSION_LENGTH] as? Double)
            XCTAssertNotNil(event.data?[LifecycleConstants.EventDataKeys.SESSION_START_TIMESTAMP])
            XCTAssertEqual(LifecycleConstants.START, event.data?[LifecycleConstants.EventDataKeys.SESSION_EVENT] as? String)
            self.assertContextData(contextData: (event.data?[LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA] as? [String: Any])!, launches: 1, additionalContextData: additionalContextData)
            
            lifecycleResponseExpectation.fulfill()
        }
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.lifecycleStart(additionalContextData: additionalContextData)
        
        // verify
        wait(for: [lifecycleResponseExpectation, sharedStateExpectation], timeout: 2)
    }
    
    /// Tests simple start then pause, then start again, the second start call should be ignored
    func testLifecycleStartPauseStart() {
        // setup
        let additionalContextData = ["testKey": "testVal"]
        let sharedStateExpectation = XCTestExpectation(description: "Lifecycle start dispatches a lifecycle shared state")
        sharedStateExpectation.expectedFulfillmentCount = 2 // for config shared state and lifecycle shared state
        let lifecycleResponseExpectation = XCTestExpectation(description: "Lifecycle start dispatches a lifecycle response event")
        lifecycleResponseExpectation.assertForOverFulfill = true
        EventHub.shared.createSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, data: [:], event: nil)
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .lifecycle, source: .responseContent) { (event) in
            XCTAssertEqual(0, event.data?[LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_START_TIMESTAMP] as? Int)
            XCTAssertEqual(0, event.data?[LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_PAUSE_TIMESTAMP] as? Int)
            XCTAssertEqual(LifecycleConstants.MAX_SESSION_LENGTH_SECONDS, event.data?[LifecycleConstants.EventDataKeys.MAX_SESSION_LENGTH] as? Double)
            XCTAssertNotNil(event.data?[LifecycleConstants.EventDataKeys.SESSION_START_TIMESTAMP])
            XCTAssertEqual(LifecycleConstants.START, event.data?[LifecycleConstants.EventDataKeys.SESSION_EVENT] as? String)
            self.assertContextData(contextData: (event.data?[LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA] as? [String: Any])!, launches: 1, additionalContextData: additionalContextData)
            
            lifecycleResponseExpectation.fulfill()
        }
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.lifecycleStart(additionalContextData: additionalContextData)
        AEPCore.lifecyclePause()
        AEPCore.lifecycleStart(additionalContextData: additionalContextData)
        
        // verify
        wait(for: [lifecycleResponseExpectation, sharedStateExpectation], timeout: 2)
    }
    
    /// Tests simple start then pause, then start again, the second start call should NOT be ignored
    func testLifecycleStartPauseStartOverTimeout() {
        // setup
        let additionalContextData = ["testKey": "testVal"]
        let sharedStateExpectation = XCTestExpectation(description: "Lifecycle start dispatches a lifecycle shared state")
        sharedStateExpectation.expectedFulfillmentCount = 2 // for config shared state and lifecycle shared state
        let lifecycleResponseExpectation = XCTestExpectation(description: "Lifecycle start dispatches two lifecycle response events")
        lifecycleResponseExpectation.expectedFulfillmentCount = 2
        EventHub.shared.createSharedState(extensionName: ConfigurationConstants.EXTENSION_NAME, data: [LifecycleConstants.EventDataKeys.CONFIG_SESSION_TIMEOUT: 1], event: nil)
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .lifecycle, source: .responseContent) { (event) in
            XCTAssertEqual(LifecycleConstants.MAX_SESSION_LENGTH_SECONDS, event.data?[LifecycleConstants.EventDataKeys.MAX_SESSION_LENGTH] as? Double)
            XCTAssertNotNil(event.data?[LifecycleConstants.EventDataKeys.SESSION_START_TIMESTAMP])
            XCTAssertEqual(LifecycleConstants.START, event.data?[LifecycleConstants.EventDataKeys.SESSION_EVENT] as? String)
            let expectedLaunchCount = event.data?[LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_PAUSE_TIMESTAMP] as? Int == 0 ? 1 : 2
            self.assertContextData(contextData: (event.data?[LifecycleConstants.EventDataKeys.LIFECYCLE_CONTEXT_DATA] as? [String: Any])!, launches: expectedLaunchCount, additionalContextData: additionalContextData)
            
            lifecycleResponseExpectation.fulfill()
        }
        
        EventHub.shared.registerListener(parentExtension: MockExtension.self, type: .hub, source: .sharedState) { (event) in
            sharedStateExpectation.fulfill()
        }
        
        // test
        AEPCore.lifecycleStart(additionalContextData: additionalContextData)
        AEPCore.lifecyclePause()
        sleep(2) // allow session timeout to expire
        AEPCore.lifecycleStart(additionalContextData: additionalContextData)
        
        // verify
        wait(for: [lifecycleResponseExpectation, sharedStateExpectation], timeout: 2)
    }

}
