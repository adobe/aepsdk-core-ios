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

#if os(iOS)
    import CoreTelephony
#endif
import Foundation
import UIKit

/// The Core system info service implementation which provides
///     - network connection status
///     - bundled properties
///     - bundled assets
///     - TBD as WIP as of now, holds required functionality for ConfigurationExtension
class ApplicationSystemInfoService: SystemInfoService {

    private let DEFAULT_LOCALE = "en-US"

    private let bundle: Bundle

    private let queue = DispatchQueue(label: "com.adobe.applicationSystemInfoService.queue")

    private lazy var userAgent: String = {
        let model = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let localeIdentifier = getSystemLocaleName().userAgentLocale ?? DEFAULT_LOCALE

        return "Mozilla/5.0 (\(model); CPU OS \(osVersion) like Mac OS X; \(localeIdentifier))"
    }()

    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }

    func getProperty(for key: String) -> String? {
        return bundle.object(forInfoDictionaryKey: key) as? String
    }

    func getAsset(fileName: String, fileType: String) -> String? {
        if fileName.isEmpty {
            return nil
        }

        if let filePath = bundle.path(forResource: fileName, ofType: fileType) {
            return try? String(contentsOfFile: filePath)
        }

        return nil
    }

    func getAsset(fileName: String, fileType: String) -> [UInt8]? {
        if fileName.isEmpty {
            return nil
        }

        if let filePath = bundle.path(forResource: fileName, ofType: fileType) {
            guard let data = NSData(contentsOfFile: filePath) else { return nil }
            return [UInt8](data)
        }

        return nil
    }

    func getDefaultUserAgent() -> String {
        // Ensure the lazy variable is initialized correctly during concurrent API calls.
        queue.sync {
            return userAgent
        }
    }

    func getActiveLocaleName() -> String {
        return Locale.autoupdatingCurrent.identifier
    }

    func getSystemLocaleName() -> String {
        if #available(iOS 16, tvOS 16, *) {
            var systemLocaleComponents = Locale.Components(locale: Locale.autoupdatingCurrent)
            let preferredLanguageComponents = Locale.Language.Components(identifier: Locale.preferredLanguages.first ?? DEFAULT_LOCALE)

            systemLocaleComponents.languageComponents = preferredLanguageComponents

            return Locale(components: systemLocaleComponents).identifier
        } else {
            return Locale.preferredLanguages.first ?? DEFAULT_LOCALE
        }
    }

    func getDeviceName() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    func getMobileCarrierName() -> String? {
        #if targetEnvironment(macCatalyst) || os(tvOS)
            return "unknown"
        #else
            let networkInfo = CTTelephonyNetworkInfo()
            let carrier: CTCarrier?
            if #available(iOS 12, *) {
                carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
            } else {
                carrier = networkInfo.subscriberCellularProvider
            }

            return carrier?.carrierName
        #endif
    }

    func getRunMode() -> String {
        guard let executablePath = bundle.executablePath else {
            return "Application"
        }
        if executablePath.contains(".appex/") {
            return "Extension"
        } else {
            return "Application"
        }
    }

    func getApplicationName() -> String? {
        guard let infoDict = bundle.infoDictionary,
              let appName = infoDict["CFBundleName"] as? String ?? infoDict["CFBundleDisplayName"] as? String else {
            return nil
        }

        return appName
    }

    func getApplicationBuildNumber() -> String? {
        return bundle.infoDictionary?["CFBundleVersion"] as? String
    }

    func getApplicationVersionNumber() -> String? {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    func getOperatingSystemName() -> String {
        return UIDevice.current.systemName
    }

    func getOperatingSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }

    func getCanonicalPlatformName() -> String {
        #if os(iOS)
            return "ios"
        #elseif os(tvOS)
            return "tvos"
        #endif
    }

    func getDisplayInformation() -> (width: Int, height: Int) {
        let displayInfo = NativeDisplayInformation()
        return (displayInfo.widthPixels, displayInfo.heightPixels)
    }

    func getDeviceType() -> DeviceType {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .PHONE
        case .pad:
            return .PAD
        case .tv:
            return .TV
        case .carPlay:
            return .CARPLAY
        case .unspecified:
            return .UNKNOWN
        default:
            return .UNKNOWN
        }
    }

    func getApplicationBundleId() -> String? {
        return Bundle.main.bundleIdentifier
    }

    func getApplicationVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    func getCurrentOrientation() -> DeviceOrientation {
        #if os(iOS)
            if UIDevice.current.orientation.isPortrait {return .PORTRAIT}
            if UIDevice.current.orientation.isLandscape {return .LANDSCAPE}
        #endif
        return .UNKNOWN
    }

    func getDeviceModelNumber() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

struct NativeDisplayInformation {
    private var screenRect: CGRect {
        UIScreen.main.bounds
    }

    private var screenScale: CGFloat {
        UIScreen.main.scale
    }

    var widthPixels: Int {
        Int(screenRect.size.width * screenScale)
    }

    var heightPixels: Int {
        Int(screenRect.size.height * screenScale)
    }
}

extension String {
    var userAgentLocale: String? {
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

        return nil
    }
}
