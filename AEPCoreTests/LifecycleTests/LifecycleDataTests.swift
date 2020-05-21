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

import XCTest
@testable import AEPCore

class LifecycleDataUnitTests: XCTestCase {

    var lifecycleData: LifecycleData!
    
    private func fillData() {
        lifecycleData.installEvent = true
        lifecycleData.launchEvent = true
        lifecycleData.crashEvent = true
        lifecycleData.upgradeEvent = true
        lifecycleData.dailyEngagedEvent = true
        lifecycleData.monthlyEngagedEvent = true
        lifecycleData.launches = 10
        lifecycleData.daysSinceFirstLaunch = 20
        lifecycleData.daysSinceLastLaunch = 2
        lifecycleData.hourOfTheDay = 22
        lifecycleData.dayOfTheWeek = 1
        lifecycleData.operatingSystem = "13.0"
        lifecycleData.appId = "some-app-id"
        lifecycleData.daysSinceLastUpgrade = 2
        lifecycleData.launchesSinceUpgrade = 5
        lifecycleData.deviceName = "iPhone X"
        lifecycleData.carrierName = "some-carrier"
        lifecycleData.deviceResolution = "some-res"
        lifecycleData.locale = "en_US"
        lifecycleData.runMode = "Application"
        lifecycleData.previousOsVersion = "10.0"
        lifecycleData.previousAppId = "prev-app-id"

    }
    
    override func setUp() {
        lifecycleData = LifecycleData()
    }

    func testEmptyLifecycleDataTest() {
        // setup
        let expectedString = "{}"
        
        // test
        let data = try? JSONEncoder().encode(lifecycleData)
        let jsonStr = String(data: data!, encoding: .utf8)
        
        // verify
        XCTAssertEqual(expectedString, jsonStr!)
    }
    
    func testFullLifecycleDataEncodedCorrectly() {
        // setup
        fillData()
        let expectedDate = Date()
        lifecycleData.installDate = expectedDate
        
        // test
        let encodedLifecycleData = try? JSONEncoder().encode(lifecycleData)
        let decodedDict = try? JSONDecoder().decode([String: String].self, from: encodedLifecycleData!)
        
        // verify
        XCTAssertEqual(LifecycleData.INSTALL_EVENT, decodedDict?[LifecycleData.CodingKeys.installEvent.rawValue])
        XCTAssertEqual(LifecycleData.LAUNCH_EVENT, decodedDict?[LifecycleData.CodingKeys.launchEvent.rawValue])
        XCTAssertEqual(LifecycleData.CRASH_EVENT, decodedDict?[LifecycleData.CodingKeys.crashEvent.rawValue])
        XCTAssertEqual(LifecycleData.UPGRADE_EVENT, decodedDict?[LifecycleData.CodingKeys.upgradeEvent.rawValue])
        XCTAssertEqual(LifecycleData.DAILY_ENG_USER_EVENT, decodedDict?[LifecycleData.CodingKeys.dailyEngagedEvent.rawValue])
        XCTAssertEqual(LifecycleData.MONTHLY_ENG_USER_EVENT, decodedDict?[LifecycleData.CodingKeys.monthlyEngagedEvent.rawValue])
        XCTAssertEqual(expectedDate.toSdfString(), decodedDict?[LifecycleData.CodingKeys.installDate.rawValue])
        XCTAssertEqual(String(lifecycleData.launches!), decodedDict?[LifecycleData.CodingKeys.launches.rawValue])
        XCTAssertEqual(String(lifecycleData.daysSinceFirstLaunch!), decodedDict?[LifecycleData.CodingKeys.daysSinceFirstLaunch.rawValue])
        XCTAssertEqual(String(lifecycleData.daysSinceLastLaunch!), decodedDict?[LifecycleData.CodingKeys.daysSinceLastLaunch.rawValue])
        XCTAssertEqual(String(lifecycleData.hourOfTheDay!), decodedDict?[LifecycleData.CodingKeys.hourOfTheDay.rawValue])
        XCTAssertEqual(String(lifecycleData.dayOfTheWeek!), decodedDict?[LifecycleData.CodingKeys.dayOfTheWeek.rawValue])
        XCTAssertEqual(lifecycleData.operatingSystem, decodedDict?[LifecycleData.CodingKeys.operatingSystem.rawValue])
        XCTAssertEqual(lifecycleData.appId, decodedDict?[LifecycleData.CodingKeys.appId.rawValue])
        XCTAssertEqual(String(lifecycleData.daysSinceLastUpgrade!), decodedDict?[LifecycleData.CodingKeys.daysSinceLastUpgrade.rawValue])
        XCTAssertEqual(String(lifecycleData.launchesSinceUpgrade!), decodedDict?[LifecycleData.CodingKeys.launchesSinceUpgrade.rawValue])
        XCTAssertEqual(lifecycleData.deviceName, decodedDict?[LifecycleData.CodingKeys.deviceName.rawValue])
        XCTAssertEqual(lifecycleData.deviceResolution, decodedDict?[LifecycleData.CodingKeys.deviceResolution.rawValue])
        XCTAssertEqual(lifecycleData.carrierName, decodedDict?[LifecycleData.CodingKeys.carrierName.rawValue])
        XCTAssertEqual(lifecycleData.locale, decodedDict?[LifecycleData.CodingKeys.locale.rawValue])
        XCTAssertEqual(lifecycleData.runMode, decodedDict?[LifecycleData.CodingKeys.runMode.rawValue])
        XCTAssertEqual(lifecycleData.previousOsVersion, decodedDict?[LifecycleData.CodingKeys.previousOsVersion.rawValue])
        XCTAssertEqual(lifecycleData.previousAppId, decodedDict?[LifecycleData.CodingKeys.previousAppId.rawValue])
    }
    
    func testFullLifecycleDataTestRoundTrip() {
        // setup
        fillData()
        
        // test
        let encodedLifecycleData = try? JSONEncoder().encode(lifecycleData)
        let decodedLifecycleData = try! JSONDecoder().decode(LifecycleData.self, from: encodedLifecycleData!)
        
        // verify
        XCTAssertEqual(decodedLifecycleData, lifecycleData)
    }
    
    func testFullLifecycleDataTestRoundTripEmptyEventType() {
        // setup
        lifecycleData.launches = 10
        lifecycleData.daysSinceFirstLaunch = 20
        lifecycleData.daysSinceLastLaunch = 2
        lifecycleData.hourOfTheDay = 22
        lifecycleData.dayOfTheWeek = 1
        lifecycleData.operatingSystem = "13.0"
        lifecycleData.appId = "some-app-id"
        lifecycleData.daysSinceLastUpgrade = 2
        lifecycleData.launchesSinceUpgrade = 5
        lifecycleData.deviceName = "iPhone X"
        lifecycleData.deviceResolution = "some-res"
        lifecycleData.carrierName = "some-carrier"
        lifecycleData.locale = "en_US"
        lifecycleData.runMode = "Application"
        lifecycleData.previousOsVersion = "10.0"
        lifecycleData.previousAppId = "prev-app-id"
        
        // test
        let encodedLifecycleData = try? JSONEncoder().encode(lifecycleData)
        let decodedLifecycleData = try! JSONDecoder().decode(LifecycleData.self, from: encodedLifecycleData!)
        
        // verify
        XCTAssertEqual(decodedLifecycleData, lifecycleData)
    }

}
