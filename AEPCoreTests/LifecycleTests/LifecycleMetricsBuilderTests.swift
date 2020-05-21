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

class LifecycleMetricsBuilderTests: XCTestCase {
    
    private var dataStore: FakeDataStore?
    private var metricsBuilder: LifecycleMetricsBuilder?
    private var systemInfoService: MockSystemInfoService?
    private var date: Date = Date()
    private typealias KEYS = LifecycleConstants.Keys
    
    override func setUp() {
        self.systemInfoService = MockSystemInfoService()
        AEPServiceProvider.shared.systemInfoService = self.systemInfoService!
        self.dataStore = FakeDataStore(name: "testStore")
        self.metricsBuilder = LifecycleMetricsBuilder(dataStore: self.dataStore!, date: self.date)
    }
    
    override func tearDown() {
        dataStore?.removeAll()
        metricsBuilder = nil
    }
    
    func testAddInstallData() {
        let _ = metricsBuilder?.addInstallData()
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
        dataStore?.getObjectValues.append(lastLaunchDate!)
        dataStore?.getObjectValues.append(firstLaunchDate!)
        
        let _ = metricsBuilder?.addLaunchData()
        let metrics = metricsBuilder?.build()
        // Check that the "daysSinceLastLaunch" and "daysSinceFirstLaunch" values are correct
        XCTAssertEqual(dataStore?.setIntValues[0], 1)
        XCTAssertEqual(dataStore?.setIntValues[1], 2)
        
        XCTAssertTrue(metrics!.dailyEngagedEvent)
        XCTAssertFalse(metrics!.monthlyEngagedEvent)
    }
    
    // Tests add launch data when last launch was a month before this launch
    func testAddLaunchDataDifferentMonth() {
        let lastLaunchDate = Calendar.current.date(byAdding: .month, value: -1, to: self.date)
        let firstLaunchDate = Calendar.current.date(byAdding: .day, value: -1, to: lastLaunchDate!)
        dataStore?.getObjectValues.append(lastLaunchDate!)
        dataStore?.getObjectValues.append(firstLaunchDate!)
        
        let _ = metricsBuilder?.addLaunchData()
        let metrics = metricsBuilder?.build()
        // Check that the "daysSinceLastLaunch" and "daysSinceFirstLaunch" values are correct when last launch was a month prior, and first launch was one day before that
        XCTAssertEqual(dataStore?.setIntValues[0], 30)
        XCTAssertEqual(dataStore?.setIntValues[1], 31)
        
        XCTAssertTrue(metrics!.dailyEngagedEvent)
        XCTAssertTrue(metrics!.monthlyEngagedEvent)
    }
    
    func testAddGenericDataWithLaunches() {
        let numberOfLaunches = 1
        dataStore?.getIntValues.append(numberOfLaunches)
        let currentDateComponents = Calendar.current.dateComponents([.weekday, .hour], from: self.date)
        
        let _ = metricsBuilder?.addGenericData()
        let metrics = metricsBuilder?.build()
        
        XCTAssertEqual(metrics?.launches, numberOfLaunches)
        XCTAssertEqual(metrics?.dayOfTheWeek, currentDateComponents.weekday)
        XCTAssertEqual(metrics?.hourOfTheDay, currentDateComponents.hour)
        XCTAssertTrue(metrics!.launchEvent)
    }
    
    func testAddGenericDataWithoutLaunches() {
        let currentDateComponents = Calendar.current.dateComponents([.weekday, .hour], from: self.date)
        
        let _ = metricsBuilder?.addGenericData()
        let metrics = metricsBuilder?.build()
        
        XCTAssertNil(metrics?.launches)
        XCTAssertEqual(metrics?.dayOfTheWeek, currentDateComponents.weekday)
        XCTAssertEqual(metrics?.hourOfTheDay, currentDateComponents.hour)
        XCTAssertTrue(metrics!.launchEvent)
    }
    
    func testAddUpgradeDataWithUpgrade() {
        let _ = metricsBuilder?.addUpgradeData(upgrade: true)
        let metrics = metricsBuilder?.build()
        
        XCTAssertTrue(metrics!.upgradeEvent)
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
        let _ = metricsBuilder?.addCrashData(previousSessionCrash: previousSessionCrash, osVersion: osVersion, appId: appID)
        let metrics = metricsBuilder?.build()
        XCTAssertEqual(metrics?.crashEvent, previousSessionCrash)
        XCTAssertEqual(metrics?.previousOsVersion, osVersion)
        XCTAssertEqual(metrics?.previousAppId, appID)
    }
    
    func testAddCoreData() {
        let deviceName = "testDevice"
        self.systemInfoService?.deviceName = deviceName
        let mobileCarrierName = "testCarrier"
        self.systemInfoService?.mobileCarrierName = mobileCarrierName
        let applicationName = "testAppName"
        self.systemInfoService?.applicationName = applicationName
        let applicationVersion = "1.0.1"
        self.systemInfoService?.applicationVersion = applicationVersion
        let applicationVersionCode = "1.0.0"
        self.systemInfoService?.applicationVersionCode = applicationVersionCode
        let applicationIdentifier = "\(applicationName) \(applicationVersion) (\(applicationVersionCode))"
        let operatingSystemName = "iOS"
        self.systemInfoService?.operatingSystemName = operatingSystemName
        let widthPixels = 375
        let heightPixels = 812
        let resolution = "\(widthPixels)x\(heightPixels)"
        let displayInformation = MockDisplayInformation(widthPixels: widthPixels, heightPixels: heightPixels)
        self.systemInfoService?.displayInformation = displayInformation
        let locale = "US"
        self.systemInfoService?.activeLocaleName = locale
        let runMode = "Application"
        self.systemInfoService?.runMode = runMode
        
        let _ = metricsBuilder?.addCoreData()
        let metrics = metricsBuilder?.build()
        XCTAssertEqual(metrics?.deviceName, deviceName)
        XCTAssertEqual(metrics?.carrierName, mobileCarrierName)
        XCTAssertEqual(metrics?.appId, applicationIdentifier)
        XCTAssertEqual(metrics?.deviceResolution, resolution)
        XCTAssertEqual(metrics?.operatingSystem, operatingSystemName)
        XCTAssertEqual(metrics?.locale, locale)
        XCTAssertEqual(metrics?.runMode, runMode)
    }
}

fileprivate struct MockDisplayInformation: DisplayInformation {
    var widthPixels: Int
    var heightPixels: Int
}

fileprivate class FakeDataStore: NamedKeyValueStore {
    
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

