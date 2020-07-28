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
@testable import AEPLifecycle
@testable import AEPServices
import AEPServicesMock

class LifecycleMetricsBuilderTests: XCTestCase {
    
    private var dataStore: FakeDataStore?
    private var metricsBuilder: LifecycleMetricsBuilder?
    private var systemInfoService: MockSystemInfoService?
    private var date: Date = Date()
    private typealias KEYS = LifecycleConstants.EventDataKeys
    
    override func setUp() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/05/02 22:31")
        self.date = someDateTime!
        self.systemInfoService = MockSystemInfoService()
        ServiceProvider.shared.systemInfoService = self.systemInfoService!
        self.dataStore = FakeDataStore(name: "testStore")
        self.metricsBuilder = LifecycleMetricsBuilder(dataStore: self.dataStore!, date: self.date)
    }
    
    override func tearDown() {
        dataStore?.removeAll()
        metricsBuilder = nil
    }
    
    func testAddInstallData() {
        metricsBuilder?.addInstallData()
        let metrics = metricsBuilder?.build()
        XCTAssertEqual(metrics?.dailyEngagedEvent, true)
        XCTAssertEqual(metrics?.monthlyEngagedEvent, true)
        XCTAssertEqual(metrics?.installEvent, true)
        XCTAssertEqual(metrics?.installDate, self.date)
        XCTAssertTrue((dataStore?.setObjectCalled)!)
        XCTAssertEqual(dataStore?.setObjectValues[0] as? Date, self.date)
    }
    
    // Tests add launch data when last launch is in the same month as current launch
    func testAddLaunchDataSameMonth() {
        let lastLaunchDate = Calendar.current.date(byAdding: .day, value: -1, to: self.date)
        let firstLaunchDate = Calendar.current.date(byAdding: .day, value: -1, to: lastLaunchDate!)
        dataStore?.getObjectValues.append(firstLaunchDate!)
        dataStore?.getObjectValues.append(lastLaunchDate!)
        
        metricsBuilder?.addLaunchData()
        let metrics = metricsBuilder?.build()

        XCTAssertTrue(metrics!.dailyEngagedEvent ?? false)
        XCTAssertNil(metrics!.monthlyEngagedEvent)
        // Check that the "daysSinceLastLaunch" and "daysSinceFirstLaunch" values are correct
        XCTAssertEqual(metrics?.daysSinceLastLaunch, 1)
        XCTAssertEqual(metrics?.daysSinceFirstLaunch, 2)
    }
    
    // Tests add launch data when last launch was a month before this launch
    func testAddLaunchDataDifferentMonth() {
        let lastLaunchDate = Calendar.current.date(byAdding: .month, value: -1, to: self.date)
        let firstLaunchDate = Calendar.current.date(byAdding: .day, value: -1, to: lastLaunchDate!)
        dataStore?.getObjectValues.append(firstLaunchDate!)
        dataStore?.getObjectValues.append(lastLaunchDate!)
        
        metricsBuilder?.addLaunchData()
        let metrics = metricsBuilder?.build()

        XCTAssertTrue(metrics!.dailyEngagedEvent ?? false)
        XCTAssertTrue(metrics!.monthlyEngagedEvent ?? false)
        // Check that the "daysSinceLastLaunch" and "daysSinceFirstLaunch" values are correct when last launch was a month prior, and first launch was one day before that
        XCTAssertEqual(metrics?.daysSinceLastLaunch, 30)
        XCTAssertEqual(metrics?.daysSinceFirstLaunch, 31)
    }
    
    func testAddGenericDataWithLaunches() {
        let numberOfLaunches = 1
        var mockPersistedContext = LifecyclePersistedContext()
        mockPersistedContext.launches = numberOfLaunches
        dataStore?.getObjectValues.append(mockPersistedContext)
        
        let currentDateComponents = Calendar.current.dateComponents([.weekday, .hour], from: self.date)
        
        metricsBuilder?.addLaunchEventData()
        let metrics = metricsBuilder?.build()
        
        XCTAssertEqual(metrics?.launches, numberOfLaunches)
        XCTAssertEqual(metrics?.dayOfTheWeek, currentDateComponents.weekday)
        XCTAssertEqual(metrics?.hourOfTheDay, currentDateComponents.hour)
        XCTAssertTrue(metrics!.launchEvent ?? false)
    }
    
    func testAddGenericDataWithoutLaunches() {
        let currentDateComponents = Calendar.current.dateComponents([.weekday, .hour], from: self.date)
        
        metricsBuilder?.addLaunchEventData()
        let metrics = metricsBuilder?.build()
        
        XCTAssertNil(metrics?.launches)
        XCTAssertEqual(metrics?.dayOfTheWeek, currentDateComponents.weekday)
        XCTAssertEqual(metrics?.hourOfTheDay, currentDateComponents.hour)
        XCTAssertTrue(metrics!.launchEvent ?? false)
    }
    
    func testAddUpgradeDataWithUpgrade() {
        metricsBuilder?.addUpgradeData(upgrade: true)
        let metrics = metricsBuilder?.build()
        
        XCTAssertTrue(metrics!.upgradeEvent ?? false)
        XCTAssertEqual(dataStore?.setObjectValues[0] as? Date, self.date)
        XCTAssertEqual(dataStore?.setIntValues[0], 0)
    }
    
    func testAddUpgradeDataWithoutUpgrade() {
        let daysSinceLastUpgrade = 5
        let lastUpgradeDate = Calendar.current.date(byAdding: .day, value: -(daysSinceLastUpgrade), to: self.date)
        dataStore?.getObjectValues.append(lastUpgradeDate!)
        var launchesSinceLastUpgrade = 10
        dataStore?.getIntValues.append(launchesSinceLastUpgrade)
        let _ = metricsBuilder?.addUpgradeData(upgrade: false)
        let metrics = metricsBuilder?.build()
        launchesSinceLastUpgrade += 1
        XCTAssertEqual(metrics?.daysSinceLastUpgrade, daysSinceLastUpgrade)
        XCTAssertEqual(dataStore?.setIntValues[0], launchesSinceLastUpgrade)
        XCTAssertEqual(metrics?.launchesSinceUpgrade, launchesSinceLastUpgrade)
    }
    
    func testAddCrashData() {
        let previousSessionCrash = true
        let osVersion = "13.0"
        let appID = "testAppID"
        metricsBuilder?.addCrashData(previousSessionCrash: previousSessionCrash, osVersion: osVersion, appId: appID)
        let metrics = metricsBuilder?.build()
        XCTAssertEqual(metrics?.crashEvent, previousSessionCrash)
        XCTAssertEqual(metrics?.previousOsVersion, osVersion)
        XCTAssertEqual(metrics?.previousAppId, appID)
    }
    
    func testAddDeviceData() {
        let deviceName = "testDevice"
        self.systemInfoService?.deviceName = deviceName
        let mobileCarrierName = "testCarrier"
        self.systemInfoService?.mobileCarrierName = mobileCarrierName
        let applicationName = "testAppName"
        self.systemInfoService?.applicationName = applicationName
        let applicationVersionNumber = "1.0.1"
        self.systemInfoService?.applicationVersionNumber = applicationVersionNumber
        let applicationBuildNumber = "11C29"
        self.systemInfoService?.applicationBuildNumber = applicationBuildNumber
        let applicationIdentifier = "\(applicationName) \(applicationVersionNumber) (\(applicationBuildNumber))"
        let operatingSystemName = "iOS"
        self.systemInfoService?.operatingSystemName = operatingSystemName
        let widthPixels = 375
        let heightPixels = 812
        let resolution = "\(widthPixels)x\(heightPixels)"
        self.systemInfoService?.displayInformation = (widthPixels, heightPixels)
        let locale = "US_OF_A"
        let formattedLocale = "US-OF-A"
        self.systemInfoService?.activeLocaleName = locale
        let runMode = "Application"
        self.systemInfoService?.runMode = runMode
        
        metricsBuilder?.addDeviceData()
        let metrics = metricsBuilder?.build()
        XCTAssertEqual(metrics?.deviceName, deviceName)
        XCTAssertEqual(metrics?.carrierName, mobileCarrierName)
        XCTAssertEqual(metrics?.appId, applicationIdentifier)
        XCTAssertEqual(metrics?.deviceResolution, resolution)
        XCTAssertEqual(metrics?.operatingSystem, operatingSystemName)
        XCTAssertEqual(metrics?.locale, formattedLocale)
        XCTAssertEqual(metrics?.runMode, runMode)
    }
    
    func testAddDeviceDataNoName() {
        let applicationVersionNumber = "1.0.1"
        let applicationBuildNumber = "11C29"
        self.systemInfoService?.applicationBuildNumber = applicationBuildNumber
        self.systemInfoService?.applicationVersionNumber = applicationVersionNumber
        let applicationIdentifierNoName = "\(applicationVersionNumber) (\(applicationBuildNumber))"
        metricsBuilder?.addDeviceData()
        let metricsNoName = metricsBuilder?.build()
        XCTAssertEqual(metricsNoName?.appId, applicationIdentifierNoName)
    }
    
    func testAddDeviceDataNoVersionNumber() {
        let applicationName = "testAppName"
        let applicationBuildNumber = "11C29"
        self.systemInfoService?.applicationName = applicationName
        self.systemInfoService?.applicationBuildNumber = applicationBuildNumber
        let applicationIdentifierNoVersionNumber = "\(applicationName) (\(applicationBuildNumber))"
        metricsBuilder?.addDeviceData()
        let metricsNoBuild = metricsBuilder?.build()
        XCTAssertEqual(metricsNoBuild?.appId, applicationIdentifierNoVersionNumber)
    }
    
    func testAddDeviceDataNoBuildNumber() {
        let applicationName = "testAppName"
        let applicationVersionNumber = "1.0.1"
        self.systemInfoService?.applicationName = applicationName
        self.systemInfoService?.applicationVersionNumber = applicationVersionNumber
        let applicationIdentifierNoBuildNumber = "\(applicationName) \(applicationVersionNumber)"
        metricsBuilder?.addDeviceData()
        let metricsNoVersion = metricsBuilder?.build()
        XCTAssertEqual(metricsNoVersion?.appId, applicationIdentifierNoBuildNumber)
    }
    
    func testAddDeviceDataNoNameOrBuild() {
        let applicationVersionNumber = "1.0.1"
        self.systemInfoService?.applicationVersionNumber = applicationVersionNumber
        let appIDNoNameOrBuild = "\(applicationVersionNumber)"
        metricsBuilder?.addDeviceData()
        let metricsNoNameOrBuild = metricsBuilder?.build()
        XCTAssertEqual(metricsNoNameOrBuild?.appId, appIDNoNameOrBuild)
    }
    
    func testAddDeviceDataNoNameOrVersion() {
        let applicationBuildNumber = "12C33"
        self.systemInfoService?.applicationBuildNumber = applicationBuildNumber
        let appIDNoNameOrVersion = "(\(applicationBuildNumber))"
        metricsBuilder?.addDeviceData()
        let metricsNoNameOrVersion = metricsBuilder?.build()
        XCTAssertEqual(metricsNoNameOrVersion?.appId, appIDNoNameOrVersion)
    }
    
    func testAddDeviceDataNoBuildOrVersion() {
        let applicationName = "testAppName"
        self.systemInfoService?.applicationName = applicationName
        self.systemInfoService?.applicationBuildNumber = nil
        self.systemInfoService?.applicationVersionNumber = nil
        let appIDNoBuildOrVersion = "\(applicationName)"
        metricsBuilder?.addDeviceData()
        let metricsNoBuildOrVersion = metricsBuilder?.build()
        XCTAssertEqual(metricsNoBuildOrVersion?.appId, appIDNoBuildOrVersion)
    }
    
}

fileprivate class FakeDataStore: NamedCollectionDataStore {
    
    var setIntCalled = false
    var setIntValues: [Int?] = []
    override func set(key: String, value: Int?) {
        setIntCalled = true
        setIntValues.append(value)
    }
    
    var getIntValues: [Int] = []
    private var getIntCallCount = 0
    override func getInt(key: String, fallback: Int? = nil) -> Int? {
        getIntCallCount += 1
        if getIntCallCount == 0 || getIntValues.count == 0 { return nil }
        return getIntValues[getIntCallCount - 1]
    }
    
    var setObjectCalled = false
    var setObjectValues: [Any] = []
    override func setObject<T>(key: String, value: T) where T : Decodable, T : Encodable {
        setObjectCalled = true
        setObjectValues.append(value)
    }
    
    
    var getObjectValues: [Any] = []
    private var getObjectCallCount = 0
    override func getObject<T>(key: String, fallback: T? = nil) -> T? where T : Decodable, T : Encodable {
        getObjectCallCount += 1
        if getObjectCallCount == 0 || getObjectValues.count == 0 { return nil }
        return getObjectValues[getObjectCallCount - 1] as? T
    }
}

