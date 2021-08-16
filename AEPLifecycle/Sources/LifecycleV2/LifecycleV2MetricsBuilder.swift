//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation
import AEPServices

/// LifecycleV2MetricsBuilder collects metrics in XDM format, to be sent as two XDM events for mobile application launch and application close.
/// Refer to the Mobile App Lifecycle Details field group, which includes:
///  - XDM Environment datatype
///  - XMD Device datatype
///  - XDM Application datatype
class LifecycleV2MetricsBuilder {
    private let LOG_TAG = "LifecycleV2MetricsBuilder"
    private let startDate: Date
    private var xdmApplicationInfoClose: XDMApplication?
    private var xdmApplicationInfoLaunch: XDMApplication?
    private var xdmDeviceInfo: XDMDevice?
    private var xdmEnvironmentInfo: XDMEnvironment?

    private var systemInfoService: SystemInfoService {
        return ServiceProvider.shared.systemInfoService
    }

    /// Initializer for the Lifecycle metrics builder in XDM format
    /// - Parameter startDate: the app start date
    init(startDate: Date) {
        self.startDate = startDate
    }

    /// Builds the data required for the XDM Application Launch event, including `XDMApplication`
    /// `XDMEnvironment` and `XDMDevice` info.
    /// - Returns: App launch event data in dictionary format
    func buildAppLaunchXDMData() -> [String: Any]? {
        var appLaunchXDMData = XDMLifecycleMobileDetails()
        appLaunchXDMData.application = xdmApplicationInfoLaunch
        appLaunchXDMData.device = xdmDeviceInfo
        appLaunchXDMData.environment = xdmEnvironmentInfo
        appLaunchXDMData.eventType = LifecycleConstants.XDM.EVENT_TYPE_APP_LAUNCH
        appLaunchXDMData.timestamp = startDate

        return appLaunchXDMData.asDictionary()
    }

    /// Builds the data required for the XDM Application Close event, including `XDMApplication`
    /// - Returns: App close event data in dictionary format
    func buildAppCloseXDMData() -> [String: Any]? {
        var appLaunchXDMData = XDMLifecycleMobileDetails()
        appLaunchXDMData.application = xdmApplicationInfoClose
        appLaunchXDMData.eventType = LifecycleConstants.XDM.EVENT_TYPE_APP_CLOSE
        appLaunchXDMData.timestamp = startDate

        // TODO: MOB-14370 backdate timestamp

        return appLaunchXDMData.asDictionary()
    }

    /// Adds general application information as well as details related to the type of launch (install, upgrade, regular launch)
    /// - Parameters:
    ///   - isInstall: indicates if this is an app install
    ///   - isUpgrade: indicates if this is an app upgrade
    /// - Returns: this `LifecycleV2MetricsBuilder` instance
    func addAppLaunchData(isInstall: Bool, isUpgrade: Bool) -> LifecycleV2MetricsBuilder {
        xdmApplicationInfoLaunch = XDMApplication()
        xdmApplicationInfoLaunch?.isLaunch = true

        if isInstall {
            xdmApplicationInfoLaunch?.isInstall = true
        }

        if isUpgrade {
            xdmApplicationInfoLaunch?.isUpgrade = true
        }

        xdmApplicationInfoLaunch?.name = systemInfoService.getApplicationName()
        xdmApplicationInfoLaunch?.id = systemInfoService.getApplicationBundleId()
        xdmApplicationInfoLaunch?.version = systemInfoService.getApplicationVersion()

        return self
    }

    /// Adds general application information as well as details related to the type of close event
    /// - Parameters:
    ///   - previousAppId: application version from the previous session when the close happened
    ///   - previousSessionInfo: previous session information to be attached to the close event
    /// - Returns: this `LifecycleV2MetricsBuilder` instance
    func addAppCloseData(previousAppId: String?, previousSessionInfo: LifecycleSessionInfo) -> LifecycleV2MetricsBuilder {
        xdmApplicationInfoClose = XDMApplication()

        // TODO: MOB-14453
        xdmApplicationInfoClose?.version = previousAppId
        xdmApplicationInfoClose?.isClose = true
        xdmApplicationInfoClose?.closeType = previousSessionInfo.isCrash ? .unknown : .close
        if let sessionLength = previousSessionInfo.sessionLength {
            xdmApplicationInfoClose?.sessionLength = Int64(sessionLength)
        }
        xdmApplicationInfoClose?.name = systemInfoService.getApplicationName()
        xdmApplicationInfoClose?.id = systemInfoService.getApplicationBundleId()

        return self
    }

    /// Adds information related to the running environment, see `XDMEnvironment`
    /// - Returns: this `LifecycleV2MetricsBuilder` instance
    func addEnvironmentData() -> LifecycleV2MetricsBuilder {
        xdmEnvironmentInfo = XDMEnvironment()

        xdmEnvironmentInfo?.carrier = systemInfoService.getMobileCarrierName()
        xdmEnvironmentInfo?.type = XDMEnvironmentType.from(runMode: systemInfoService.getRunMode())
        xdmEnvironmentInfo?.operatingSystem = systemInfoService.getOperatingSystemName()
        xdmEnvironmentInfo?.operatingSystemVersion = systemInfoService.getOperatingSystemVersion()
        xdmEnvironmentInfo?.language = XDMLifecycleLanguage(language: systemInfoService.getFormattedLocale())

        return self
    }

    /// Adds information related to the running environment, see `XDMEnvironment`
    /// - Returns: this `LifecycleV2MetricsBuilder` instance
    func addDeviceData() -> LifecycleV2MetricsBuilder {
        xdmDeviceInfo = XDMDevice()

        let displayInfo = systemInfoService.getDisplayInformation()
        xdmDeviceInfo?.screenWidth = Int64(displayInfo.width)
        xdmDeviceInfo?.screenHeight = Int64(displayInfo.height)
        xdmDeviceInfo?.type = XDMDeviceType.from(servicesDeviceType: systemInfoService.getDeviceType())
        xdmDeviceInfo?.model = systemInfoService.getDeviceName()
        xdmDeviceInfo?.modelNumber = systemInfoService.getDeviceModelNumber()
        xdmDeviceInfo?.manufacturer = "apple"

        return self
    }

}
