/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import AEPServices

/// LifecycleV2MetricsBuilder collects metrics in XDM format, to be sent as two XDM events for mobile application launch and application close.
/// Refer to the Mobile App Lifecycle Details field group, which includes:
///  - XDM Environment datatype
///  - XMD Device datatype
///  - XDM Application datatype
class LifecycleV2MetricsBuilder {

    private var xdmDeviceInfo: XDMDevice?
    private var xdmEnvironmentInfo: XDMEnvironment?

    private var systemInfoService: SystemInfoService {
        return ServiceProvider.shared.systemInfoService
    }

    /// Builds the data required for the XDM Application Launch event, including `XDMApplication`
    /// `XDMEnvironment` and `XDMDevice` info.
    /// - Returns: App launch event data in dictionary format
    func buildAppLaunchXDMData(launchDate: Date, isInstall: Bool, isUpgrade: Bool) -> [String: Any]? {
        var appLaunchXDMData = XDMMobileLifecycleDetails()
        appLaunchXDMData.application = computeAppLaunchData(isInstall: isInstall, isUpgrade: isUpgrade)
        appLaunchXDMData.device = computeDeviceData()
        appLaunchXDMData.environment = computeEnvironmentData()
        appLaunchXDMData.eventType = LifecycleV2Constants.XDMEventType.APP_LAUNCH
        appLaunchXDMData.timestamp = launchDate

        return appLaunchXDMData.asDictionary()
    }

    /// Builds the data required for the XDM Application Close event, including `XDMApplication`
    /// - Parameters:
    ///    - launchDate: the app launch date
    ///    - closeDate: the app close date
    ///    - fallbackCloseDate: the date to be used as xdm.timestamp for the Close event when `closeDate` is nil
    ///    - isCloseUnknown: indicates if this is a regular or abnormal close event
    /// - Returns: App close event data in dictionary format
    func buildAppCloseXDMData(launchDate: Date?, closeDate: Date?, fallbackCloseDate: Date, isCloseUnknown: Bool) -> [String: Any]? {
        var appCloseXDMData = XDMMobileLifecycleDetails()

        appCloseXDMData.application = computeAppCloseData(launchDate: launchDate, closeDate: closeDate, isCloseUnknown: isCloseUnknown)
        appCloseXDMData.eventType = LifecycleV2Constants.XDMEventType.APP_CLOSE
        appCloseXDMData.timestamp = closeDate ?? fallbackCloseDate

        return appCloseXDMData.asDictionary()
    }

    /// Computes general application information as well as details related to the type of launch (install, upgrade, regular launch)
    /// - Parameters:
    ///   - isInstall: indicates if this is an app install
    ///   - isUpgrade: indicates if this is an app upgrade
    /// - Returns: an `XDMApplication` with the launch information
    private func computeAppLaunchData(isInstall: Bool, isUpgrade: Bool) -> XDMApplication {
        var xdmApplicationInfoLaunch = XDMApplication()
        xdmApplicationInfoLaunch.isLaunch = true

        if isInstall {
            xdmApplicationInfoLaunch.isInstall = true
        } else if isUpgrade {
            xdmApplicationInfoLaunch.isUpgrade = true
        }

        xdmApplicationInfoLaunch.name = systemInfoService.getApplicationName()
        xdmApplicationInfoLaunch.id = systemInfoService.getApplicationBundleId()
        xdmApplicationInfoLaunch.version = LifecycleV2.getAppVersion(systemInfoService: systemInfoService)
        xdmApplicationInfoLaunch.language = XDMLanguage(language: systemInfoService.getActiveLocaleName().bcpFormattedLocale)

        return xdmApplicationInfoLaunch
    }

    /// Computes metrics related to the type of close event. The session length is computed based on the launch and close timestamp values.
    /// The`closeDate` corresponds to the pause event timestamp in normal scenarios or to the last known
    /// close event in case of an abnormal application close.
    ///
    /// - Parameters:
    ///   - launchDate: the app launch timestamp
    ///   - closeDate: the app close timestamp
    ///   - isCloseUnknown: indicates if this is a regular or abnormal close event
    /// - Returns: an `XDMApplication` with the close information
    private func computeAppCloseData(launchDate: Date?, closeDate: Date?, isCloseUnknown: Bool) -> XDMApplication {
        var xdmApplicationInfoClose = XDMApplication()

        xdmApplicationInfoClose.isClose = true
        xdmApplicationInfoClose.closeType = isCloseUnknown ? .unknown : .close
        xdmApplicationInfoClose.sessionLength = computeSessionLength(launchDate: launchDate, closeDate: closeDate)

        return xdmApplicationInfoClose
    }

    /// Returns information related to the running environment. This data is computed once, when it is first used, then
    /// returned from cache.
    /// - Returns: the `XDMEnvironment` info
    private func computeEnvironmentData() -> XDMEnvironment? {
        if let xdmEnvironmentInfo = xdmEnvironmentInfo {
            return xdmEnvironmentInfo
        }

        xdmEnvironmentInfo = XDMEnvironment()
        xdmEnvironmentInfo?.carrier = systemInfoService.getMobileCarrierName()
        xdmEnvironmentInfo?.type = XDMEnvironmentType.from(runMode: systemInfoService.getRunMode())
        xdmEnvironmentInfo?.operatingSystem = systemInfoService.getOperatingSystemName()
        xdmEnvironmentInfo?.operatingSystemVersion = systemInfoService.getOperatingSystemVersion()
        xdmEnvironmentInfo?.language = XDMLanguage(language: systemInfoService.getSystemLocaleName().bcpFormattedLocale)

        return xdmEnvironmentInfo
    }

    /// Returns information related to the device. This data is computed once, when it is first used, then
    /// returned from cache.
    /// - Returns: the `XDMDevice` info
    private func computeDeviceData() -> XDMDevice? {
        if let xdmDeviceInfo = xdmDeviceInfo {
            return xdmDeviceInfo
        }

        xdmDeviceInfo = XDMDevice()

        let displayInfo = systemInfoService.getDisplayInformation()
        xdmDeviceInfo?.screenWidth = Int64(displayInfo.width)
        xdmDeviceInfo?.screenHeight = Int64(displayInfo.height)
        xdmDeviceInfo?.type = XDMDeviceType.from(servicesDeviceType: systemInfoService.getDeviceType())
        xdmDeviceInfo?.model = systemInfoService.getDeviceName()
        xdmDeviceInfo?.modelNumber = systemInfoService.getDeviceModelNumber()
        xdmDeviceInfo?.manufacturer = "apple"

        return xdmDeviceInfo
    }

    /// Computes the session length based on the previous app session launch and close date.
    /// - Parameters:
    ///   - launchDate: last known app launch date
    ///   - closeDate: last known app close date
    /// - Returns: the session length (seconds) or 0 if the session length could not be computed
    private func computeSessionLength(launchDate: Date?, closeDate: Date?) -> Int64 {
        var sessionLength: Int64 = 0
        let launchTS = launchDate?.timeIntervalSince1970 ?? 0
        let closeTS = closeDate?.timeIntervalSince1970 ?? 0

        if launchTS > 0 && closeTS > 0 {
            sessionLength = Int64(closeTS - launchTS)
        }

        return sessionLength > 0 ? sessionLength : 0
    }

}

extension String {

    /// Returns a BCP formatted locale from the calling locale String.
    /// Uses `Locale.identifier(.bcp47)` for iOS 16+, otherwise uses format `Locale.languageCode-Locale.regionCode`.
    /// - Return:  'String' representation of the given 'locale', or nil if no language code is set.
    var bcpFormattedLocale: String? {
        let locale = Locale(identifier: self)

        if #available(iOS 16, tvOS 16, *) {
            return locale.identifier(.bcp47)
        } else {
            if let language = locale.languageCode {
                if let region = locale.regionCode {
                    return "\(language)-\(region)"
                }
                return language
            }

            return nil
        }
    }
}
