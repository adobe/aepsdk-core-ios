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
import AEPServicesMocks
import XCTest

class LifecycleDataStoreCacheTests: XCTestCase {
    
    var dataStore = NamedCollectionDataStore(name: "LifecycleDataStoreCacheTests")
    var lifecycleDataStoreCache: LifecycleDataStoreCache!

    override func setUp() {
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
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
        let currTimeStamp = NSDate().timeIntervalSince1970
        persistAppCloseTS(ts: currTimeStamp)
        
        //test
        XCTAssertEqual(0.0, lifecycleDataStoreCache.getCloseTimestampSec())
    }
    
    func testConstructor_getAppCloseTS_WithPreviouslyPersistedValuePlusTimeout() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        persistAppCloseTS(ts: currTimeStamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        //test
        let expectedTS = currTimeStamp + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
    }
    
    func testSettLastKnownTS_DifferenceLessThanCacheTimeoutSinceLastUpdate_WillNotUpdateValueInPersitence() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        persistAppCloseTS(ts: currTimeStamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        let expectedTS = currTimeStamp + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        
        //test
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(1))
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
        // should not update persistence
        XCTAssertEqual(currTimeStamp, getAppCloseTSFromPersitence())
    }
    
    func testSettLastKnownTS_DifferenceMoreThanCacheTimeoutSinceLastUpdate_WillUpdateValueInPersitenceAndReflectInNextLaunch() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        persistAppCloseTS(ts: currTimeStamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        let expectedTS = currTimeStamp + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        let expectedTS2 = currTimeStamp + TimeInterval(3) + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
        
        //test
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(3))
        
        // verify that datastore is updated
        XCTAssertEqual(currTimeStamp + TimeInterval(3), getAppCloseTSFromPersitence())
        
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        // verify the closeTimeStamp value in next launch
        XCTAssertEqual(expectedTS2, lifecycleDataStoreCache.getCloseTimestampSec())
    }
    
    func testSettLastKnownTS_ConsecutiveUpdates() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        persistAppCloseTS(ts: currTimeStamp)
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        
        let expectedTS = currTimeStamp + TimeInterval(LifecycleConstants.CACHE_TIMEOUT_SECONDS)
        XCTAssertEqual(expectedTS, lifecycleDataStoreCache.getCloseTimestampSec())
        
        //test
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(1))
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(2))
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(3))
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(4))
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(5))
        lifecycleDataStoreCache.setLastKnownTimeStamp(ts: currTimeStamp + TimeInterval(6))
        
        // verify that datastore is updated
        XCTAssertEqual(currTimeStamp + TimeInterval(6), getAppCloseTSFromPersitence())
    }
    
    func testSetAppStartTS() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        lifecycleDataStoreCache.setAppStartTimestamp(ts: currTimeStamp)
        
        //test
        XCTAssertEqual(currTimeStamp, getAppStartTSFromPersitence())
    }
    
    func testGetAppStartTS_NotSet() {
        XCTAssertEqual(0.0, lifecycleDataStoreCache.getAppStartTimestampSec())
    }
    
    func testGetAppStartTS() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        lifecycleDataStoreCache.setAppStartTimestamp(ts: currTimeStamp)
        
        //test
        XCTAssertEqual(currTimeStamp, lifecycleDataStoreCache.getAppStartTimestampSec())
    }
    
    func testSetAppPauseTS() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        lifecycleDataStoreCache.setAppPauseTimestamp(ts: currTimeStamp)
        
        //test
        XCTAssertEqual(currTimeStamp, getAppPauseTSFromPersitence())
    }
    
    func testGetAppPauseTS_NotSet() {
        XCTAssertEqual(0.0, lifecycleDataStoreCache.getAppPauseTimestampSec())
    }
    
    func testGetAppPauseTS() {
        //setup
        let currTimeStamp = NSDate().timeIntervalSince1970
        lifecycleDataStoreCache = LifecycleDataStoreCache(dataStore: dataStore)
        lifecycleDataStoreCache.setAppPauseTimestamp(ts: currTimeStamp)
        
        //test
        XCTAssertEqual(currTimeStamp, lifecycleDataStoreCache.getAppPauseTimestampSec())
    }
}
