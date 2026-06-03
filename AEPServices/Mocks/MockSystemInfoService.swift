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

@testable import AEPServices

public class MockSystemInfoService: SystemInfoService {
    public init() {}

    public var deviceType: DeviceType = .PHONE
    public func getDeviceType() -> DeviceType {
        return deviceType
    }

    public var appId:String?
    public func getApplicationBundleId() -> String? {
        return appId
    }

    public var appVersion:String?
    public func getApplicationVersion() -> String? {
        return appVersion
    }

    public var orientation: DeviceOrientation = .LANDSCAPE
    public func getCurrentOrientation() -> DeviceOrientation {
        return orientation
    }

    public var property: String?
    public func getProperty(for _: String) -> String? {
        return property
    }

    public var asset: String?
    public func getAsset(fileName _: String, fileType _: String) -> String? {
        return asset
    }

    public var assetImage: [UInt8]?
    public func getAsset(fileName _: String, fileType _: String) -> [UInt8]? {
        return assetImage
    }

    public var defaultUserAgent = ""
    public func getDefaultUserAgent() -> String {
        return defaultUserAgent
    }

    public var activeLocaleName = ""
    public func getActiveLocaleName() -> String {
        return activeLocaleName
    }

    public var systemLocaleName = ""
    public func getSystemLocaleName() -> String {
        return systemLocaleName
    }

    public var deviceName = ""
    public func getDeviceName() -> String {
        return deviceName
    }

    public var mobileCarrierName: String?
    public func getMobileCarrierName() -> String? {
        return mobileCarrierName
    }

    public var runMode: String = ""
    public func getRunMode() -> String {
        return runMode
    }

    public var applicationName: String?
    public func getApplicationName() -> String? {
        return applicationName
    }

    public var applicationBuildNumber: String?
    public func getApplicationBuildNumber() -> String? {
        return applicationBuildNumber
    }

    public var applicationVersionNumber: String?
    public func getApplicationVersionNumber() -> String? {
        return applicationVersionNumber
    }

    public var operatingSystemName: String = ""
    public func getOperatingSystemName() -> String {
        return operatingSystemName
    }

    public var operatingSystemVersion: String = ""
    public func getOperatingSystemVersion() -> String {
        return operatingSystemVersion
    }

    public var platformName: String = ""
    public func getCanonicalPlatformName() -> String {
        return platformName
    }

    public var displayInformation: (width: Int, height: Int) = (0, 0)
    public func getDisplayInformation() -> (width: Int, height: Int) {
        return displayInformation
    }

    public var deviceModelNumber: String = ""
    public func getDeviceModelNumber() -> String {
        return deviceModelNumber
    }
}
