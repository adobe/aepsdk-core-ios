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
@testable import AEPCore

class MockSystemInfoService: SystemInfoService {

    var property: String? = nil
    func getProperty(for key: String) -> String? {
        return property
    }
    
    var asset: String? = nil
    func getAsset(fileName: String, fileType: String) -> String? {
        return asset
    }
    
    var assetImage: [UInt8]? = nil
    func getAsset(fileName: String, fileType: String) -> [UInt8]? {
        return assetImage
    }
    
    var defaultUserAgent = ""
    func getDefaultUserAgent() -> String {
        return defaultUserAgent
    }
    
    var activeLocaleName = ""
    func getActiveLocaleName() -> String {
        return activeLocaleName
    }
    
    var deviceName = ""
    func getDeviceName() -> String {
        return deviceName
    }
    
    var mobileCarrierName: String? = nil
    func getMobileCarrierName() -> String? {
        return mobileCarrierName
    }
    
    var runMode: String = ""
    func getRunMode() -> String {
        return runMode
    }
    
    var applicationName: String? = nil
    func getApplicationName() -> String? {
        return applicationName
    }
    
    var applicationBuildNumber: String? = nil
    func getApplicationBuildNumber() -> String? {
        return applicationBuildNumber
    }
    
    var applicationVersionNumber: String? = nil
    func getApplicationVersionNumber() -> String? {
        return applicationVersionNumber
    }
    
    var operatingSystemName: String = ""
    func getOperatingSystemName() -> String {
        return operatingSystemName
    }
    
    var displayInformation: DisplayInformation = NativeDisplayInformation()
    func getDisplayInformation() -> DisplayInformation {
        return displayInformation
    }
    
}
