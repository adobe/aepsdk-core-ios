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
@testable import AEPServices
import AEPServicesMocks

/// Test type to ensure we can cache codable types
private struct Person: Codable, Equatable {
    let firstName: String
    let lastName: String
}

class DiskCacheServiceTests: XCTestCase {

    var diskCache = DiskCacheService()
    let CACHE_NAME = "DiskCacheServiceTests"
    let ENTRY_KEY = "testEntryKey"
    var dateOneMinInFuture: Date!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        dateOneMinInFuture = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
    }

    override func tearDown() {
        // clear cache after each test
        let cachePath = diskCache.cachePath(for: CACHE_NAME)
        try? FileManager.default.removeItem(atPath: cachePath)
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
        XCTAssertEqual(entry, storedEntry)
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
        XCTAssertEqual(entry, storedEntry)
        XCTAssertEqual(decodedPerson, person)
    }

    /// Tests that we can store many entries in the cache and read them back out
    func testSetGetHappyMany() {
        // setup
        let count = 100
        var entries = [CacheEntry]()

        // test
        for i in 0..<count {
            let entry = CacheEntry(data: "\(i)".data(using: .utf8)!, expiry: .date(dateOneMinInFuture), metadata: ["metadataKey": "metadataValue"])
            entries.append(entry)
            try! diskCache.set(cacheName: CACHE_NAME, key: "\(i)", entry: entry)
        }

        // verify
        for i in 0..<count {
            let storedEntry = diskCache.get(cacheName: CACHE_NAME, key: "\(i)")
            XCTAssertEqual(entries[i], storedEntry)
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
        XCTAssertEqual(newEntry, storedEntry)
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
        XCTAssertEqual(entry, storedEntry)

        // test pt. 2
        try! diskCache.remove(cacheName: CACHE_NAME, key: ENTRY_KEY)

        // verify pt. 2
        XCTAssertNil(diskCache.get(cacheName: CACHE_NAME, key: ENTRY_KEY))
    }

}
