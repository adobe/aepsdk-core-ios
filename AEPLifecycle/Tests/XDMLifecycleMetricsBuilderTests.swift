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
@testable import AEPLifecycle
import AEPServices
import AEPServicesMocks
import XCTest

class XDMLifecycleMetricsBuilderTests: XCTestCase {
    
    let startDate = Date(timeIntervalSince1970: 1483889568)
    
    override func setUp() {
        buildAndSetMockInfoService()
    }
    
    private func buildAndSetMockInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.appId = "test-app-id"
        mockSystemInfoService.applicationName = "test-app-name"
        mockSystemInfoService.appVersion = "test-version"
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
    
    func testBuildXDMAppLaunchEventDataReturnsCorrectDataWhenIsInstall() {
        let actualAppLaunchData = XDMLifecycleMetricsBuilder(startDate: startDate)
            .addAppLaunchData(isInstall: true, isUpgrade: false)
            .buildXDMAppLaunchEventData()
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "test-version",
            "isInstall": true,
            "isLaunch": true,
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildXDMAppLaunchEventDataReturnsCorrectDataWhenIsUpgradeEvent() {
        let actualAppLaunchData = XDMLifecycleMetricsBuilder(startDate: startDate)
            .addAppLaunchData(isInstall: false, isUpgrade: true)
            .buildXDMAppLaunchEventData()
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "test-version",
            "isUpgrade": true,
            "isLaunch": true,
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildXDMAppLaunchEventDataReturnsCorrectDataWhenIsLaunch() {
        let actualAppLaunchData = XDMLifecycleMetricsBuilder(startDate: startDate)
            .addAppLaunchData(isInstall: false, isUpgrade: false)
            .buildXDMAppLaunchEventData()
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "test-version",
            "isLaunch": true,
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildXDMAppLaunchEventDataReturnsCorrectDataWhenEnvironmentData() {
        let actualAppLaunchData = XDMLifecycleMetricsBuilder(startDate: startDate)
            .addEnvironmentData().buildXDMAppLaunchEventData()
        
        // verify
        let environment = [
            "carrier": "test-carrier",
            "operatingSystemVersion": "test-os-version",
            "operatingSystem": "test-os-name",
            "type": "application",
            "_dc": ["language": "en-US"]
        ] as [String : Any]
        
        let expected = ["environment": environment,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildXDMAppLaunchEventDataReturnsCorrectDataWhenDeviceData() {
        let actualAppLaunchData = XDMLifecycleMetricsBuilder(startDate: startDate)
            .addDeviceData().buildXDMAppLaunchEventData()
        
        // verify
        let device = [
            "manufacturer": "apple",
            "model": "test-device-name",
            "modelNumber": "test-device-model",
            "type": "mobile",
            "screenHeight": 200,
            "screenWidth": 100
        ] as [String : Any]
        
        let expected = ["device": device,
                        "eventType": "application.launch",
                        "timestamp": "2017-01-08T15:32:48Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppLaunchData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildXDMAppCloseEventDataReturnsCorrectDataWhenIsCloseCrashEvent() {
        let actualAppCloseData = XDMLifecycleMetricsBuilder(startDate: Date(timeIntervalSince1970: 1483965500))
            .addAppCloseData(previousAppId: "1.10", previousSessionInfo: LifecycleSessionInfo(
                startDate: Date(timeIntervalSince1970: 1483864368), // start: Sunday, January 8, 2017 8:32:48 AM GMT
                pauseDate: Date(timeIntervalSince1970: 1483864129), // pause: Sunday, January 8, 2017 8:28:49 AM GMT (before start, simulate incorrect app close)
                isCrash: true)).buildAppCloseXDMEventData()
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "1.10",
            "isClose": true,
            "closeType": "unknown",
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.close",
                        "timestamp": "2017-01-09T12:38:20Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppCloseData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildXDMAppCloseEventDataReturnsCorrectDataWhenIsCloseIncorrectLifecycleImplementation() {
        // new start: Monday January 9, 2017 12:38:20 PM GMT
        let actualAppCloseData = XDMLifecycleMetricsBuilder(startDate: Date(timeIntervalSince1970: 1483965500))
            .addAppCloseData(previousAppId: "1.10", previousSessionInfo: LifecycleSessionInfo(
                startDate: Date(timeIntervalSince1970: 1483864368), // start: Sunday, January 8, 2017 8:32:48 AM GMT
                pauseDate: Date(timeIntervalSince1970: 0), // simulate Lifecycle pause not implemented
                isCrash: true)).buildAppCloseXDMEventData()
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "1.10",
            "isClose": true,
            "closeType": "unknown",
            "id": "test-app-id"
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.close",
                        "timestamp": "2017-01-09T12:38:20Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppCloseData ?? [:]).isEqual(to: expected))
    }
    
    func testBuildXDMAppCloseEventDataReturnsCorrectDataWhenIsCloseCorrectSession() {
        let actualAppCloseData = XDMLifecycleMetricsBuilder(startDate: Date(timeIntervalSince1970: 1483965500))
            .addAppCloseData(previousAppId: "1.10", previousSessionInfo: LifecycleSessionInfo(
                startDate: Date(timeIntervalSince1970: 1483864368), // start: Sunday, January 8, 2017 8:32:48 AM GMT
                pauseDate: Date(timeIntervalSince1970: 1483864390), // pause: Sunday, January 8, 2017 8:33:10 AM GMT
                isCrash: false)).buildAppCloseXDMEventData()
        
        // verify
        let application = [
            "name": "test-app-name",
            "version": "1.10",
            "isClose": true,
            "closeType": "close",
            "id": "test-app-id",
            "sessionLength": 22
        ] as [String : Any]
        
        let expected = ["application": application,
                        "eventType": "application.close",
                        "timestamp": "2017-01-09T12:38:20Z"] as [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: actualAppCloseData ?? [:]).isEqual(to: expected))
    }    
}
