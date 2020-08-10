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

class LifecycleContextDataTests: XCTestCase {
    var contextData = LifecycleContextData()

    override func setUp() {
        contextData = LifecycleContextData()
    }

    private func fillMetrics() {
        contextData.lifecycleMetrics.installEvent = true
        contextData.lifecycleMetrics.launchEvent = true
        contextData.lifecycleMetrics.crashEvent = true
        contextData.lifecycleMetrics.upgradeEvent = true
        contextData.lifecycleMetrics.dailyEngagedEvent = true
        contextData.lifecycleMetrics.monthlyEngagedEvent = true
        contextData.lifecycleMetrics.launches = 10
        contextData.lifecycleMetrics.daysSinceFirstLaunch = 20
        contextData.lifecycleMetrics.daysSinceLastLaunch = 2
        contextData.lifecycleMetrics.hourOfTheDay = 22
        contextData.lifecycleMetrics.dayOfTheWeek = 1
        contextData.lifecycleMetrics.operatingSystem = "13.0"
        contextData.lifecycleMetrics.appId = "some-app-id"
        contextData.lifecycleMetrics.daysSinceLastUpgrade = 2
        contextData.lifecycleMetrics.launchesSinceUpgrade = 5
        contextData.lifecycleMetrics.deviceName = "iPhone X"
        contextData.lifecycleMetrics.carrierName = "some-carrier"
        contextData.lifecycleMetrics.deviceResolution = "some-res"
        contextData.lifecycleMetrics.locale = "en_US"
        contextData.lifecycleMetrics.runMode = "Application"
        contextData.lifecycleMetrics.previousOsVersion = "10.0"
        contextData.lifecycleMetrics.previousAppId = "prev-app-id"
    }

    // MARK: merging(...) tests

    /// Tests that when merging with nil the context data is preserved
    func testMergeWithNil() {
        // setup
        fillMetrics()

        // test
        let contextDataCopy = contextData
        contextData = contextData.merging(with: nil)

        // verify
        XCTAssertEqual(contextDataCopy, contextData)
    }

    /// Tests that values in `lifecycleMetrics` are merged properly
    func testMergeMetrics() {
        // setup
        fillMetrics()
        contextData.advertisingIdentifier = "old ad id"

        var otherContextData = LifecycleContextData()
        otherContextData.lifecycleMetrics.appId = "new app id"
        otherContextData.advertisingIdentifier = "new ad id"

        // test
        contextData = contextData.merging(with: otherContextData)

        // verify
        XCTAssertEqual(otherContextData.lifecycleMetrics.appId, contextData.lifecycleMetrics.appId)
        XCTAssertEqual(otherContextData.advertisingIdentifier, contextData.advertisingIdentifier)
        XCTAssertTrue(contextData.lifecycleMetrics.installEvent ?? false)
    }

    /// Tests that additional context data is merged correctly
    func testMergeAdditionalContextData() {
        // setup
        fillMetrics()
        contextData.additionalContextData = ["oldKey": "oldVal"]

        var otherContextData = LifecycleContextData()
        otherContextData.additionalContextData = ["newKey": "newVal", "oldKey": "newVal"]

        // test
        contextData = contextData.merging(with: otherContextData)

        // verify
        XCTAssertEqual(otherContextData.additionalContextData, contextData.additionalContextData)
    }

    /// Tests that session context data is merged correctly
    func testMergeSessionContextData() {
        // setup
        fillMetrics()
        contextData.sessionContextData = ["oldKey": "oldVal"]

        var otherContextData = LifecycleContextData()
        otherContextData.sessionContextData = ["newKey": "newVal", "oldKey": "newVal"]

        // test
        contextData = contextData.merging(with: otherContextData)

        // verify
        XCTAssertEqual(otherContextData.sessionContextData, contextData.sessionContextData)
    }

    /// Tests that we can merge the lifecycle metrics, advertising id, additional context data, and session context at once
    func testMergeAll() {
        // setup
        fillMetrics()
        contextData.advertisingIdentifier = "old ad id"
        contextData.additionalContextData = ["oldKey": "oldVal"]
        contextData.sessionContextData = ["oldKeySession": "oldVal"]

        var otherContextData = LifecycleContextData()
        otherContextData.lifecycleMetrics.appId = "new app id"
        otherContextData.advertisingIdentifier = "new ad id"
        otherContextData.additionalContextData = ["newKey": "newVal", "oldKey": "newVal"]
        otherContextData.sessionContextData = ["newKeySession": "newVal", "oldKeySession": "newVal"]

        // test
        contextData = contextData.merging(with: otherContextData)

        // verify
        XCTAssertEqual(otherContextData.lifecycleMetrics.appId, contextData.lifecycleMetrics.appId)
        XCTAssertEqual(otherContextData.advertisingIdentifier, contextData.advertisingIdentifier)
        XCTAssertTrue(contextData.lifecycleMetrics.installEvent ?? false)
        XCTAssertEqual(otherContextData.additionalContextData, contextData.additionalContextData)
        XCTAssertEqual(otherContextData.sessionContextData, contextData.sessionContextData)
    }

    // MARK: toEventData() tests

    fileprivate func assertMetrics(_ eventData: [String: Any]) {
        // verify
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.installEvent.stringValue])
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.launchEvent.stringValue])
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.crashEvent.stringValue])
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.upgradeEvent.stringValue])
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.dailyEngagedEvent.stringValue])
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.monthlyEngagedEvent.stringValue])
        XCTAssertEqual("10", eventData[LifecycleMetrics.CodingKeys.launches.stringValue] as? String)
        XCTAssertEqual("20", eventData[LifecycleMetrics.CodingKeys.daysSinceFirstLaunch.stringValue] as? String)
        XCTAssertEqual("2", eventData[LifecycleMetrics.CodingKeys.daysSinceLastLaunch.stringValue] as? String)
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.hourOfTheDay.stringValue])
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.dayOfTheWeek.stringValue])
        XCTAssertEqual("13.0", eventData[LifecycleMetrics.CodingKeys.operatingSystem.stringValue] as? String)
        XCTAssertEqual("some-app-id", eventData[LifecycleMetrics.CodingKeys.appId.stringValue] as? String)
        XCTAssertEqual("2", eventData[LifecycleMetrics.CodingKeys.daysSinceLastUpgrade.stringValue] as? String)
        XCTAssertEqual("5", eventData[LifecycleMetrics.CodingKeys.launchesSinceUpgrade.stringValue] as? String)
        XCTAssertEqual("iPhone X", eventData[LifecycleMetrics.CodingKeys.deviceName.stringValue] as? String)
        XCTAssertEqual("some-carrier", eventData[LifecycleMetrics.CodingKeys.carrierName.stringValue] as? String)
        XCTAssertNotNil(eventData[LifecycleMetrics.CodingKeys.deviceResolution.stringValue])
        XCTAssertEqual("en_US", eventData[LifecycleMetrics.CodingKeys.locale.stringValue] as? String)
        XCTAssertEqual("Application", eventData[LifecycleMetrics.CodingKeys.runMode.stringValue] as? String)
        XCTAssertEqual("10.0", eventData[LifecycleMetrics.CodingKeys.previousOsVersion.stringValue] as? String)
        XCTAssertEqual("prev-app-id", eventData[LifecycleMetrics.CodingKeys.previousAppId.stringValue] as? String)
    }

    /// Tests that metrics are properly formatter in the event data dict
    func testToEventDataMetricsOnly() {
        // setup
        fillMetrics()

        // test
        let eventData = contextData.toEventData()

        // verify
        assertMetrics(eventData)
    }

    /// Tests that metrics and ad id are properly formatter in the event data dict
    func testToEventDataMetricsAndAdId() {
        // setup
        fillMetrics()
        let testAdId = "test-ad-id"
        contextData.advertisingIdentifier = testAdId
        // test
        let eventData = contextData.toEventData()

        // verify
        assertMetrics(eventData)
        XCTAssertEqual(testAdId, eventData[LifecycleContextData.CodingKeys.advertisingIdentifier.stringValue] as? String)
    }

    /// Tests that metrics, ad id, and additional data are properly formatter in the event data dict
    func testToEventDataMetricsAndAdIdAndAdditionalContextData() {
        // setup
        fillMetrics()
        let testAdId = "test-ad-id"
        let additionalContextData = ["testKey": "testVal"]
        contextData.advertisingIdentifier = testAdId
        contextData.additionalContextData = additionalContextData

        // test
        let eventData = contextData.toEventData()

        // verify
        assertMetrics(eventData)
        XCTAssertEqual(testAdId, eventData[LifecycleContextData.CodingKeys.advertisingIdentifier.stringValue] as? String)
        XCTAssertEqual(additionalContextData["testKey"], eventData["testKey"] as? String)
    }

    /// Tests that metrics, ad id, additional data, and session data are properly formatter in the event data dict
    func testToEventDataMetricsAndAdIdAndAdditionalContextDataAndSessionData() {
        // setup
        fillMetrics()
        let testAdId = "test-ad-id"
        let additionalContextData = ["testKey": "testVal"]
        let sessionData = ["sessionKey": "sessionVal"]
        contextData.advertisingIdentifier = testAdId
        contextData.additionalContextData = additionalContextData
        contextData.sessionContextData = sessionData

        // test
        let eventData = contextData.toEventData()

        // verify
        assertMetrics(eventData)
        XCTAssertEqual(testAdId, eventData[LifecycleContextData.CodingKeys.advertisingIdentifier.stringValue] as? String)
        XCTAssertEqual(additionalContextData["testKey"], eventData["testKey"] as? String)
        XCTAssertEqual(sessionData["sessionKey"], eventData["sessionKey"] as? String)
    }
}
