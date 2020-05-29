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

class LifecycleStateTests: XCTestCase {
    
    var lifecycleState: LifecycleState!
    var dataStore = NamedKeyValueStore(name: "LifecycleStateTests")
    var mockSystemInfoService: MockSystemInfoService!
    
    var currentDate: Date!
    var currentDateMinusOneSecond: Date!
    var currentDateMinusTenMin: Date!
    var currentDateMinusOneHour: Date!
    var currentDateMinusOneDay: Date!
    
    override func setUp() {
        setupDates()
        setupMockSystemInfoService()
        dataStore.removeAll()
        lifecycleState = LifecycleState(dataStore: dataStore)
    }
    
    private func setupDates() {
        currentDate = Date()
        
        currentDateMinusOneSecond = Calendar.current.date(byAdding: .second, value: -1, to: currentDate)
        currentDateMinusTenMin = Calendar.current.date(byAdding: .minute, value: -10, to: currentDate)
        currentDateMinusOneHour = Calendar.current.date(byAdding: .hour, value: -1, to: currentDate)
        currentDateMinusOneDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)
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
    
    /// Happy path testing start
    func testStartSimple() {
        // setup
        var persistedContext = LifecyclePersistedContext()
        persistedContext.pauseDate = currentDateMinusOneSecond
        persistedContext.startDate = currentDateMinusTenMin
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: persistedContext)
        let mockAppVersion = "1.1.1"
        dataStore.set(key: LifecycleConstants.DataStoreKeys.LAST_VERSION, value: mockAppVersion)
        
        // test
        lifecycleState.start(date: currentDate, additionalContextData: nil, adId: nil)
        
        // verify
        let actualContext: LifecyclePersistedContext = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT)!
        XCTAssertEqual(currentDateMinusTenMin.timeIntervalSince1970 + 1, actualContext.startDate?.timeIntervalSince1970)
        XCTAssertFalse(actualContext.successfulClose)
        XCTAssertNil(actualContext.pauseDate)
        XCTAssertEqual(mockAppVersion, dataStore.getString(key: LifecycleConstants.DataStoreKeys.LAST_VERSION))
    }
    
    func testPreviousSessionCrashed() {
        // setup
        let osVersion = "iOS 13.0"
        let appId = "app_id_123"
        
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.INSTALL_DATE, value: currentDateMinusOneDay)
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LAST_LAUNCH_DATE, value: Date(timeIntervalSince1970: 0))
        dataStore.set(key: LifecycleConstants.DataStoreKeys.LAST_VERSION, value: "1.1.0")
        
        var persistedContext = LifecyclePersistedContext()
        persistedContext.startDate = currentDateMinusTenMin
        persistedContext.successfulClose = false
        persistedContext.osVersion = osVersion
        persistedContext.appId = appId
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: persistedContext)
        
        // test
        lifecycleState.start(date: currentDate, additionalContextData: nil, adId: nil)
        
        // verify
        let actualContextData = lifecycleState.getContextData()
        
        XCTAssertTrue((actualContextData?.lifecycleMetrics.crashEvent)!)
        XCTAssertEqual(actualContextData?.lifecycleMetrics.previousOsVersion, osVersion)
        XCTAssertEqual(actualContextData?.lifecycleMetrics.previousAppId, appId)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.appId)
        XCTAssertEqual(mockSystemInfoService.getMobileCarrierName(), actualContextData?.lifecycleMetrics.carrierName)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.crashEvent ?? false)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.dailyEngagedEvent ?? false)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.dayOfTheWeek)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.hourOfTheDay)
        XCTAssertEqual(1, actualContextData?.lifecycleMetrics.daysSinceFirstLaunch)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.daysSinceLastLaunch)
        XCTAssertNotNil(actualContextData?.sessionContextData[LifecycleConstants.Keys.IGNORED_SESSION_LENGTH])
        XCTAssertEqual(1, actualContextData?.lifecycleMetrics.launches)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.launchEvent ?? false)
        XCTAssertEqual(mockSystemInfoService.getActiveLocaleName(), actualContextData?.lifecycleMetrics.locale)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.monthlyEngagedEvent ?? false)
        XCTAssertEqual(osVersion, actualContextData?.lifecycleMetrics.previousOsVersion)
        XCTAssertEqual(appId, actualContextData?.lifecycleMetrics.previousAppId)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.deviceResolution)
        XCTAssertEqual(mockSystemInfoService.getRunMode(), actualContextData?.lifecycleMetrics.runMode)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.upgradeEvent ?? false)
        XCTAssertFalse(actualContextData?.lifecycleMetrics.installEvent ?? true)
        
    }
    
    func testStartAppResumeVersionUpgradeNoLifecycleInMemory() {
        // setup
        var persistedContext = LifecyclePersistedContext()
        persistedContext.pauseDate = currentDateMinusOneSecond
        persistedContext.startDate = currentDateMinusTenMin
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: persistedContext)
        dataStore.set(key: LifecycleConstants.DataStoreKeys.LAST_VERSION, value: "1.1.1")
        
        let expectedAppId = "new-app-id"
        var contextData = LifecycleContextData()
        contextData.lifecycleMetrics = LifecycleMetrics()
        contextData.lifecycleMetrics.appId = expectedAppId
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA, value: contextData)
        
        // test
        lifecycleState.start(date: currentDate, additionalContextData: nil, adId: nil)
        
        // verify
        let actualContextData = lifecycleState.getContextData()
        XCTAssertEqual(expectedAppId, actualContextData?.lifecycleMetrics.appId)
    }
    
    func testAppResumeVersionUpgradeLifecycleIsInMemory() {
        // setup
        let expectedAppId = "a-different-app-id"
        var contextData = LifecycleContextData()
        contextData.lifecycleMetrics = LifecycleMetrics()
        contextData.lifecycleMetrics.appId = expectedAppId
        
        lifecycleState.lifecycleContextData = contextData
        
        // test
        lifecycleState.start(date: currentDate, additionalContextData: nil, adId: nil, sessionTimeout: 200)
        
        // verify
        let actualContextData = lifecycleState.getContextData()
        
        XCTAssertEqual("Test app name 1.1.1 (12345)", actualContextData?.lifecycleMetrics.appId)
        XCTAssertEqual(mockSystemInfoService.getMobileCarrierName(), actualContextData?.lifecycleMetrics.carrierName)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.dailyEngagedEvent ?? false)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.dayOfTheWeek)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.hourOfTheDay)
        XCTAssertEqual(mockSystemInfoService.getDeviceName(), actualContextData?.lifecycleMetrics.deviceName)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.installDate)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.installEvent ?? false)
        XCTAssertEqual(1, actualContextData?.lifecycleMetrics.launches)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.launchEvent ?? false)
        XCTAssertEqual(mockSystemInfoService.getActiveLocaleName(), actualContextData?.lifecycleMetrics.locale)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.monthlyEngagedEvent ?? false)
        XCTAssertEqual(mockSystemInfoService.getOperatingSystemName(), actualContextData?.lifecycleMetrics.operatingSystem)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.deviceResolution)
        XCTAssertEqual(mockSystemInfoService.getRunMode(), actualContextData?.lifecycleMetrics.runMode)
        XCTAssertFalse(actualContextData?.lifecycleMetrics.upgradeEvent ?? true)
        XCTAssertFalse(actualContextData?.lifecycleMetrics.crashEvent ?? true)
    }
    
    func testStartAppResumeVersionsAreSame() {
        // setup
        let appName = "test app name"
        let testAppVersion = "1.1.0"
        let expectedAppId = "\(appName) \(testAppVersion)"
        
        var persistedContext = LifecyclePersistedContext()
        persistedContext.pauseDate = currentDateMinusOneSecond
        persistedContext.startDate = currentDateMinusTenMin
        
        var contextData = LifecycleContextData()
        contextData.lifecycleMetrics = LifecycleMetrics()
        contextData.lifecycleMetrics.appId = expectedAppId
        
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: persistedContext)
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA, value: contextData)
        dataStore.set(key: LifecycleConstants.DataStoreKeys.LAST_VERSION, value: "1.1.1")
        
        
        // test
        lifecycleState.start(date: currentDate, additionalContextData: nil, adId: nil, sessionTimeout: 200)
        
        // verify
        let actualContextData = lifecycleState.getContextData()
        XCTAssertEqual(expectedAppId, actualContextData?.lifecycleMetrics.appId)
    }

    func testStartOverTimeoutAdditionalData() {
        // setup
        let appVersion = "1.1.1"
        
        var persistedContext = LifecyclePersistedContext()
        persistedContext.pauseDate = currentDateMinusTenMin
        persistedContext.startDate = currentDateMinusOneHour
        persistedContext.successfulClose = true
        
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.INSTALL_DATE, value: currentDateMinusOneDay)
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LAST_LAUNCH_DATE, value: currentDateMinusTenMin)
        dataStore.set(key: LifecycleConstants.DataStoreKeys.LAST_VERSION, value: appVersion)
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: persistedContext)
        
        let additionalData = ["testKey1": "testVal1"]
        let adId = "testAdId"
        
        // test
        lifecycleState.start(date: currentDate, additionalContextData: additionalData, adId: adId, sessionTimeout: 200)
        
        // verify
        let actualContextData = lifecycleState.getContextData()
        let actualContext: LifecyclePersistedContext! = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT)
        let lastUsedDate: Date = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.LAST_LAUNCH_DATE)!
        
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.appId)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.deviceResolution)
        XCTAssertEqual(mockSystemInfoService.getMobileCarrierName(), actualContextData?.lifecycleMetrics.carrierName)
        XCTAssertEqual(mockSystemInfoService.getOperatingSystemName(), actualContextData?.lifecycleMetrics.operatingSystem)
        XCTAssertEqual(mockSystemInfoService.getDeviceName(), actualContextData?.lifecycleMetrics.deviceName)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.dayOfTheWeek)
        XCTAssertNotNil(actualContextData?.lifecycleMetrics.hourOfTheDay)
        XCTAssertEqual(1, actualContextData?.lifecycleMetrics.launches)
        XCTAssertTrue(actualContextData?.lifecycleMetrics.launchEvent ?? false)
        XCTAssertEqual(mockSystemInfoService.getActiveLocaleName(), actualContextData?.lifecycleMetrics.locale)
        XCTAssertEqual(mockSystemInfoService.getRunMode(), actualContextData?.lifecycleMetrics.runMode)
        XCTAssertEqual("3000", actualContextData?.sessionContextData[LifecycleConstants.Keys.PREVIOUS_SESSION_LENGTH])
        XCTAssertEqual(1, actualContextData?.lifecycleMetrics.daysSinceFirstLaunch)
        XCTAssertEqual(0, actualContextData?.lifecycleMetrics.daysSinceLastLaunch)
        XCTAssertEqual(1, actualContext.launches)
        XCTAssertEqual(currentDate, lastUsedDate)
        XCTAssertEqual(currentDate, actualContext.startDate)
        XCTAssertEqual(appVersion, dataStore.getString(key: LifecycleConstants.DataStoreKeys.LAST_VERSION))
        XCTAssertFalse(actualContext.successfulClose )
        XCTAssertEqual(additionalData, actualContextData?.additionalContextData)
        XCTAssertEqual(adId, actualContextData?.advertisingIdentifier)
    }
    
    // MARK: Pause(...) tests
    func testPauseSimple() {
        // test
        lifecycleState.pause(pauseDate: currentDate)
        
        // verify
        let actualContext: LifecyclePersistedContext! = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT)
        XCTAssertTrue(actualContext.successfulClose )
        XCTAssertEqual(currentDate, actualContext.pauseDate)
    }
    
    // MARK: GetContextData() tests
    
    /// When no context data exists we should return nil
    func testEmptyContextData() {
        XCTAssertNil(lifecycleState.getContextData())
    }
    
    /// Should properly return `lifecycleContextData`
    func testInMemoryContextDataExists() {
        // setup
        var contextData = LifecycleContextData()
        contextData.additionalContextData = ["testKey": "testVal"]
        lifecycleState.lifecycleContextData = contextData
        
        // test
        let actualContextData = lifecycleState.getContextData()
        
        // verify
        XCTAssertEqual(actualContextData?.additionalContextData, contextData.additionalContextData)
    }
    
    /// Should properly return `lifecycleContextData` even when `previousSessionLifecycleContextData` is non-nil
    func testInMemoryContextDataExistsAndPreviousSessionExists() {
        // setup
        var contextData = LifecycleContextData()
        contextData.additionalContextData = ["testKey": "testVal"]
        lifecycleState.lifecycleContextData = contextData
        
        var contextData1 = LifecycleContextData()
        contextData1.additionalContextData = ["testKey1": "testVal1"]
        lifecycleState.previousSessionLifecycleContextData = contextData1
        
        // test
        let actualContextData = lifecycleState.getContextData()
        
        // verify
        XCTAssertEqual(actualContextData?.additionalContextData, contextData.additionalContextData)
    }
    
    /// Should properly return `previousSessionLifecycleContextData` when `lifecycleContextData` is nil
    func testInMemoryPreviousSessionContextDataExists() {
        // setup
        var contextData = LifecycleContextData()
        contextData.additionalContextData = ["testKey": "testVal"]
        lifecycleState.previousSessionLifecycleContextData = contextData
        
        // test
        let actualContextData = lifecycleState.getContextData()
        
        // verify
        XCTAssertEqual(actualContextData?.additionalContextData, contextData.additionalContextData)
    }
    
    /// When `lifecycleContextData` and `previousSessionLifecycleContextData` are nil we should attempt to load from data store
    func testPersistedContextDataExists() {
        // setup
        var contextData = LifecycleContextData()
        contextData.additionalContextData = ["testKey": "testVal"]
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA, value: contextData)
        
        // test
        let actualContextData = lifecycleState.getContextData()
        
        // verify
        XCTAssertEqual(actualContextData?.additionalContextData, contextData.additionalContextData)
    }
    
    // MARK: checkForApplicationUpgrade(...) tests
    
    /// When context data is empty, it should remain empty after invoking `checkForApplicationUpgrade`
    func testCheckApplicationUpgradeWhenContextDataNil() {
        // test
        lifecycleState.checkForApplicationUpgrade(appId: "")
        
        // verify
        XCTAssertNil(lifecycleState.getContextData())
    }
    
    /// When appId is present in memory we, it should be present in the context data
    func testCheckApplicationUpgradeAppUpgradeExistingLifecycleDataInMemeory() {
        // setup
        let appId = "test-app-id"
        var contextData = LifecycleContextData()
        contextData.lifecycleMetrics = LifecycleMetrics()
        contextData.lifecycleMetrics.appId = appId
        lifecycleState.lifecycleContextData = contextData
        
        // test
        lifecycleState.checkForApplicationUpgrade(appId: appId)
        
        // verify
        XCTAssertEqual(appId, lifecycleState.getContextData()?.lifecycleMetrics.appId)
    }
    
    /// When appId is present in the persisted data we, it should be present in the context data
    func testCheckApplicationUpgradeAppUpgradeExistingLifecycleDataPersisted() {
        // setup
        let appId = "test-app-id"
        var contextData = LifecycleContextData()
        contextData.lifecycleMetrics = LifecycleMetrics()
        contextData.lifecycleMetrics.appId = appId
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA, value: contextData)
        
        // test
        lifecycleState.checkForApplicationUpgrade(appId: appId)
        
        // verify
        XCTAssertEqual(appId, lifecycleState.getContextData()?.lifecycleMetrics.appId)
    }
    
    func testCheckApplicationUpgradeHappy() {
        // setup
        let appId = "new-app-id"
        let appVersion = "appVersion"
        var contextData = LifecycleContextData()
        contextData.lifecycleMetrics = LifecycleMetrics()
        contextData.lifecycleMetrics.appId = appId
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.LIFECYCLE_DATA, value: contextData)
        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.INSTALL_DATE, value: currentDate)
        dataStore.set(key: LifecycleConstants.DataStoreKeys.LAST_VERSION, value: appVersion)
        
        // test
        lifecycleState.checkForApplicationUpgrade(appId: appId)
        
        // verify
        let actualContextData = lifecycleState.getContextData()
        XCTAssertEqual(appId, actualContextData?.lifecycleMetrics.appId)
    }
}
