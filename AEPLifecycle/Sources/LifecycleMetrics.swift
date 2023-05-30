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

extension Date {
    private static var sdfDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        formatter.locale = Locale(identifier: "en_US")

        return formatter
    }

    func toSdfString() -> String {
        return Date.sdfDateFormatter.string(from: self)
    }

    static func fromSdfString(sdfString: String) -> Date? {
        return sdfDateFormatter.date(from: sdfString)
    }
}

/// A well-typed struct representing Lifecycle data
struct LifecycleMetrics: Equatable {
    var installEvent: Bool?
    var launchEvent: Bool?
    var crashEvent: Bool?
    var upgradeEvent: Bool?
    var dailyEngagedEvent: Bool?
    var monthlyEngagedEvent: Bool?
    var installDate: Date?
    var launches: Int?
    var daysSinceFirstLaunch: Int?
    var daysSinceLastLaunch: Int?
    var hourOfTheDay: Int?
    var dayOfTheWeek: Int?
    var operatingSystem: String?
    var appId: String?
    var daysSinceLastUpgrade: Int?
    var launchesSinceUpgrade: Int?
    var deviceName: String?
    var deviceResolution: String?
    var carrierName: String?
    var locale: String?
    var systemLocale: String?
    var runMode: String?
    var previousOsVersion: String?
    var previousAppId: String?

    init() {}
}

extension LifecycleMetrics {
    enum CodingKeys: String, CodingKey {
        case installEvent = "installevent"
        case launchEvent = "launchevent"
        case crashEvent = "crashevent"
        case upgradeEvent = "upgradeevent"
        case dailyEngagedEvent = "dailyenguserevent"
        case monthlyEngagedEvent = "monthlyenguserevent"
        case installDate = "installdate"
        case launches
        case daysSinceFirstLaunch = "dayssincefirstuse"
        case daysSinceLastLaunch = "dayssincelastuse"
        case hourOfTheDay = "hourofday"
        case dayOfTheWeek = "dayofweek"
        case operatingSystem = "osversion"
        case appId = "appid"
        case daysSinceLastUpgrade = "dayssincelastupgrade"
        case launchesSinceUpgrade = "launchessinceupgrade"
        case deviceName = "devicename"
        case deviceResolution = "resolution"
        case carrierName = "carriername"
        case locale
        case systemLocale = "systemlocale"
        case runMode = "runmode"
        case previousOsVersion = "previousosversion"
        case previousAppId = "previousappid"
    }
}

extension LifecycleMetrics: Encodable {
    static let DAILY_ENG_USER_EVENT = "DailyEngUserEvent"
    static let MONTHLY_ENG_USER_EVENT = "MonthlyEngUserEvent"
    static let INSTALL_EVENT = "InstallEvent"
    static let UPGRADE_EVENT = "UpgradeEvent"
    static let CRASH_EVENT = "CrashEvent"
    static let LAUNCH_EVENT = "LaunchEvent"

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if installEvent ?? false { try container.encode(LifecycleMetrics.INSTALL_EVENT, forKey: .installEvent) }
        if launchEvent ?? false { try container.encode(LifecycleMetrics.LAUNCH_EVENT, forKey: .launchEvent) }
        if crashEvent ?? false { try container.encode(LifecycleMetrics.CRASH_EVENT, forKey: .crashEvent) }
        if upgradeEvent ?? false { try container.encode(LifecycleMetrics.UPGRADE_EVENT, forKey: .upgradeEvent) }
        if dailyEngagedEvent ?? false { try container.encode(LifecycleMetrics.DAILY_ENG_USER_EVENT, forKey: .dailyEngagedEvent) }
        if monthlyEngagedEvent ?? false { try container.encode(LifecycleMetrics.MONTHLY_ENG_USER_EVENT, forKey: .monthlyEngagedEvent) }
        if let unwrapped = installDate { try container.encode(unwrapped.toSdfString(), forKey: .installDate) }
        if let unwrapped = launches { try container.encode(String(unwrapped), forKey: .launches) }
        if let unwrapped = daysSinceFirstLaunch { try container.encode(String(unwrapped), forKey: .daysSinceFirstLaunch) }
        if let unwrapped = daysSinceLastLaunch { try container.encode(String(unwrapped), forKey: .daysSinceLastLaunch) }
        if let unwrapped = hourOfTheDay { try container.encode(String(unwrapped), forKey: .hourOfTheDay) }
        if let unwrapped = dayOfTheWeek { try container.encode(String(unwrapped), forKey: .dayOfTheWeek) }
        if let unwrapped = operatingSystem { try container.encode(unwrapped, forKey: .operatingSystem) }
        if let unwrapped = appId { try container.encode(unwrapped, forKey: .appId) }
        if let unwrapped = daysSinceLastUpgrade { try container.encode(String(unwrapped), forKey: .daysSinceLastUpgrade) }
        if let unwrapped = launchesSinceUpgrade { try container.encode(String(unwrapped), forKey: .launchesSinceUpgrade) }
        if let unwrapped = deviceName { try container.encode(unwrapped, forKey: .deviceName) }
        if let unwrapped = deviceResolution { try container.encode(unwrapped, forKey: .deviceResolution) }
        if let unwrapped = carrierName { try container.encode(unwrapped, forKey: .carrierName) }
        if let unwrapped = locale { try container.encode(unwrapped, forKey: .locale) }
        if let unwrapped = systemLocale { try container.encode(unwrapped, forKey: .systemLocale) }
        if let unwrapped = runMode { try container.encode(unwrapped, forKey: .runMode) }
        if let unwrapped = previousOsVersion { try container.encode(unwrapped, forKey: .previousOsVersion) }
        if let unwrapped = previousAppId { try container.encode(unwrapped, forKey: .previousAppId) }
    }
}

extension LifecycleMetrics: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        installEvent = (try? values.decode(String?.self, forKey: .installEvent) != nil) ?? nil
        launchEvent = (try? values.decode(String?.self, forKey: .launchEvent) != nil) ?? nil
        crashEvent = (try? values.decode(String?.self, forKey: .crashEvent) != nil) ?? nil
        upgradeEvent = (try? values.decode(String?.self, forKey: .upgradeEvent) != nil) ?? nil
        dailyEngagedEvent = (try? values.decode(String?.self, forKey: .dailyEngagedEvent) != nil) ?? nil
        monthlyEngagedEvent = (try? values.decode(String?.self, forKey: .monthlyEngagedEvent) != nil) ?? nil
        if let sdfDateString = try? values.decode(String?.self, forKey: .installDate) {
            installDate = Date.fromSdfString(sdfString: sdfDateString)
        }

        if let unwrapped = try? values.decode(String?.self, forKey: .launches) { launches = Int(unwrapped) }
        if let unwrapped = try? values.decode(String?.self, forKey: .daysSinceFirstLaunch) { daysSinceFirstLaunch = Int(unwrapped) }
        if let unwrapped = try? values.decode(String?.self, forKey: .daysSinceLastLaunch) { daysSinceLastLaunch = Int(unwrapped) }
        if let unwrapped = try? values.decode(String?.self, forKey: .hourOfTheDay) { hourOfTheDay = Int(unwrapped) }
        if let unwrapped = try? values.decode(String?.self, forKey: .dayOfTheWeek) { dayOfTheWeek = Int(unwrapped) }
        operatingSystem = try? values.decode(String?.self, forKey: .operatingSystem)
        appId = try? values.decode(String?.self, forKey: .appId)
        if let unwrapped = try? values.decode(String?.self, forKey: .daysSinceLastUpgrade) { daysSinceLastUpgrade = Int(unwrapped) }
        if let unwrapped = try? values.decode(String?.self, forKey: .launchesSinceUpgrade) { launchesSinceUpgrade = Int(unwrapped) }
        deviceName = try? values.decode(String?.self, forKey: .deviceName)
        deviceResolution = try? values.decode(String?.self, forKey: .deviceResolution)
        carrierName = try? values.decode(String?.self, forKey: .carrierName)
        locale = try? values.decode(String?.self, forKey: .locale)
        systemLocale = try? values.decode(String?.self, forKey: .systemLocale)
        runMode = try? values.decode(String?.self, forKey: .runMode)
        previousOsVersion = try? values.decode(String?.self, forKey: .previousOsVersion)
        previousAppId = try? values.decode(String?.self, forKey: .previousAppId)
    }
}
