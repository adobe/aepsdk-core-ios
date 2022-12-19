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
@testable import AEPLifecycle
import AEPServices
import AEPServicesMocks
import XCTest

class LifecycleV2MetricsBuilderTests: XCTestCase {
    private let startDate = Date(milliseconds: 1483889568123)
    private let xdmMetricsBuilder = LifecycleV2MetricsBuilder()
    private let expectedEnvironmentInfo = [
        "carrier": "test-carrier",
        "operatingSystemVersion": "test-os-version",
        "operatingSystem": "test-os-name",
        "type": "application",
        "_dc": ["language": "en-US"]
    ] as [String : Any]
    
    let expectedDeviceInfo = [
        "manufacturer": "apple",
        "model": "test-device-name",
        "modelNumber": "test-device-model",
        "type": "mobile",
        "screenHeight": 200,
        "screenWidth": 100
    ] as [String : Any]
    
    override func setUp() {
        buildAndSetMockInfoService()
        continueAfterFailure = true
    }
    
    private let mockSystemInfoService = MockSystemInfoService()

    private func buildAndSetMockInfoService() {
        //let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.appId = "test-app-id"
        mockSystemInfoService.applicationName = "test-app-name"
        mockSystemInfoService.applicationBuildNumber = "build-number"
        mockSystemInfoService.applicationVersionNumber = "version-number"
        mockSystemInfoService.mobileCarrierName = "test-carrier"
        mockSystemInfoService.platformName = "test-platform"
        mockSystemInfoService.operatingSystemName = "test-os-name"
        mockSystemInfoService.operatingSystemVersion = "test-os-version"
        mockSystemInfoService.deviceName = "test-device-name"
        mockSystemInfoService.deviceModelNumber = "test-device-model"
        mockSystemInfoService.displayInformation = (100, 200)
        mockSystemInfoService.deviceType = .PHONE
        mockSystemInfoService.activeLocaleName = "en_US"
        mockSystemInfoService.runMode = "Application"
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }
    
    func testBuildAppLaunchXDMDataReturnsCorrectDataWhenIsInstall() {
        let actualAppLaunchData = xdmMetricsBuilder.buildAppLaunchXDMData(launchDate: startDate, isInstall: true, isUpgrade: false)
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "version-number (build-number)",
            "isInstall": true,
            "isLaunch": true,
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "environment": expectedEnvironmentInfo,
                        "device": expectedDeviceInfo,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48.123Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildAppLaunchXDMDataReturnsCorrectDataWhenIsUpgradeEvent() {
        let actualAppLaunchData = xdmMetricsBuilder.buildAppLaunchXDMData(launchDate: startDate, isInstall: false, isUpgrade: true)
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "version-number (build-number)",
            "isUpgrade": true,
            "isLaunch": true,
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "environment": expectedEnvironmentInfo,
                        "device": expectedDeviceInfo,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48.123Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildAppLaunchXDMDataReturnsCorrectDataWhenIsLaunch() {
        let actualAppLaunchData = xdmMetricsBuilder.buildAppLaunchXDMData(launchDate: startDate, isInstall: false, isUpgrade: false)
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "version-number (build-number)",
            "isLaunch": true,
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "environment": expectedEnvironmentInfo,
                        "device": expectedDeviceInfo,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48.123Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildAppCloseXDMDataReturnsCorrectDataWhenIsCloseWithCloseUnknown() {
        let actualAppCloseData = xdmMetricsBuilder.buildAppCloseXDMData(
            launchDate: Date(milliseconds: 1483965500201), // start: Sunday, January 8, 2017 8:32:48.201 AM GMT
            closeDate: Date(milliseconds: 1483864390436), // close: Sunday, January 8, 2017 8:33:10.436 AM GMT
            fallbackCloseDate:  Date(milliseconds: 1483864390018), // fallbackClose: Sunday, January 8, 2017 8:33:10.018 AM GMT
            isCloseUnknown: true)
        
        // verify
        let application = [
            "isClose": true,
            "closeType": "unknown",
            "sessionLength": 0
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.close",
                        "timestamp": "2017-01-08T08:33:10.436Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppCloseData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildAppCloseXDMDataReturnsCorrectDataWhenIsCloseIncorrectLifecycleImplementation() {
        let actualAppCloseData = xdmMetricsBuilder.buildAppCloseXDMData(
            launchDate: Date(milliseconds: 1483864368401), // start: Sunday, January 8, 2017 8:32:48.401 AM GMT
            closeDate: nil, fallbackCloseDate: Date(milliseconds: 1483864367804), // start: Sunday, January 8, 2017 8:32:47.804 AM GMT
            isCloseUnknown: true)
        
        // verify
        let application = [
            "isClose": true,
            "closeType": "unknown",
            "sessionLength": 0
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.close",
                        "timestamp": "2017-01-08T08:32:47.804Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppCloseData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildAppCloseXDMDataReturnsCorrectDataWhenIsCloseCorrectSession() {
        let actualAppCloseData = xdmMetricsBuilder.buildAppCloseXDMData(
            launchDate: Date(milliseconds: 1483864368005), // start: Sunday, January 8, 2017 8:32:48.005 AM GMT
            closeDate: Date(milliseconds: 1483864390123), // close: Sunday, January 8, 2017 8:33:10.123 AM GMT
            fallbackCloseDate: Date(milliseconds: 1483864390321), // fallback: Sunday, January 8, 2017 8:33:10.321 AM GMT
            isCloseUnknown: false)
        
        // verify
        let application = [
            "isClose": true,
            "closeType": "close",
            "sessionLength": 22
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.close",
                        "timestamp": "2017-01-08T08:33:10.123Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppCloseData ?? [:]).isEqual(to: expected))
    }
    
    // List of tests for verifying getFormattedLocaleBCPString function
    // [$0: Locale identifier string to test, $1: expected result]
    let localeBCPStringTests = [
        ("es-US", "es-US"), // language + region
        ("en_US", "en-US"), // language + region (underscore)
        ("de", "de"), // language only
        ("-US", nil), // region only
        ("--POSIX", nil), // variant only
        ("und", "und"), // undefined
        ("de-POSIX", "de"), // language + variant
        ("de--POSIX", "de"), // language + variant (double hyphen)
        ("de-DE-POSIX", "de-DE"), // language + region + variant
        ("de-Latn-DE-POSIX", "de-DE"), // language + script + region + variant
        ("zh-Hant-HK", "zh-HK"), // Chinese Hong Kong
        ("zh-Hans-CN", "zh-CN"), // Chinese China
        ("zh-Hans", "zh"), // language + script
        ("-Hans-CN", nil), // script + region
        ("no-NO-NY", "no-NO"), // Norwegian Nynorsk (special case)
        ("sr-Latn-ME", "sr-ME"), // Serbian Montenegro
        ("it-Latn", "it"), // langauge + variant
        ("ja-JP-JP", "ja-JP"), // Japanese (special case)
        ("ja-JP-u-ca-japanese", "ja-JP"), // Japanese calendar BCP
        ("ja-JP@calendar=japanese", "ja-JP"), // Japanese calender ICU
        ("TH-TH-TH", "th-TH"), // Thai (special case)
        ("th-TH-u-ca-buddhist", "th-TH"), // Thai buddhist calendar BCP
        ("th-TH@calendar=buddhist", "th-TH"), // Thai buddhist calendar ICU
        ("en-US@calendar=buddhist", "en-US"), // English US buddhist calendar ICU
        ("en@calendar=buddhist;numbers=thai", "en"), // English buddhist calendar with Thai numbers
        ("i-klingon", "tlh") // Grandfathered case Klingon
    ]
    
    func testGetFormattedLocaleBCPString() {
        XCTAssertFalse(localeBCPStringTests.isEmpty)
        
        localeBCPStringTests.forEach {
            mockSystemInfoService.activeLocaleName = $0
            let result = mockSystemInfoService.getFormattedLocaleBCPString()
                XCTAssertEqual($1, result, "Locale '\($0)' failed!")
        }
    }
    
}

private extension Date {
    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
