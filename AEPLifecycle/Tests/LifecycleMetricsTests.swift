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

@testable import AEPLifecycle
import XCTest

class LifecycleMetricsUnitTests: XCTestCase {
    var lifecycleMetrics: LifecycleMetrics!

    private func fillData() {
        lifecycleMetrics.installEvent = true
        lifecycleMetrics.launchEvent = true
        lifecycleMetrics.crashEvent = true
        lifecycleMetrics.upgradeEvent = true
        lifecycleMetrics.dailyEngagedEvent = true
        lifecycleMetrics.monthlyEngagedEvent = true
        lifecycleMetrics.launches = 10
        lifecycleMetrics.daysSinceFirstLaunch = 20
        lifecycleMetrics.daysSinceLastLaunch = 2
        lifecycleMetrics.hourOfTheDay = 22
        lifecycleMetrics.dayOfTheWeek = 1
        lifecycleMetrics.operatingSystem = "13.0"
        lifecycleMetrics.appId = "some-app-id"
        lifecycleMetrics.daysSinceLastUpgrade = 2
        lifecycleMetrics.launchesSinceUpgrade = 5
        lifecycleMetrics.deviceName = "iPhone X"
        lifecycleMetrics.carrierName = "some-carrier"
        lifecycleMetrics.deviceResolution = "some-res"
        lifecycleMetrics.locale = "en_US"
        lifecycleMetrics.runMode = "Application"
        lifecycleMetrics.previousOsVersion = "10.0"
        lifecycleMetrics.previousAppId = "prev-app-id"
    }

    override func setUp() {
        lifecycleMetrics = LifecycleMetrics()
    }

    func testEmptyLifecycleDataTest() {
        // setup
        let expectedString = "{}"

        // test
        let data = try? JSONEncoder().encode(lifecycleMetrics)
        let jsonStr = String(data: data!, encoding: .utf8)

        // verify
        XCTAssertEqual(expectedString, jsonStr!)
    }

    func testFullLifecycleDataEncodedCorrectly() {
        // setup
        fillData()
        let expectedDate = Date()
        lifecycleMetrics.installDate = expectedDate

        // test
        let encodedLifecycleData = try? JSONEncoder().encode(lifecycleMetrics)
        let decodedDict = try? JSONDecoder().decode([String: String].self, from: encodedLifecycleData!)

        // verify
        XCTAssertEqual(LifecycleMetrics.INSTALL_EVENT, decodedDict?[LifecycleMetrics.CodingKeys.installEvent.rawValue])
        XCTAssertEqual(LifecycleMetrics.LAUNCH_EVENT, decodedDict?[LifecycleMetrics.CodingKeys.launchEvent.rawValue])
        XCTAssertEqual(LifecycleMetrics.CRASH_EVENT, decodedDict?[LifecycleMetrics.CodingKeys.crashEvent.rawValue])
        XCTAssertEqual(LifecycleMetrics.UPGRADE_EVENT, decodedDict?[LifecycleMetrics.CodingKeys.upgradeEvent.rawValue])
        XCTAssertEqual(LifecycleMetrics.DAILY_ENG_USER_EVENT, decodedDict?[LifecycleMetrics.CodingKeys.dailyEngagedEvent.rawValue])
        XCTAssertEqual(LifecycleMetrics.MONTHLY_ENG_USER_EVENT, decodedDict?[LifecycleMetrics.CodingKeys.monthlyEngagedEvent.rawValue])
        XCTAssertEqual(expectedDate.toSdfString(), decodedDict?[LifecycleMetrics.CodingKeys.installDate.rawValue])
        XCTAssertEqual(String(lifecycleMetrics.launches!), decodedDict?[LifecycleMetrics.CodingKeys.launches.rawValue])
        XCTAssertEqual(String(lifecycleMetrics.daysSinceFirstLaunch!), decodedDict?[LifecycleMetrics.CodingKeys.daysSinceFirstLaunch.rawValue])
        XCTAssertEqual(String(lifecycleMetrics.daysSinceLastLaunch!), decodedDict?[LifecycleMetrics.CodingKeys.daysSinceLastLaunch.rawValue])
        XCTAssertEqual(String(lifecycleMetrics.hourOfTheDay!), decodedDict?[LifecycleMetrics.CodingKeys.hourOfTheDay.rawValue])
        XCTAssertEqual(String(lifecycleMetrics.dayOfTheWeek!), decodedDict?[LifecycleMetrics.CodingKeys.dayOfTheWeek.rawValue])
        XCTAssertEqual(lifecycleMetrics.operatingSystem, decodedDict?[LifecycleMetrics.CodingKeys.operatingSystem.rawValue])
        XCTAssertEqual(lifecycleMetrics.appId, decodedDict?[LifecycleMetrics.CodingKeys.appId.rawValue])
        XCTAssertEqual(String(lifecycleMetrics.daysSinceLastUpgrade!), decodedDict?[LifecycleMetrics.CodingKeys.daysSinceLastUpgrade.rawValue])
        XCTAssertEqual(String(lifecycleMetrics.launchesSinceUpgrade!), decodedDict?[LifecycleMetrics.CodingKeys.launchesSinceUpgrade.rawValue])
        XCTAssertEqual(lifecycleMetrics.deviceName, decodedDict?[LifecycleMetrics.CodingKeys.deviceName.rawValue])
        XCTAssertEqual(lifecycleMetrics.deviceResolution, decodedDict?[LifecycleMetrics.CodingKeys.deviceResolution.rawValue])
        XCTAssertEqual(lifecycleMetrics.carrierName, decodedDict?[LifecycleMetrics.CodingKeys.carrierName.rawValue])
        XCTAssertEqual(lifecycleMetrics.locale, decodedDict?[LifecycleMetrics.CodingKeys.locale.rawValue])
        XCTAssertEqual(lifecycleMetrics.runMode, decodedDict?[LifecycleMetrics.CodingKeys.runMode.rawValue])
        XCTAssertEqual(lifecycleMetrics.previousOsVersion, decodedDict?[LifecycleMetrics.CodingKeys.previousOsVersion.rawValue])
        XCTAssertEqual(lifecycleMetrics.previousAppId, decodedDict?[LifecycleMetrics.CodingKeys.previousAppId.rawValue])
    }

    func testFullLifecycleDataTestRoundTrip() {
        // setup
        fillData()

        // test
        let encodedLifecycleData = try? JSONEncoder().encode(lifecycleMetrics)
        let decodedLifecycleData = try! JSONDecoder().decode(LifecycleMetrics.self, from: encodedLifecycleData!)

        // verify
        XCTAssertEqual(decodedLifecycleData, lifecycleMetrics)
    }

    func testFullLifecycleDataTestRoundTripEmptyEventType() {
        // setup
        lifecycleMetrics.launches = 10
        lifecycleMetrics.daysSinceFirstLaunch = 20
        lifecycleMetrics.daysSinceLastLaunch = 2
        lifecycleMetrics.hourOfTheDay = 22
        lifecycleMetrics.dayOfTheWeek = 1
        lifecycleMetrics.operatingSystem = "13.0"
        lifecycleMetrics.appId = "some-app-id"
        lifecycleMetrics.daysSinceLastUpgrade = 2
        lifecycleMetrics.launchesSinceUpgrade = 5
        lifecycleMetrics.deviceName = "iPhone X"
        lifecycleMetrics.deviceResolution = "some-res"
        lifecycleMetrics.carrierName = "some-carrier"
        lifecycleMetrics.locale = "en_US"
        lifecycleMetrics.runMode = "Application"
        lifecycleMetrics.previousOsVersion = "10.0"
        lifecycleMetrics.previousAppId = "prev-app-id"

        // test
        let encodedLifecycleData = try? JSONEncoder().encode(lifecycleMetrics)
        let decodedLifecycleData = try! JSONDecoder().decode(LifecycleMetrics.self, from: encodedLifecycleData!)

        // verify
        XCTAssertEqual(decodedLifecycleData, lifecycleMetrics)
    }
}
