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

import AEPServices
import Foundation

// Builds the LifecycleMetricsData and handles Lifecycle metrics data storage updates
class LifecycleMetricsBuilder {
    private var lifecycleMetrics: LifecycleMetrics = LifecycleMetrics()

    private typealias KEYS = LifecycleConstants.DataStoreKeys

    private let dataStore: NamedCollectionDataStore
    private let date: Date

    private var systemInfoService: SystemInfoService {
        ServiceProvider.shared.systemInfoService
    }

    init(dataStore: NamedCollectionDataStore, date: Date) {
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
        lifecycleMetrics.dailyEngagedEvent = true
        lifecycleMetrics.monthlyEngagedEvent = true
        lifecycleMetrics.installEvent = true
        lifecycleMetrics.installDate = date
        return self
    }

    /// Adds the launch data to the lifecycle metrics
    /// Launch Metrics includes:
    /// - Days since first launch
    /// - Days since last launch
    /// - Daily engaged event
    /// - Monthly engaged event
    /// - Previous OS version
    /// - Previous app id
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    @discardableResult
    func addLaunchData(prevOsVersion: String?, prevAppId: String?) -> LifecycleMetricsBuilder {
        if let firstLaunchDate: Date = dataStore.getObject(key: KEYS.INSTALL_DATE) {
            guard let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: date).day else {
                return self
            }

            if daysSinceFirstLaunch >= 0 {
                lifecycleMetrics.daysSinceFirstLaunch = daysSinceFirstLaunch
            }

            lifecycleMetrics.previousOsVersion = prevOsVersion
            lifecycleMetrics.previousAppId = prevAppId
        }

        if let lastLaunchDate: Date = dataStore.getObject(key: KEYS.LAST_LAUNCH_DATE) {
            guard let daysSinceLastLaunch = Calendar.current.dateComponents([.day], from: lastLaunchDate, to: date).day else {
                return self
            }

            if daysSinceLastLaunch >= 0 {
                lifecycleMetrics.daysSinceLastLaunch = daysSinceLastLaunch
            }

            let currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
            let lastLaunchDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: lastLaunchDate)
            // Check if we have launched this month already
            if currentDateComponents.month != lastLaunchDateComponents.month || currentDateComponents.year != lastLaunchDateComponents.year {
                lifecycleMetrics.dailyEngagedEvent = true
                lifecycleMetrics.monthlyEngagedEvent = true
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
    /// - Day of the week
    /// - Hour of the day
    /// Return: `LifecycleMetricsBuilder` returns the mutated builder
    @discardableResult
    func addLaunchEventData() -> LifecycleMetricsBuilder {
        let context: LifecyclePersistedContext? = dataStore.getObject(key: KEYS.PERSISTED_CONTEXT)
        lifecycleMetrics.launches = context?.launches

        let currentDateComponents = Calendar.current.dateComponents([.weekday, .hour], from: date)
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
            dataStore.setObject(key: KEYS.UPGRADE_DATE, value: date)
            dataStore.set(key: KEYS.LAUNCHES_SINCE_UPGRADE, value: 0)
        } else if let upgradeDate: Date = dataStore.getObject(key: KEYS.UPGRADE_DATE) {
            if let daysSinceLastUpgrade = Calendar.current.dateComponents([.day], from: upgradeDate, to: date).day, daysSinceLastUpgrade >= 0 {
                lifecycleMetrics.daysSinceLastUpgrade = daysSinceLastUpgrade
            }
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
    func addCrashData(previousSessionCrash: Bool) -> LifecycleMetricsBuilder {
        if previousSessionCrash {
            lifecycleMetrics.crashEvent = true
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
        lifecycleMetrics.operatingSystem = "\(systemInfoService.getOperatingSystemName()) \(systemInfoService.getOperatingSystemVersion())"
        lifecycleMetrics.locale = systemInfoService.getActiveLocaleName().lifecycleLocaleFormat
        lifecycleMetrics.systemLocale = systemInfoService.getSystemLocaleName().lifecycleLocaleFormat
        lifecycleMetrics.runMode = systemInfoService.getRunMode()

        return self
    }

    // MARK: - Private helper functions

    /// Combines the application name, version, and version code into a formatted application identifier
    /// - Return: `String` formatted Application identifier
    private func getApplicationIdentifier() -> String {
        let applicationName = systemInfoService.getApplicationName() ?? ""
        let applicationVersion = systemInfoService.getApplicationVersionNumber() ?? ""
        let applicationBuildNumber = systemInfoService.getApplicationBuildNumber() ?? ""
        // Make sure that the formatted identifier removes white space if any of the values are empty, and remove the () version wrapper if version is empty as well
        return "\(applicationName) \(applicationVersion) (\(applicationBuildNumber))".replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: "()", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Gets the resolution of the current device
    /// - Return: `String` formatted resolution
    private func getResolution() -> String {
        let displayInfo = systemInfoService.getDisplayInformation()
        return "\(displayInfo.width)x\(displayInfo.height)"
    }
}

extension String {
    /// Gets the formatted locale
    /// - Return: `String` formatted locale
    var lifecycleLocaleFormat: String {
        let locale = Locale(identifier: self)

        if #available(iOS 16, tvOS 16, *) {
            if let language = locale.language.languageCode?.identifier {
                if let region = locale.region?.identifier {
                    return "\(language)-\(region)"
                }
                return language
            }
        } else {
            if let language = locale.languageCode {
                if let region = locale.regionCode {
                    return "\(language)-\(region)"
                }
                return language
            }
        }

        return "en-US"
    }
}
