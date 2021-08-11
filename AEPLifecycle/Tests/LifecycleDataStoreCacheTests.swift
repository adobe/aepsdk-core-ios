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

class LifecycleDataStoreCacheTests: XCTestCase {
    
    var dataStore = NamedCollectionDataStore(name: "LifecycleDataStoreCacheTests")
    var lifecycleDataStoreCache: LifecycleDataStoreCache!
    var currTimestamp = TimeInterval()

    override func setUp() {
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        currTimestamp = Date().timeIntervalSince1970
    }
    
    override func tearDown() {
        dataStore.remove(key: LifecycleConstants.DataStoreKeys.APP_CLOSE_TIMESTAMP_SEC)
        dataStore.remove(key: LifecycleConstants.DataStoreKeys.APP_START_TIMESTAMP_SEC)
        dataStore.remove(key: LifecycleConstants.DataStoreKeys.APP_PAUSE_TIMESTAMP_SEC)
    }
    
    func persistAppCloseTS(ts: TimeInterval) {
        dataStore.set(key: LifecycleConstants.DataStoreKeys.APP_CLOSE_TIMESTAMP_SEC, value: ts)
    }
    
    func persistAppStartTS(ts: TimeInterval) {
        dataStore.set(key: LifecycleConstants.DataStoreKeys.APP_START_TIMESTAMP_SEC, value: ts)
    }
    
    func persistAppPauseTS(ts: TimeInterval) {
        dataStore.set(key: LifecycleConstants.DataStoreKeys.APP_PAUSE_TIMESTAMP_SEC, value: ts)
    }
    
    func getAppCloseTSFromPersitence() -> TimeInterval {
        return dataStore.getDouble(key: LifecycleConstants.DataStoreKeys.APP_CLOSE_TIMESTAMP_SEC) ?? TimeInterval()
    }
    
    func getAppStartTSFromPersitence() -> TimeInterval {
        return dataStore.getDouble(key: LifecycleConstants.DataStoreKeys.APP_START_TIMESTAMP_SEC) ?? TimeInterval()
    }
    
    func getAppPauseTSFromPersitence() -> TimeInterval {
        return dataStore.getDouble(key: LifecycleConstants.DataStoreKeys.APP_PAUSE_TIMESTAMP_SEC) ?? TimeInterval()
    }
    
    /// Tests
    func testGetAppCloseTS_NotSet() {
        XCTAssertEqual(0.0, lifecycleDataStoreCache.getCloseTimestampSec())
    }
    
    func testGetAppCloseTS_UpdatedAfterDataStoreInstanceIsCreated() {
        //setup
        persistAppCloseTS(ts: currTimestamp)
        
        //test
        XCTAssertEqual(0.0, lifecycleDataStoreCache.getCloseTimestampSec())
    }
    
    func testConstructor_getAppCloseTS_WithPreviouslyPersistedValuePlusTimeout() {
        //setup
        persistAppCloseTS(ts: currTimestamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        //test
        let expectedTS = currTimestamp + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
    }
    
    func testSetLastKnownTS_DifferenceLessThanCacheTimeoutSinceLastUpdate_WillNotUpdateValueInPersitence() {
        //setup
        persistAppCloseTS(ts: currTimestamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        let expectedTS = currTimestamp + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        
        //test
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(1))
        
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
        // should not update persistence
        XCTAssertEqual(currTimestamp, getAppCloseTSFromPersitence())
    }
    
    func testSetLastKnownTS_DifferenceMoreThanCacheTimeoutSinceLastUpdate_WillUpdateValueInPersitenceAndReflectInNextLaunch() {
        //setup
        persistAppCloseTS(ts: currTimestamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        let expectedTS = currTimestamp + TimeInterval(3) + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        
        //test
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(3))
        
        // verify that datastore is updated
        XCTAssertEqual(currTimestamp + TimeInterval(3), getAppCloseTSFromPersitence())
        
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        // verify the closeTimeStamp value in next launch
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
    }
    
    func testSetLastKnownTS_ConsecutiveUpdates() {
        //setup
        persistAppCloseTS(ts: currTimestamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        let expectedTS = currTimestamp + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
        
        //test
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(1))
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(2))
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(3))
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(4))
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(5))
        lifecycleDataStoreCache.setLastKnownTimestamp(ts: currTimestamp + TimeInterval(6))
        
        // verify that datastore is updated
        XCTAssertEqual(currTimestamp + TimeInterval(6), getAppCloseTSFromPersitence())
    }
    
    func testSetAppStartTS() {
        //setup
        lifecycleDataStoreCache.setAppStartTimestamp(ts: currTimestamp)
        
        //test
        XCTAssertEqual(currTimestamp, getAppStartTSFromPersitence())
    }
    
    func testGetAppStartTS_NotSet() {
        XCTAssertEqual(0.0, lifecycleDataStoreCache.getAppStartTimestampSec())
    }
    
    func testGetAppStartTS() {
        //setup
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        lifecycleDataStoreCache.setAppStartTimestamp(ts: currTimestamp)
        
        //test
        XCTAssertEqual(currTimestamp, lifecycleDataStoreCache.getAppStartTimestampSec())
    }
    
    func testSetAppPauseTS() {
        //setup
        lifecycleDataStoreCache.setAppPauseTimestamp(ts: currTimestamp)
        
        //test
        XCTAssertEqual(currTimestamp, getAppPauseTSFromPersitence())
    }
    
    func testGetAppPauseTS_NotSet() {
        XCTAssertEqual(0.0, lifecycleDataStoreCache.getAppPauseTimestampSec())
    }
    
    func testGetAppPauseTS() {
        //setup
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        lifecycleDataStoreCache.setAppPauseTimestamp(ts: currTimestamp)
        
        //test
        XCTAssertEqual(currTimestamp, lifecycleDataStoreCache.getAppPauseTimestampSec())
    }
}
