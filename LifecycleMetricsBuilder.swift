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

import Foundation

// Builds the LifecycleMetricsData and handles Lifecycle metrics data storage updates
struct LifecycleMetricsBuilder {
    private var lifecycleMetrics: LifecycleMetrics = LifecycleMetrics()
    private let systemInfoService = AEPServiceProvider.shared.systemInfoService
    
    private typealias KEYS = LifecycleConstants.Keys

    private let dataStore: NamedKeyValueStore
    private let date: Date
    
    init(dataStore: NamedKeyValueStore, date: Date) {
        self.dataStore = dataStore
        self.date = date
    }
        
    func build() -> LifecycleMetrics {
        return lifecycleMetrics
    }
    
    /// Adds install data to the lifecycle metrics and sets the data store lifecycle install date value
    /// Install data includes:
    /// - Daily engaged event
    /// - Monthly engaged event
    /// - Install event
    /// - Install date
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    mutating func addInstallData() -> LifecycleMetricsBuilder {
        self.lifecycleMetrics.dailyEngagedEvent = true
        self.lifecycleMetrics.monthlyEngagedEvent = true
        self.lifecycleMetrics.installEvent = true
        self.lifecycleMetrics.installDate = date
        self.dataStore.setObject(key: KEYS.INSTALL_DATE, value: date)
        return self
    }
    
    /// Adds the launch data to the lifecycle metrics and sets the days since last launch and days since first launch values in the data store.
    /// Launch Metrics includes:
    /// - Daily engaged event
    /// - Monthly engaged event
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    mutating func addLaunchData() -> LifecycleMetricsBuilder {
        guard let lastLaunchDate: Date = self.dataStore.getObject(key: KEYS.LAST_LAUNCH_DATE),
            let firstLaunchDate: Date = self.dataStore.getObject(key: KEYS.FIRST_LAUNCH_DATE) else {
            return self
        }

        guard let daysSinceLastLaunch = Calendar.current.dateComponents([.day], from: lastLaunchDate, to: self.date).day else {
            return self
        }
        
        guard let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: self.date).day else {
            return self
        }
        
        dataStore.set(key: KEYS.DAYS_SINCE_LAST_LAUNCH, value: daysSinceLastLaunch)
        dataStore.set(key: KEYS.DAYS_SINCE_FIRST_LAUNCH, value: daysSinceFirstLaunch)
        
        let currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self.date)
        let lastLaunchDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: lastLaunchDate)
        // Check if we have launched this month already
        if currentDateComponents.month != lastLaunchDateComponents.month || currentDateComponents.year != lastLaunchDateComponents.year {
            self.lifecycleMetrics.dailyEngagedEvent = true
            self.lifecycleMetrics.monthlyEngagedEvent = true
        } else if currentDateComponents.day != lastLaunchDateComponents.day {
            lifecycleMetrics.dailyEngagedEvent = true
        }
        
        return self
    }
    
    /// Adds the generic data to the lifecycle metrics
    /// Generic data includes:
    /// - Launches
    /// - Day off the week
    /// - Hour of the day
    /// - Launch event
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    mutating func addGenericData() -> LifecycleMetricsBuilder {
        if let launches = dataStore.getInt(key: KEYS.LAUNCHES) {
            lifecycleMetrics.launches = launches
        }
        let currentDateComponents = Calendar.current.dateComponents([.weekday, .hour], from: self.date)
        lifecycleMetrics.dayOfTheWeek = currentDateComponents.weekday
        lifecycleMetrics.hourOfTheDay = currentDateComponents.hour
        lifecycleMetrics.launchEvent = true
        return self
    }
    
    /// Adds the upgrade data to the lifecycle metrics, sets the following values to the data store:
    /// - Upgrade date
    /// - Launches since upgrade
    /// Upgrade data added to lifecycle metrics includes:
    /// - Upgrade event
    /// - Days since last upgrade
    /// - Launches since upgrade
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    mutating func addUpgradeData(upgrade: Bool) -> LifecycleMetricsBuilder {
        if upgrade {
            lifecycleMetrics.upgradeEvent = true
        }

        if upgrade {
            dataStore.setObject(key: KEYS.UPGRADE_DATE, value: self.date)
            dataStore.set(key: KEYS.LAUNCHES_SINCE_UPGRADE, value: 0)
        } else if let upgradeDate: Date = dataStore.getObject(key: KEYS.UPGRADE_DATE) {
            let daysSinceLastUpgrade = Calendar.current.dateComponents([.day], from: upgradeDate, to: self.date).day
            lifecycleMetrics.daysSinceLastUpgrade = daysSinceLastUpgrade
            if var launchesSinceUpgrade = dataStore.getInt(key: KEYS.LAUNCHES_SINCE_UPGRADE, fallback: 0) {
                launchesSinceUpgrade += 1
                dataStore.set(key: KEYS.LAUNCHES_SINCE_UPGRADE, value: launchesSinceUpgrade)
                lifecycleMetrics.launchesSinceUpgrade = launchesSinceUpgrade
            }
        }
        return self
    }
    
    /// Adds the crash data to the lifecycle metrics
    /// Crash data includes:
    /// - Crash event
    /// - Previous OS version
    /// - Previous app id
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    mutating func addCrashData(previousSessionCrash: Bool, osVersion: String, appId: String) -> LifecycleMetricsBuilder {
        if previousSessionCrash {
            lifecycleMetrics.crashEvent = true
            lifecycleMetrics.previousOsVersion = osVersion
            lifecycleMetrics.previousAppId = appId
        }
        return self
    }
    
    /// Adds the core data to the lifecycle metrics
    /// Core data includes:
    /// - Device name
    /// - Carrier name
    /// - App id
    /// - Device resolution
    /// - Operating System
    /// - Locale
    /// - Run mode
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    mutating func addCoreData() -> LifecycleMetricsBuilder {
        let deviceName = systemInfoService.getDeviceName()
        if !deviceName.isEmpty {
            lifecycleMetrics.deviceName = deviceName
        }
        
        if let carrierName = systemInfoService.getMobileCarrierName() {
            lifecycleMetrics.carrierName = carrierName
        }
        let applicationIdentifier = getApplicationIdentifier()
        if !applicationIdentifier.isEmpty {
            lifecycleMetrics.appId = applicationIdentifier
        }
        
        lifecycleMetrics.deviceResolution = getResolution()
        lifecycleMetrics.operatingSystem = systemInfoService.getOperatingSystemName()
        lifecycleMetrics.locale = systemInfoService.getActiveLocaleName()
        
        if let runMode = systemInfoService.getRunMode() {
            lifecycleMetrics.runMode = runMode
        }

        return self
    }
    
    /// MARK: - Private helper functions
    /// Combines the application name, verseion, and version code into a formatted application identifier
    /// - Return: `String` formatted Application identifier
    private func getApplicationIdentifier() -> String {
        let applicationName = systemInfoService.getApplicationName() ?? ""
        let applicationVersion = systemInfoService.getApplicationVersion() ?? ""
        let applicationVersionCode = systemInfoService.getApplicationVersionCode() ?? ""
        
        return "\(applicationName) \(applicationVersion) (\(applicationVersionCode))"
    }
    
    /// Gets the resolution of the current device
    /// - Return: `String` formatted resolution
    private func getResolution() -> String {
        let displayInfo = systemInfoService.getDisplayInformation()
        return "\(displayInfo.widthPixels)x\(displayInfo.heightPixels)"
    }
}

