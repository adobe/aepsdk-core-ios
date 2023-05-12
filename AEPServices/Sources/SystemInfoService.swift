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

/// This service provides system info as needed
public protocol SystemInfoService {
    /// Gets a system property for the given key
    ///  - Parameter key: The key to be used to get the property value
    ///  - Return: `String` representation of the property
    func getProperty(for key: String) -> String?

    /// Gets a system asset for the given path
    ///  - Parameter fileName: The asset's name
    ///  - Parameter fileType: The file's extension e.g "txt", "json"
    ///  - Return: `String?` representation of the asset,
    func getAsset(fileName: String, fileType: String) -> String?

    /// Gets a system asset for the given path
    ///  - Parameter fileName: The asset's name
    ///  - Parameter fileType: The file's extension e.g "txt", "json"
    ///  - Return: `[UInt8]?` representation of the asset
    func getAsset(fileName: String, fileType: String) -> [UInt8]?

    /// Gets the device name
    /// - Return: `String` the device name
    func getDeviceName() -> String

    /// Gets the mobile carrier name
    /// - Return: `String` the mobile carrier name
    func getMobileCarrierName() -> String?

    /// Gets the run mode (Extension, or Application) as a string
    /// - Return: `String` the run mode as a string
    func getRunMode() -> String

    /// Gets the application name
    /// - Return: `String` the application name
    func getApplicationName() -> String?

    /// Gets the application's build number
    /// - Return: `String` the application's build number
    func getApplicationBuildNumber() -> String?

    /// Gets the application's version number
    /// - Return: `String` the application's version number
    func getApplicationVersionNumber() -> String?

    /// Gets the operating system's name
    /// - Return: `String` the operating system's name
    func getOperatingSystemName() -> String

    /// Gets the operating system's version
    /// - Return: `String` the operating system's version
    func getOperatingSystemVersion() -> String

    /// Gets the string representation of the canonical platform name
    /// - Return: `String` the platform name name
    func getCanonicalPlatformName() -> String

    /// Gets the display information for the system
    /// - Return: `DisplayInformation` the system's display information
    func getDisplayInformation() -> (width: Int, height: Int)

    /// Gets the default platform/device user agent
    /// - Return: `String` representing the default user agent
    func getDefaultUserAgent() -> String

    /// Returns the highest preferred locale (as set by the user on the system) that is also supported in the app's localization.
    /// If no matching language is found, the application's default language will be used along with the system's selected region.
    /// - Return: `String` representation of the locale name
    func getActiveLocaleName() -> String

    /// Returns the locale created by combining the device's preferred language and selected region (as set by the user on the system).
    /// - Return: `String` representation of the locale name
    func getSystemLocaleName() -> String

    /// Returns the device type
    /// - Return: `DeviceType` the type of the Apple device
    func getDeviceType() -> DeviceType

    /// Returns the application bundleId.
    /// - Return: `String` Application bundle id
    func getApplicationBundleId() -> String?

    // TODO: - Include planned deprecation version in message
    /// Returns the application version.
    /// - Return: `String` Application version
    @available(*, deprecated, renamed: "getApplicationVersionNumber")
    func getApplicationVersion() -> String?

    /// Returns the current orientation of the device
    /// - Return: `DeviceOrientation` the current orientation of the device
    func getCurrentOrientation() -> DeviceOrientation

    /// Returns the current device model number
    /// - Return: `String` representation of the current model number of the device
    func getDeviceModelNumber() -> String
}

public enum DeviceType {
    case PHONE
    case PAD
    case TV
    case CARPLAY
    case UNKNOWN
}

public enum DeviceOrientation {
    case PORTRAIT
    case LANDSCAPE
    case UNKNOWN
}
