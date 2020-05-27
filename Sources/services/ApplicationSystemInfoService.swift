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
import UIKit
import CoreTelephony

/// The Core system info service implementation which provides
///     - network connection status
///     - bundled properties
///     - bundled assets
///     - TBD as WIP as of now, holds required functionality for ConfigurationExtension
class ApplicationSystemInfoService: SystemInfoService {
    
    private let bundle: Bundle
    private lazy var userAgent: String = {
        let model = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let localeIdentifier = getActiveLocaleName()
        
        return "Mozilla/5.0 (\(model); CPU OS \(osVersion) like Mac OS X; \(localeIdentifier))"
    }()
    
    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }
    
    func getProperty(for key: String) -> String? {
        return self.bundle.object(forInfoDictionaryKey: key) as? String
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
        return userAgent
    }
    
    func getActiveLocaleName() -> String {
        return Locale.autoupdatingCurrent.identifier
    }
    
    func getDeviceName() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    func getMobileCarrierName() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier: CTCarrier?
        if #available(iOS 12, *) {
            carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
        } else {
            carrier = networkInfo.subscriberCellularProvider
        }
        
        return carrier?.carrierName
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
    
    func getDisplayInformation() -> (width: Int, height: Int) {
        let displayInfo = NativeDisplayInformation()
        return (displayInfo.widthPixels, displayInfo.heightPixels)
    }
}

struct NativeDisplayInformation {
    private var screenRect: CGRect {
        get {
            UIScreen.main.bounds
        }
    }
    
    private var screenScale: CGFloat {
        get {
            UIScreen.main.scale
        }
    }
    
    var widthPixels: Int {
        get {
            Int(self.screenRect.size.width * screenScale)
        }
    }
    
    var heightPixels: Int {
        get {
            Int(self.screenRect.size.height * screenScale)
        }
    }
}
