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
import AEPCore
@testable import AEPLifecycle
import AEPServices
import AEPServicesMock
import AEPCoreMocks

/// Functional tests for the Lifecycle extension
class LifecycleFunctionalTests: XCTestCase {
    var mockSystemInfoService: MockSystemInfoService!
    var mockRuntime: TestableExtensionRuntime!
    var lifecycle: Lifecycle!

    override func setUp() {
        setupMockSystemInfoService()
        mockRuntime = TestableExtensionRuntime()
        lifecycle = Lifecycle(runtime: mockRuntime)
        lifecycle.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        for key in UserDefaults.standard.dictionaryRepresentation().keys{
            UserDefaults.standard.removeObject(forKey: key)
        }
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

        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }
    
    // MARK: lifecycleStart(...) tests

    /// Tests device related info
    func testLifecycleDeviceInfo() {
        // setup
        mockRuntime.simulateSharedState(for:"com.adobe.module.configuration", data: ([:],.set))
        
        // test
        mockRuntime.simulateComingEvents(createStartEvent())
        
        //verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        
        // event data
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(mockSystemInfoService.mobileCarrierName, dispatchedEvent.lifecycleContextData["carriername"] as? String)
        XCTAssertEqual("100x100", dispatchedEvent.lifecycleContextData["resolution"] as? String)
        XCTAssertEqual(mockSystemInfoService.runMode, dispatchedEvent.lifecycleContextData["runmode"] as? String)
        XCTAssertEqual(mockSystemInfoService.activeLocaleName, dispatchedEvent.lifecycleContextData["locale"] as? String)
        XCTAssertEqual(mockSystemInfoService.operatingSystemName, dispatchedEvent.lifecycleContextData["osversion"] as? String)
        XCTAssertEqual("Test app name 1.1.1 (12345)", dispatchedEvent.lifecycleContextData["appid"] as? String)
        XCTAssertEqual(mockSystemInfoService.deviceName, dispatchedEvent.lifecycleContextData["devicename"] as? String)
        
        // shared state
        let sharedState = mockRuntime.createdSharedStates[0]
        let lifecycleData = sharedState?["lifecyclecontextdata"] as? [String:Any]
        XCTAssertEqual(mockSystemInfoService.mobileCarrierName, lifecycleData?["carriername"] as? String)
        XCTAssertEqual("100x100", lifecycleData?["resolution"] as? String)
        XCTAssertEqual(mockSystemInfoService.runMode, lifecycleData?["runmode"] as? String)
        XCTAssertEqual(mockSystemInfoService.activeLocaleName, lifecycleData?["locale"] as? String)
        XCTAssertEqual(mockSystemInfoService.operatingSystemName, lifecycleData?["osversion"] as? String)
        XCTAssertEqual("Test app name 1.1.1 (12345)", lifecycleData?["appid"] as? String)
        XCTAssertEqual(mockSystemInfoService.deviceName, lifecycleData?["devicename"] as? String)
    }
    
    /// Tests first launch
    func testLifecycleFirstLaunch() {
        // setup
        let calendar = Calendar.current
        var dateComponents: DateComponents? = calendar.dateComponents([.hour, .minute, .second], from: Date())
        dateComponents?.day = 27
        dateComponents?.month = 7
        dateComponents?.year = 2020
        dateComponents?.hour = 22
        let date: Date = calendar.date(from: dateComponents!)!
        
        let event = createStartEvent().copyWithNewTimeStamp(date)
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: ([:],.set))
        
        // test
        mockRuntime.simulateComingEvents(event)
        
        //verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(0, dispatchedEvent.data?["previoussessionstarttimestampmillis"] as? Double)
        XCTAssertEqual(0, dispatchedEvent.data?["previoussessionpausetimestampmillis"] as? Double)
        XCTAssertEqual(86400.0 * 7.0 , dispatchedEvent.data?["maxsessionlength"] as? Double)
        // the value of starttimestampmillis changes based on the time zone
        XCTAssertNotNil(dispatchedEvent.data?["starttimestampmillis"] as? Double)
        XCTAssertEqual("start", dispatchedEvent.data?["sessionevent"] as? String)
        
        XCTAssertEqual("2", dispatchedEvent.lifecycleContextData["dayofweek"] as? String)
        XCTAssertEqual("22", dispatchedEvent.lifecycleContextData["hourofday"] as? String)
        XCTAssertEqual("InstallEvent", dispatchedEvent.lifecycleContextData["installevent"] as? String)
        XCTAssertEqual("LaunchEvent", dispatchedEvent.lifecycleContextData["launchevent"] as? String)
        XCTAssertEqual("MonthlyEngUserEvent", dispatchedEvent.lifecycleContextData["monthlyenguserevent"] as? String)
        XCTAssertEqual("DailyEngUserEvent", dispatchedEvent.lifecycleContextData["dailyenguserevent"] as? String)
        XCTAssertEqual("7/27/2020", dispatchedEvent.lifecycleContextData["installdate"] as? String)
        XCTAssertEqual("1", dispatchedEvent.lifecycleContextData["launches"] as? String)
        
        // shared state
        let sharedState = mockRuntime.createdSharedStates[0]
        let lifecycleData = sharedState?["lifecyclecontextdata"] as? [String:Any]
        
        XCTAssertEqual("2", lifecycleData?["dayofweek"] as? String)
        XCTAssertEqual("22", lifecycleData?["hourofday"] as? String)
        XCTAssertEqual("InstallEvent", lifecycleData?["installevent"] as? String)
        XCTAssertEqual("LaunchEvent", lifecycleData?["launchevent"] as? String)
        XCTAssertEqual("MonthlyEngUserEvent", lifecycleData?["monthlyenguserevent"] as? String)
        XCTAssertEqual("DailyEngUserEvent", lifecycleData?["dailyenguserevent"] as? String)
        XCTAssertEqual("7/27/2020", lifecycleData?["installdate"] as? String)
        XCTAssertEqual("1", lifecycleData?["launches"] as? String)
        
        
    }
    
    /// Tests additional data
    func testLifecycleAdditionalData() {
        // setup
        let additionalContextData = ["testKey": "testVal"]
        let event = createStartEvent(additionalData: additionalContextData)
        mockRuntime.simulateSharedState(for: (extensionName: "com.adobe.module.configuration", event: event), data: ([:],.set))
        
        // test
        mockRuntime.simulateComingEvents(event)
        
        //verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.createdSharedStates.count)
        
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual("testVal", dispatchedEvent.lifecycleContextData["testKey"] as? String)
    }

    /// Tests simple start then pause, then start again, the second start call should be ignored, shared state will be updated twice
    func testLifecycleStartPauseStart() {
        // setup
        let startEvent1 = createStartEvent()
        let pauseEvent = createPauseEvent()
        let startEvent2 = createStartEvent()
                
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))

        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent, startEvent2)

        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        
        XCTAssertEqual(mockRuntime.createdSharedStates[0]?.count, mockRuntime.createdSharedStates[1]?.count)
    }

    /// Tests simple start then pause, then start again, the second start call should NOT be ignored
    func testLifecycleStartPauseStartOverTimeout() {
        // setup
        let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
        let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 10))
        let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 40))
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))

        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent, startEvent2)
        

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("1", (mockRuntime.dispatchedEvents[0].data?["lifecyclecontextdata"] as? [String: Any])?["launches"] as? String)
        XCTAssertEqual("2", (mockRuntime.dispatchedEvents[1].data?["lifecyclecontextdata"] as? [String: Any])?["launches"] as? String)
        
        XCTAssertEqual(1595909459, mockRuntime.dispatchedEvents[1].data?["previoussessionstarttimestampmillis"] as? Double)
        XCTAssertEqual(1595909469, mockRuntime.dispatchedEvents[1].data?["previoussessionpausetimestampmillis"] as? Double)
        XCTAssertEqual(86400.0 * 7.0 , mockRuntime.dispatchedEvents[1].data?["maxsessionlength"] as? Double)
        XCTAssertEqual(1595909499, mockRuntime.dispatchedEvents[1].data?["starttimestampmillis"] as? Double)
        XCTAssertEqual("start", mockRuntime.dispatchedEvents[1].data?["sessionevent"] as? String)
 
    }
    
    /// Tests crash event when the last session was not gracefully closed
    func testLifecycleCrash() {
        // setup
        let startEvent1 = createStartEvent()
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":1],.set))
        
        let mockRuntimeSession2 = TestableExtensionRuntime()
        mockRuntimeSession2.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":1],.set))

        // test
        // start event, no pause event
        mockRuntime.simulateComingEvents(startEvent1)
        
        // simulate a new start
        let lifecycleSession2 = Lifecycle(runtime: mockRuntimeSession2)
        lifecycleSession2.onRegistered()
        mockRuntimeSession2.simulateComingEvents(createStartEvent())

        // verify
        XCTAssertEqual(1, mockRuntimeSession2.dispatchedEvents.count)
        XCTAssertEqual("CrashEvent", (mockRuntimeSession2.dispatchedEvents[0].data?["lifecyclecontextdata"] as? [String: Any])?["crashevent"] as? String)

        
    }

    /// Tests  start then pause after max session length
    func testLifecycleStartPauseStartOverMaxSessionLength() {
        // setup
        let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
        let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 10000000))
        let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 10000000 + 40))
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))

        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent, startEvent2)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("10000000", (mockRuntime.dispatchedEvents[1].data?["lifecyclecontextdata"] as? [String: Any])?["ignoredsessionlength"] as? String)
        
        let sharedState = mockRuntime.createdSharedStates[1]
        let lifecycleData = sharedState?["lifecyclecontextdata"] as? [String:Any]
        XCTAssertEqual("10000000", lifecycleData?["ignoredsessionlength"] as? String)
    }
    
    /// Tests  start then pause
    func testLifecycleStartPauseStartSessionLength() {
        // setup
        let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
        let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100))
        let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100 + 40))
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))

        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent, startEvent2)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntime.createdSharedStates.count)
        XCTAssertEqual("100", (mockRuntime.dispatchedEvents[1].data?["lifecyclecontextdata"] as? [String: Any])?["prevsessionlength"] as? String)
        
        let sharedState = mockRuntime.createdSharedStates[1]
        let lifecycleData = sharedState?["lifecyclecontextdata"] as? [String:Any]
        XCTAssertEqual("100", lifecycleData?["prevsessionlength"] as? String)
    }
    
    /// Tests upgrade event when app version changes
    func testUpgrade() {
        // setup
        let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
        let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100))
        let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100 + 40))
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))
        
        let mockRuntimeSession2 = TestableExtensionRuntime()
        mockRuntimeSession2.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))

        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent)
        
        // simulate a new start
        mockSystemInfoService.applicationVersionNumber = "1.2"
        let lifecycleSession2 = Lifecycle(runtime: mockRuntimeSession2)
        lifecycleSession2.onRegistered()
        mockRuntimeSession2.simulateComingEvents(startEvent2)

        // verify
        XCTAssertEqual("UpgradeEvent", (mockRuntimeSession2.dispatchedEvents[0].data?["lifecyclecontextdata"] as? [String: Any])?["upgradeevent"] as? String)
        
        let sharedState = mockRuntimeSession2.createdSharedStates[1]
        let lifecycleData = sharedState?["lifecyclecontextdata"] as? [String:Any]
        XCTAssertEqual("UpgradeEvent", lifecycleData?["upgradeevent"] as? String)
    }
    
    /// Tests dailyUserEvent when the new launch happens in the same day
    func testDailyUserEventWithinSameDay() {
        // setup
        let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
        let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100))
        let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100 + 40))
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))
        
        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        mockRuntime.simulateComingEvents(startEvent2)

        // verify
        XCTAssertNil((mockRuntime.dispatchedEvents[0].data?["lifecyclecontextdata"] as? [String: Any])?["dailyenguserevent"])
        let lifecycleData = mockRuntime.createdSharedStates[0]?["lifecyclecontextdata"] as? [String:Any]
        XCTAssertNil(lifecycleData?["dailyenguserevent"])
    }
    
    /// Tests dailyUserEvent when the new launch happens after one day
    func testDailyUserEventAfterOneDay() {
        // setup
        let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
        let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100))
        let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100 + 60 * 60 * 24))
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))
        
        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent)
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
        mockRuntime.simulateComingEvents(startEvent2)

        // verify
        XCTAssertEqual("DailyEngUserEvent", (mockRuntime.dispatchedEvents[0].data?["lifecyclecontextdata"] as? [String: Any])?["dailyenguserevent"] as? String)
        let lifecycleData = mockRuntime.createdSharedStates[0]?["lifecyclecontextdata"] as? [String:Any]
        XCTAssertEqual("DailyEngUserEvent", lifecycleData?["dailyenguserevent"] as? String)
    }
    
    /// Tests dailyUserEvent when the new launch happens in the same month
       func testMonthlyUserEventWithinSameMonth() {
           // setup
           let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
           let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100))
           let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100 + 60 * 60 * 24))
           
           mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))
           
           // test
           mockRuntime.simulateComingEvents(startEvent1, pauseEvent)
           mockRuntime.resetDispatchedEventAndCreatedSharedStates()
           mockRuntime.simulateComingEvents(startEvent2)

           // verify
           XCTAssertNil((mockRuntime.dispatchedEvents[0].data?["lifecyclecontextdata"] as? [String: Any])?["monthlyenguserevent"])
           let lifecycleData = mockRuntime.createdSharedStates[0]?["lifecyclecontextdata"] as? [String:Any]
           XCTAssertNil(lifecycleData?["monthlyenguserevent"])
       }
       
       /// Tests dailyUserEvent when the new launch happens after one day
       func testMonthlyUserEventAfterOneMonth() {
           // setup
           let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
           let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100))
           let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100 + 60 * 60 * 24 * 30))
           
           mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))
           
           // test
           mockRuntime.simulateComingEvents(startEvent1, pauseEvent)
           mockRuntime.resetDispatchedEventAndCreatedSharedStates()
           mockRuntime.simulateComingEvents(startEvent2)

           // verify
           XCTAssertEqual("MonthlyEngUserEvent", (mockRuntime.dispatchedEvents[0].data?["lifecyclecontextdata"] as? [String: Any])?["monthlyenguserevent"] as? String)
           let lifecycleData = mockRuntime.createdSharedStates[0]?["lifecyclecontextdata"] as? [String:Any]
           XCTAssertEqual("MonthlyEngUserEvent", lifecycleData?["monthlyenguserevent"] as? String)
       }
    
    
    /// Tests restore of the lifecycle shared state from the previous session
    func testForceCloseThenRestartWithinSessionTimeout() {
        // setup
        let startEvent1 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459))
        let pauseEvent = createPauseEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100))
        let startEvent2 = createStartEvent().copyWithNewTimeStamp(Date(timeIntervalSince1970:1595909459 + 100 + 10))
        
        mockRuntime.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))
        
        let mockRuntimeSession2 = TestableExtensionRuntime()
        mockRuntimeSession2.simulateSharedState(for: "com.adobe.module.configuration", data: (["lifecycle.sessionTimeout":30],.set))

        // test
        mockRuntime.simulateComingEvents(startEvent1, pauseEvent)
        
        // simulate a new start
        let lifecycleSession2 = Lifecycle(runtime: mockRuntimeSession2)
        lifecycleSession2.onRegistered()
        mockRuntimeSession2.simulateComingEvents(startEvent2)

        // verify
        XCTAssertEqual(0, mockRuntimeSession2.dispatchedEvents.count)
        XCTAssertEqual(2, mockRuntimeSession2.createdSharedStates.count)
        let sharedState = mockRuntimeSession2.createdSharedStates[1]
        let lifecycleData = sharedState?["lifecyclecontextdata"] as? [String:Any]
        XCTAssertEqual("InstallEvent", lifecycleData?["installevent"] as? String)
    }
    
    func createStartEvent(additionalData: [String:Any] = [:]) -> Event{
        let data: [String: Any] = ["action": "start",
                                   "additionalcontextdata": additionalData]
        return Event(name: "Lifecycle Start", type: .genericLifecycle, source: .requestContent, data: data)
    }
    
    func createPauseEvent() -> Event{
        let data: [String: Any] = ["action": "pause"]
        return Event(name: "Lifecycle Start", type: .genericLifecycle, source: .requestContent, data: data)
    }
}

extension Event{
    var lifecycleContextData: [String: Any]{
        return (data?["lifecyclecontextdata"] as? [String: Any])!
    }
}
