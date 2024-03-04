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

@testable import AEPServices
import AEPServicesMocks
import XCTest
import AEPServicesMocks

/// Test type to ensure we can cache codable types
private struct Person: Codable, Equatable {
    let firstName: String
    let lastName: String
}

class DiskCacheServiceTests: XCTestCase {
    var diskCache = DiskCacheService()
    let DATA_STORE_NAME = "DiskCacheService"
    let CACHE_NAME = "DiskCacheServiceTests"
    let ENTRY_KEY = "testEntryKey"
    var mockDataStore: MockDataStore!
    var dateOneMinInFuture: Date!

    override func setUp() {
        mockDataStore = MockDataStore()
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        dateOneMinInFuture = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
    }

    override func tearDown() {
        // clear cache after each test
        let cachePath = diskCache.cachePath(for: CACHE_NAME)
        try? FileManager.default.removeItem(atPath: cachePath)
        ServiceProvider.shared.reset()
    }

    func originalEntry(_ original: CacheEntry, equals cached: CacheEntry) -> Bool {
        guard original.data == cached.data, original.expiry.date.equal(other: cached.expiry.date) else {
            return false
        }

        guard let cachedMeta = cached.metadata, cachedMeta["PATH"] != nil else {
            return false
        }

        guard let originalMeta = original.metadata else {
            // the cached metadata will always contain a PATH.
            // if original metadata doesn't exist, it's count should be 1
            return cachedMeta.count == 1
        }

        for entry in originalMeta {
            guard let cacheVal = cachedMeta[entry.key], cacheVal == entry.value else {
                return false
            }
        }

        return true
    }

    /// When an entry doesn't exist in the cache we should return nil
    func testGetEmpty() {
        XCTAssertNil(diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY))
    }

    /// Tests that we can set and get an item in the cache
    func testSetGetHappy() {
        // setup
        let data = "Test".data(using: .utf8)!
        let entry = CacheEntry(data: data, expiry: .date(dateOneMinInFuture), metadata: ["metadataKey": "metadataValue"])

        // test
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)

        // verify
        let storedEntry = diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY)
        XCTAssertTrue(originalEntry(entry, equals: storedEntry!))
    }

    func testSetGetMissingAttributes() {
        // setup
        let data = "Test".data(using: .utf8)!
        let entry = CacheEntry(data: data, expiry: .date(dateOneMinInFuture), metadata: nil)

        // test
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)
        // remove attributes for this entry
        mockDataStore.remove(collectionName: "DiskCacheService", key: diskCache.dataStoreKey(for: CACHE_NAME, with: ENTRY_KEY))

        // verify
        XCTAssertNil(diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY))
    }

    func testSetGetMissingExpiryDate() {
        // setup
        let data = "Test".data(using: .utf8)!
        let entry = CacheEntry(data: data, expiry: .date(dateOneMinInFuture), metadata: nil)

        // test
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)
        // overwrite attributes for this entry
        mockDataStore.set(collectionName: DATA_STORE_NAME, key: diskCache.dataStoreKey(for: CACHE_NAME, with: ENTRY_KEY), value: ["key": "value"])

        // verify
        XCTAssertNil(diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY))
    }

    func testSetGetNoMetadata() {
        // setup
        let data = "Test".data(using: .utf8)!
        let entry = CacheEntry(data: data, expiry: .date(dateOneMinInFuture), metadata: nil)

        // test
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)

        // verify
        let storedEntry = diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY)
        XCTAssertTrue(originalEntry(entry, equals: storedEntry!))
    }

    /// Tests that we can set and get an item in the cache
    func testSetGetCodable() {
        // setup
        let person = Person(firstName: "firstName", lastName: "lastName")
        let data = try! JSONEncoder().encode(person)
        let entry = CacheEntry(data: data, expiry: .date(dateOneMinInFuture), metadata: ["metadataKey": "metadataValue"])

        // test
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)

        // verify
        let storedEntry = diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY)
        let decodedPerson = try! JSONDecoder().decode(Person.self, from: storedEntry!.data)
        XCTAssertTrue(originalEntry(entry, equals: storedEntry!))
        XCTAssertEqual(decodedPerson, person)
    }

    /// Tests that we can store many entries in the cache and read them back out
    func testSetGetHappyMany() {
        // setup
        let count = 100
        var entries = [CacheEntry]()

        // test
        for i in 0 ..< count {
            let entry = CacheEntry(data: "\(i)".data(using: .utf8)!, expiry: .date(dateOneMinInFuture), metadata: ["metadataKey": "metadataValue"])
            entries.append(entry)
            try! diskCache.set(cacheName: CACHE_NAME, key: "\(i)", entry: entry)
        }

        // verify
        for i in 0 ..< count {
            let storedEntry = diskCache.get(cacheName: CACHE_NAME, key: "\(i)")
            XCTAssertTrue(originalEntry(entries[i], equals: storedEntry!))
        }
    }

    /// Tests that get will return nil after a cache entry has expired
    func testSetWillExpire() {
        // setup
        let entry = CacheEntry(data: "Test".data(using: .utf8)!, expiry: .seconds(1), metadata: nil)
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)

        // wait for entry to expire
        sleep(2)

        // verify
        XCTAssertNil(diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY))
    }

    /// Tests that if we set the same cache entry twice it is overwritten
    func testSetShouldOverwrite() {
        // setup
        let entry = CacheEntry(data: "Test".data(using: .utf8)!, expiry: .never, metadata: nil)
        let newEntry = CacheEntry(data: "NewData".data(using: .utf8)!, expiry: .date(dateOneMinInFuture), metadata: ["metadataKey": "metadataValue"])

        // test
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: newEntry)

        // verify
        let storedEntry = diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY)
        XCTAssertTrue(originalEntry(newEntry, equals: storedEntry!))
    }

    /// When attempting to remove an item in the cache that doesn't exist we should throw an error
    func testRemoveInvalidThrows() {
        XCTAssertThrowsError(try diskCache.remove(cacheName: CACHE_NAME, key: ENTRY_KEY))
    }

    /// Tests that we can set an item in the cache, then read it, then remove it, and then confirm its deleted
    func testSetGetRemoveGet() {
        // setup
        let data = "Test".data(using: .utf8)!
        let entry = CacheEntry(data: data, expiry: .date(dateOneMinInFuture), metadata: nil)

        // test pt. 1
        try! diskCache.set(cacheName: CACHE_NAME, key: ENTRY_KEY, entry: entry)

        // verify pt. 1
        let storedEntry = diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY)
        XCTAssertTrue(originalEntry(entry, equals: storedEntry!))        

        // test pt. 2
        try! diskCache.remove(cacheName: CACHE_NAME, key: ENTRY_KEY)

        // verify pt. 2
        XCTAssertNil(diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY))
    }
}

private extension Date {
    func equal(other: Date?) -> Bool {
        guard let other = other else {
            return false;
        }

        // As date stores the timestamp in milliseconds, compare double value with accuracy greater than milliseconds.
        let accuracy = 0.00001;
        return abs(self.timeIntervalSince1970 - other.timeIntervalSince1970) < accuracy;
    }
}

