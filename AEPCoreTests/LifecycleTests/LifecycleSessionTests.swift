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

class LifecycleSessionTests: XCTestCase {
    let sessionTimeoutInSeconds = TimeInterval(60 * 5) // 5 min
    
    let dataStore = NamedKeyValueStore(name: "LifecycleTests")
    var session: LifecycleSession!
    
    var currentDate: Date!
    var currentDateMinusOneMin: Date!
    var currentDateMinusTenMin: Date!
    
    override func setUp() {
        dataStore.removeAll()
        session = LifecycleSession(dataStore: dataStore)
        computeDates()
    }

    private func computeDates() {
        currentDate = Date()
        
        currentDateMinusOneMin = Calendar.current.date(byAdding: .minute, value: -1, to: currentDate)
        currentDateMinusTenMin = Calendar.current.date(byAdding: .minute, value: -10, to: currentDate)
    }
    
    private func loadPersistedContext() -> LifecyclePersistedContext? {
        return dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT)
    }

    func testStartFirstLaunchSession() {
        // test
        let previousSessionInfo = session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        
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
    
    func testStartResumeSession() {
        // setup
        let previousSessionStartDate = currentDate
        let previousSessionPauseDate = Calendar.current.date(byAdding: .minute, value: 2, to: currentDate)!
        let newSessionStartDate = Calendar.current.date(byAdding: .minute, value: 6, to: currentDate)!
        
        let previousSessionPauseTime = newSessionStartDate.timeIntervalSince1970 - previousSessionPauseDate.timeIntervalSince1970
        
        // test
        session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        session.pause(pauseDate: previousSessionPauseDate)
        let previousSessionInfo = session.start(startDate: newSessionStartDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        
        // verify
        let expectedDate = previousSessionStartDate?.addingTimeInterval(previousSessionPauseTime)
        let sessionContext = loadPersistedContext()
        
        XCTAssertEqual(expectedDate, sessionContext?.startDate)
        XCTAssertNil(sessionContext?.pauseDate)
        XCTAssertFalse(sessionContext?.successfulClose ?? true)
        
        XCTAssertNil(previousSessionInfo)
    }
    
    func testStartVerifyAppIdAndOsVersion() {
        // setup
        let osVersion = "iOS 13.0"
        let appId = "test-app-id"
        
        // test
        let coreData = [LifecycleConstants.Keys.OPERATING_SYSTEM: osVersion, LifecycleConstants.Keys.APP_ID: appId]
        session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: coreData)
        
        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(sessionContext?.osVersion, osVersion)
        XCTAssertEqual(sessionContext?.appId, appId)
    }
    
    func testLifecycleHasAlreadyRan() {
        // test
        session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        let previousSessionInfo = session.start(startDate: currentDate.addingTimeInterval(60 * 6), sessionTimeoutInSeconds: LifecycleConstants.MAX_SESSION_LENGTH_SECONDS, coreData: [:])
        
        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(currentDate, sessionContext?.startDate)
        XCTAssertNil(sessionContext?.pauseDate)
        XCTAssertFalse(sessionContext?.successfulClose ?? true)
        XCTAssertEqual(1, sessionContext?.launches ?? 0)
        
        XCTAssertNil(previousSessionInfo)
    }
    
    func testStartSessionExpired() {
        // setup
        let previousSessionStartDate = currentDate
        let previousSessionPauseDate = currentDate.addingTimeInterval(60 * 2)
        let newSessionStartDate = previousSessionPauseDate.addingTimeInterval(60 * 6)
        
        // test
        session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        session.pause(pauseDate: previousSessionPauseDate)
        let previousSessionInfo = session.start(startDate: newSessionStartDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        
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
    
    func testPauseSimple() {
        // test
        session.pause(pauseDate: currentDate)
        
        // verify
        let sessionContext = loadPersistedContext()
        XCTAssertEqual(currentDate, sessionContext?.pauseDate)
        XCTAssertTrue(sessionContext?.successfulClose ?? false)
    }
    
    func testGetSessionDataNotANewSession() {
        // test
        session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        let previousSessionInfo = LifecycleSessionInfo(startDate: currentDateMinusTenMin, pauseDate: currentDateMinusOneMin, isCrash: false)
        let sessionData = session.getSessionData(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, previousSessionInfo: previousSessionInfo)
        
        // verify
        XCTAssertTrue(sessionData.isEmpty)
    }
    
    func testGetSessionDataDroppedSession() {
        // test
        session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        
        let previousSessionInfo = LifecycleSessionInfo(startDate: Calendar.current.date(byAdding: .day, value: -8, to: currentDate),
                                                       pauseDate: currentDateMinusTenMin, isCrash: false)
        
        let sessionData = session.getSessionData(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, previousSessionInfo: previousSessionInfo)
        
        // verify
        let expectedData = [LifecycleConstants.Keys.IGNORED_SESSION_LENGTH: "690600"]
        XCTAssertEqual(expectedData, sessionData)
    }
    
    func testGetSessionDataPreviousSessionValid() {
        // test
        session.start(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, coreData: [:])
        
        let previousSessionInfo = LifecycleSessionInfo(startDate: Calendar.current.date(byAdding: .day, value: -5, to: currentDate),
                                                       pauseDate: currentDateMinusTenMin, isCrash: false)
        
        let sessionData = session.getSessionData(startDate: currentDate, sessionTimeoutInSeconds: sessionTimeoutInSeconds, previousSessionInfo: previousSessionInfo)
        
        // verify
        let expectedData = [LifecycleConstants.Keys.PREVIOUS_SESSION_LENGTH: "431400"]
        XCTAssertEqual(expectedData, sessionData)
    }

}
