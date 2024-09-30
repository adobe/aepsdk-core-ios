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
@testable import AEPCoreMocks
import AEPServices
import XCTest

class LifecycleSessionTests: XCTestCase {
    let sessionTimeoutInSeconds = TimeInterval(60 * 5) // 5 min

    let dataStore = NamedCollectionDataStore(name: "LifecycleTests")
    var session: LifecycleSession!

    var currentDate: Date!
    var currentDateMinusOneMin: Date!
    var currentDateMinusTenMin: Date!

    override func setUp() {
        session = LifecycleSession(dataStore: dataStore)
        computeDates()
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        NamedCollectionDataStore.clear()
    }

    private func computeDates() {
        currentDate = Date()

        currentDateMinusOneMin = currentDate.addingTimeInterval(-60)
        currentDateMinusTenMin = currentDate.addingTimeInterval(-60 * 10)
    }

    private func loadPersistedContext() -> LifecyclePersistedContext? {
        return dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT)
    }

    /// Tests session is updated correctly after a first launch session start
    func testStartFirstLaunchSession() {
        // test
        let previousSessionInfo = session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())

        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(currentDate, sessionContext?.startDate!)
        XCTAssertNil(sessionContext?.pauseDate)
        XCTAssertFalse(sessionContext?.successfulClose ?? true)
        XCTAssertEqual(1, sessionContext?.launches)

        XCTAssertNil(previousSessionInfo?.startDate)
        XCTAssertNil(previousSessionInfo?.pauseDate)
        XCTAssertFalse(previousSessionInfo?.isCrash ?? true)
    }

    /// Tests the session is in the correct state after start -> pause -> start
    func testStartResumeSession() {
        // setup
        let previousSessionStartDate = currentDate
        let previousSessionPauseDate = currentDate.addingTimeInterval(60 * 2)
        let newSessionStartDate = currentDate.addingTimeInterval(60 * 6)

        let previousSessionPauseTime = newSessionStartDate.timeIntervalSince1970 - previousSessionPauseDate.timeIntervalSince1970

        // test
        session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())
        session.pause(pauseDate: previousSessionPauseDate)
        let previousSessionInfo = session.start(date: newSessionStartDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())

        // verify
        let expectedDate = previousSessionStartDate?.addingTimeInterval(previousSessionPauseTime)
        let sessionContext = loadPersistedContext()

        XCTAssertEqual(expectedDate, sessionContext?.startDate)
        XCTAssertNil(sessionContext?.pauseDate)
        XCTAssertFalse(sessionContext?.successfulClose ?? true)

        XCTAssertNil(previousSessionInfo)
    }

    /// Tests that OS version and app identifier are properly persisted by the LifecycleSession
    func testStartVerifyAppIdAndOsVersion() {
        // setup
        let osVersion = "iOS 13.0"
        let appId = "test-app-id"

        // test
        var metrics = LifecycleMetrics()
        metrics.operatingSystem = osVersion
        metrics.appId = appId
        session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: metrics)

        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(sessionContext?.osVersion, osVersion)
        XCTAssertEqual(sessionContext?.appId, appId)
    }

    /// Tests the behavior when calling start two times in a row, the second call should have no affect
    func testLifecycleHasAlreadyRan() {
        // test
        session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())
        let previousSessionInfo = session.start(date: currentDate.addingTimeInterval(60 * 6), sessionTimeout: LifecycleConstants.MAX_SESSION_LENGTH_SECONDS, coreMetrics: LifecycleMetrics())

        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(currentDate, sessionContext?.startDate)
        XCTAssertNil(sessionContext?.pauseDate)
        XCTAssertFalse(sessionContext?.successfulClose ?? true)
        XCTAssertEqual(1, sessionContext?.launches ?? 0)

        XCTAssertNil(previousSessionInfo)
    }

    /// Tests starting a new session after the previous start session exceeded timeout
    func testStartSessionExpired() {
        // setup
        let previousSessionStartDate = currentDate
        let previousSessionPauseDate = currentDate.addingTimeInterval(60 * 2)
        let newSessionStartDate = previousSessionPauseDate.addingTimeInterval(60 * 6)

        // test
        session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())
        session.pause(pauseDate: previousSessionPauseDate)
        let previousSessionInfo = session.start(date: newSessionStartDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())

        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(newSessionStartDate, sessionContext?.startDate)
        XCTAssertNil(sessionContext?.pauseDate)
        XCTAssertFalse(sessionContext?.successfulClose ?? true)
        XCTAssertEqual(2, sessionContext?.launches)

        XCTAssertEqual(previousSessionStartDate, previousSessionInfo?.startDate)
        XCTAssertEqual(previousSessionPauseDate, previousSessionInfo?.pauseDate)
        XCTAssertFalse(previousSessionInfo?.isCrash ?? true)
    }

    /// Tests that pause correctly persists the pause date and that it was a successful close close
    func testPauseSimple() {
        // test
        session.pause(pauseDate: currentDate)

        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(currentDate, sessionContext?.pauseDate)
        XCTAssertTrue(sessionContext?.successfulClose ?? false)
    }

    /// Tests that when there is no previous session returns an empty dict for getSessionData
    func testGetSessionDataNotANewSession() {
        // test
        session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())
        let previousSessionInfo = LifecycleSessionInfo(startDate: currentDateMinusTenMin, pauseDate: currentDateMinusOneMin, isCrash: false)
        let sessionData = session.getSessionData(startDate: currentDate, sessionTimeout: sessionTimeoutInSeconds, previousSessionInfo: previousSessionInfo)

        // verify
        XCTAssertTrue(sessionData.isEmpty)
    }

    /// Tests that we get the proper session data when starting a session within the ignore timeframe
    func testGetSessionDataDroppedSession() {
        // test
        session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())

        let previousSessionInfo = LifecycleSessionInfo(startDate: currentDate.addingTimeInterval(-8*24*60*60), // currentDate - 8 days
                                                       pauseDate: currentDateMinusTenMin, isCrash: false)

        let sessionData = session.getSessionData(startDate: currentDate, sessionTimeout: sessionTimeoutInSeconds, previousSessionInfo: previousSessionInfo)

        // verify
        let expectedData = [LifecycleConstants.EventDataKeys.IGNORED_SESSION_LENGTH: "690600"]
        XCTAssertEqual(expectedData, sessionData)
    }

    /// Tests that previous session length is calculated correctly
    func testGetSessionDataPreviousSessionValid() {
        // test
        session.start(date: currentDate, sessionTimeout: sessionTimeoutInSeconds, coreMetrics: LifecycleMetrics())

        let previousSessionInfo = LifecycleSessionInfo(startDate: currentDate.addingTimeInterval(-5*24*60*60), // currentDate - 5 days
                                                       pauseDate: currentDateMinusTenMin, isCrash: false)

        let sessionData = session.getSessionData(startDate: currentDate, sessionTimeout: sessionTimeoutInSeconds, previousSessionInfo: previousSessionInfo)

        // verify
        let expectedData = [LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_LENGTH: "431400"]
        XCTAssertEqual(expectedData, sessionData)
    }

}
