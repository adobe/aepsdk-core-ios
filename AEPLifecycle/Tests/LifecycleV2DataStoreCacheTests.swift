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

@testable import AEPLifecycle
import AEPServices
import XCTest

class LifecycleV2DataStoreCacheTests: XCTestCase {

    var dataStore = NamedCollectionDataStore(name: "LifecycleV2DataStoreCacheTests")
    var lifecycleDataStoreCache: LifecycleV2DataStoreCache!
    var currDate: Date!
    var currTimestamp: TimeInterval!

    override func setUp() {
        lifecycleDataStoreCache = LifecycleV2DataStoreCache(dataStore: dataStore)
        currDate = Date()
        currTimestamp = currDate.timeIntervalSince1970

    }

    override func tearDown() {
        dataStore.remove(key: LifecycleV2Constants.DataStoreKeys.APP_CLOSE_DATE)
        dataStore.remove(key: LifecycleV2Constants.DataStoreKeys.APP_START_DATE)
        dataStore.remove(key: LifecycleV2Constants.DataStoreKeys.APP_PAUSE_DATE)
    }

    func persistAppCloseDate(_ date: Date) {
        dataStore.setObject(key: LifecycleV2Constants.DataStoreKeys.APP_CLOSE_DATE, value: date)
    }

    func persistAppStartDate(_ date: Date) {
        dataStore.setObject(key: LifecycleV2Constants.DataStoreKeys.APP_START_DATE, value: date)
    }

    func persistAppPauseDate(_ date: Date) {
        dataStore.setObject(key: LifecycleV2Constants.DataStoreKeys.APP_PAUSE_DATE, value: date)
    }

    func getAppCloseDateFromPersitence() -> Date? {
        return dataStore.getObject(key: LifecycleV2Constants.DataStoreKeys.APP_CLOSE_DATE)
    }

    func getAppStartDateFromPersitence() -> Date? {
        return dataStore.getObject(key: LifecycleV2Constants.DataStoreKeys.APP_START_DATE)
    }

    func getAppPauseDateFromPersitence() -> Date? {
        return dataStore.getObject(key: LifecycleV2Constants.DataStoreKeys.APP_PAUSE_DATE)
    }

    /// Tests
    func testGetAppCloseDate_NotSet() {
        XCTAssertNil(lifecycleDataStoreCache.getCloseDate())
    }

    func testGetAppCloseDate_UpdatedAfterDataStoreInstanceIsCreated() {
        //setup
        persistAppCloseDate(currDate)

        //test
        XCTAssertNil(lifecycleDataStoreCache.getCloseDate())
    }

    func testConstructor_getAppCloseDate_WithPreviouslyPersistedValuePlusTimeout() {
        //setup
        persistAppCloseDate(currDate)
        lifecycleDataStoreCache = LifecycleV2DataStoreCache(dataStore: dataStore)

        //test
        let expectedTS = currTimestamp + LifecycleV2Constants.CACHE_TIMEOUT_SECONDS
        let expectedDate = Date(timeIntervalSince1970: expectedTS)
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseDate()?.timeIntervalSince1970)
        XCTAssertEqual(expectedDate, lifecycleDataStoreCache.getCloseDate())
    }

    func testSetLastKnownDate_DifferenceLessThanCacheTimeoutSinceLastUpdate_WillNotUpdateValueInPersitence() {
        //setup
        persistAppCloseDate(currDate)
        lifecycleDataStoreCache = LifecycleV2DataStoreCache(dataStore: dataStore)

        let expectedTS = currTimestamp + LifecycleV2Constants.CACHE_TIMEOUT_SECONDS

        //test
        let newTS =  currTimestamp + TimeInterval(1)
        lifecycleDataStoreCache.setLastKnownDate(Date(timeIntervalSince1970: newTS))

        XCTAssertEqual(Date(timeIntervalSince1970: expectedTS), lifecycleDataStoreCache.getCloseDate())
        // should not update persistence
        XCTAssertEqual(currDate, getAppCloseDateFromPersitence())
    }

    func testSetLastKnownDate_DifferenceMoreThanCacheTimeoutSinceLastUpdate_WillUpdateValueInPersitenceAndReflectInNextLaunch() {
        //setup
        persistAppCloseDate(currDate)
        lifecycleDataStoreCache = LifecycleV2DataStoreCache(dataStore: dataStore)

        let expectedTS = currTimestamp + TimeInterval(3) + LifecycleV2Constants.CACHE_TIMEOUT_SECONDS

        //test
        let newTS = currTimestamp + TimeInterval(3)
        lifecycleDataStoreCache.setLastKnownDate(Date(timeIntervalSince1970: newTS))

        // verify that datastore is updated
        let expectedDataStoreCloseTs = currTimestamp + TimeInterval(3)
        XCTAssertEqual(Date(timeIntervalSince1970: expectedDataStoreCloseTs), getAppCloseDateFromPersitence())

        lifecycleDataStoreCache = LifecycleV2DataStoreCache(dataStore: dataStore)
        // verify the closeTimeStamp value in next launch
        XCTAssertEqual(Date(timeIntervalSince1970: expectedTS), lifecycleDataStoreCache.getCloseDate())
    }

    func testSetLastKnownDate_ConsecutiveUpdates() {
        //setup
        persistAppCloseDate(currDate)
        lifecycleDataStoreCache = LifecycleV2DataStoreCache(dataStore: dataStore)

        let expectedTS = currTimestamp + LifecycleV2Constants.CACHE_TIMEOUT_SECONDS
        XCTAssertEqual(Date(timeIntervalSince1970: expectedTS), lifecycleDataStoreCache.getCloseDate())

        //test
        for i in 1...7 {
            let ts = currTimestamp + TimeInterval(i)
            lifecycleDataStoreCache.setLastKnownDate(Date(timeIntervalSince1970: ts))
        }

        // verify that datastore is updated
        let expectedTS2 = currTimestamp + TimeInterval(6)
        XCTAssertEqual(Date(timeIntervalSince1970: expectedTS2), getAppCloseDateFromPersitence())
    }

    func testSetAppStartDate() {
        //setup
        lifecycleDataStoreCache.setAppStartDate(currDate)

        //test
        XCTAssertEqual(currDate, getAppStartDateFromPersitence())
    }

    func testGetAppStartDate_NotSet() {
        XCTAssertNil(lifecycleDataStoreCache.getAppStartDate())
    }

    func testGetAppStartDate() {
        //setup
        lifecycleDataStoreCache.setAppStartDate(currDate)

        //test
        XCTAssertEqual(currDate, lifecycleDataStoreCache.getAppStartDate())
    }

    func testSetAppPauseDate() {
        //setup
        lifecycleDataStoreCache.setAppPauseDate(currDate)

        //test
        XCTAssertEqual(currDate, getAppPauseDateFromPersitence())
    }

    func testGetAppPauseDate_NotSet() {
        XCTAssertNil(lifecycleDataStoreCache.getAppPauseDate())
    }

    func testGetAppPauseDate() {
        //setup
        lifecycleDataStoreCache.setAppPauseDate(currDate)

        //test
        XCTAssertEqual(currDate, lifecycleDataStoreCache.getAppPauseDate())
    }
}
