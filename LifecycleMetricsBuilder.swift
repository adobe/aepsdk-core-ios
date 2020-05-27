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
class LifecycleMetricsBuilder {
    private var lifecycleMetrics: LifecycleMetrics = LifecycleMetrics()
    
    private typealias KEYS = LifecycleConstants.Keys

    private let dataStore: NamedKeyValueStore
    private let date: Date
 
    private var systemInfoService: SystemInfoService {
        get {
            AEPServiceProvider.shared.systemInfoService
        }
    }
    
    init(dataStore: NamedKeyValueStore, date: Date) {
        self.dataStore = dataStore
        self.date = date
    }
    
    /// Builds the LifecycleMetrics
    /// - Return: `LifecycleMetrics` as they are upon building
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
    @discardableResult
    func addInstallData() -> LifecycleMetricsBuilder {
        self.lifecycleMetrics.dailyEngagedEvent = true
        self.lifecycleMetrics.monthlyEngagedEvent = true
        self.lifecycleMetrics.installEvent = true
        self.lifecycleMetrics.installDate = date
        self.dataStore.setObject(key: KEYS.INSTALL_DATE, value: date)
        return self
    }
    
    /// Adds the launch data to the lifecycle metrics 
    /// Launch Metrics includes:
    /// - Daily engaged event
    /// - Monthly engaged event
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    @discardableResult
    func addLaunchData() -> LifecycleMetricsBuilder {
        if let firstLaunchDate: Date = self.dataStore.getObject(key: KEYS.INSTALL_DATE) {
            guard let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: self.date).day else {
                return self
            }
            
            lifecycleMetrics.daysSinceFirstLaunch = daysSinceFirstLaunch
        }
        
        if let lastLaunchDate: Date = self.dataStore.getObject(key: KEYS.LAST_LAUNCH_DATE) {
            guard let daysSinceLastLaunch = Calendar.current.dateComponents([.day], from: lastLaunchDate, to: self.date).day else {
                return self
            }
            
            lifecycleMetrics.daysSinceLastLaunch = daysSinceLastLaunch
            let currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self.date)
            let lastLaunchDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: lastLaunchDate)
            // Check if we have launched this month already
            if currentDateComponents.month != lastLaunchDateComponents.month || currentDateComponents.year != lastLaunchDateComponents.year {
                self.lifecycleMetrics.dailyEngagedEvent = true
                self.lifecycleMetrics.monthlyEngagedEvent = true
            } else if currentDateComponents.day != lastLaunchDateComponents.day {
                lifecycleMetrics.dailyEngagedEvent = true
            }
        }
        
        return self
    }
    
    /// Adds the launch count, event, and time data to the lifecycle metrics
    /// Launch event and time data includes:
    /// - Launches
    /// - Launch event
    /// - Day off the week
    /// - Hour of the day
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    @discardableResult
    func addLaunchEventData() -> LifecycleMetricsBuilder {
        if let launches = dataStore.getInt(key: KEYS.LAUNCHES) {
            lifecycleMetrics.launches = launches
        }
        
        let currentDateComponents = Calendar.current.dateComponents([.weekday, .hour], from: self.date)
        lifecycleMetrics.launchEvent = true
        lifecycleMetrics.dayOfTheWeek = currentDateComponents.weekday
        lifecycleMetrics.hourOfTheDay = currentDateComponents.hour
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
    @discardableResult
    func addUpgradeData(upgrade: Bool) -> LifecycleMetricsBuilder {
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
    @discardableResult
    func addCrashData(previousSessionCrash: Bool, osVersion: String, appId: String) -> LifecycleMetricsBuilder {
        if previousSessionCrash {
            lifecycleMetrics.crashEvent = true
            lifecycleMetrics.previousOsVersion = osVersion
            lifecycleMetrics.previousAppId = appId
        }
        return self
    }
    
    /// Adds the device data to the lifecycle metrics
    /// Core data includes:
    /// - Device name
    /// - Carrier name
    /// - App id
    /// - Device resolution
    /// - Operating System
    /// - Locale
    /// - Run mode
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    @discardableResult
    func addDeviceData() -> LifecycleMetricsBuilder {
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
        lifecycleMetrics.locale = getLocale()
        lifecycleMetrics.runMode = systemInfoService.getRunMode()

        return self
    }
    
    /// MARK: - Private helper functions
    /// Combines the application name, version, and version code into a formatted application identifier
    /// - Return: `String` formatted Application identifier
    private func getApplicationIdentifier() -> String {
        let applicationName = systemInfoService.getApplicationName() ?? ""
        let applicationVersion = systemInfoService.getApplicationBuildNumber() ?? ""
        let applicationVersionCode = systemInfoService.getApplicationVersionNumber() ?? ""
        // Make sure that the formatted identifier removes white space if any of the values are empty, and remove the () version wrapper if version is empty as well
        return "\(applicationName) \(applicationVersion) (\(applicationVersionCode))".replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: "()", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Gets the resolution of the current device
    /// - Return: `String` formatted resolution
    private func getResolution() -> String {
        let displayInfo = systemInfoService.getDisplayInformation()
        return "\(displayInfo.widthPixels)x\(displayInfo.heightPixels)"
    }
    
    /// Gets the formatted locale
    /// - Return: `String` formatted locale
    private func getLocale() -> String {
        let locale = systemInfoService.getActiveLocaleName()
        return locale.replacingOccurrences(of: "_", with: "-")
    }
}

