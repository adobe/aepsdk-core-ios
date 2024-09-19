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

import XCTest
import SQLite3
@testable import AEPCore
import AEPServicesMocks

class EventHistoryDatabaseTests: XCTestCase {
    let testDispatchQueue: DispatchQueue = DispatchQueue(label: "testEventHistoryQueue")
    var eventHistoryDatabase: EventHistoryDatabase!
    let dbName = "com.adobe.eventHistory"
 
    override func setUp() {
        eventHistoryDatabase = EventHistoryDatabase(dbName: dbName, dbQueue: testDispatchQueue, logger: MockLogger())
    }
    
    override func tearDown() {
        eventHistoryDatabase.cleanup()
    }
    
    func testInit() throws {
        XCTAssertTrue(dbExists(dbName), "The database file failed to initialize")
        XCTAssertNotNil(eventHistoryDatabase.connection)
    }
    
    func testInsert() throws {
        let expectation = XCTestExpectation(description: "handler was called for insert")
        let testHash: UInt32 = 552
                
        eventHistoryDatabase.insert(hash: testHash, timestamp: Date()) { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testInsertNoConnection() throws {
        let expectation = XCTestExpectation(description: "handler was called for insert")
        let testHash: UInt32 = 552
        
        let connection = eventHistoryDatabase.connection
        defer {
            sqlite3_close(connection)
        }
        eventHistoryDatabase.connection = nil
        
        eventHistoryDatabase.insert(hash: testHash, timestamp: Date()) { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testInsertInvalidConnection() throws {
        let expectation = XCTestExpectation(description: "handler was called for insert")
        let testHash: UInt32 = 552
        
        sqlite3_close(eventHistoryDatabase.connection)
        
        eventHistoryDatabase.insert(hash: testHash, timestamp: Date()) { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testSelect() throws {
        let insertExpectation = XCTestExpectation(description: "handler was called for insert")
        let selectExpectation = XCTestExpectation(description: "handler was called for select")
        let testHash: UInt32 = 552
        
        eventHistoryDatabase.insert(hash: testHash, timestamp: Date()) { result in
            XCTAssertTrue(result)
            insertExpectation.fulfill()
        }
        wait(for: [insertExpectation], timeout: 1)
                
        eventHistoryDatabase.select(hash: testHash, from: nil, to: nil) { result in
            XCTAssertNotNil(result)
            XCTAssertEqual(1, result.count)
            XCTAssertNotNil(result.newestOccurrence)
            XCTAssertNotNil(result.oldestOccurrence)
            selectExpectation.fulfill()
        }
        wait(for: [selectExpectation], timeout: 1)
    }
    
    func testSelectNoConnection() throws {
        let selectExpectation = XCTestExpectation(description: "handler was called for select")
        let testHash: UInt32 = 552
        
        let connection = eventHistoryDatabase.connection
        defer {
            sqlite3_close(connection)
        }
        
        eventHistoryDatabase.connection = nil
                
        eventHistoryDatabase.select(hash: testHash, from: nil, to: nil) { result in
            XCTAssertNotNil(result)
            XCTAssertEqual(-1, result.count)
            XCTAssertNil(result.newestOccurrence)
            XCTAssertNil(result.oldestOccurrence)
            selectExpectation.fulfill()
        }
        wait(for: [selectExpectation], timeout: 1)
    }
    
    func testSelectInvalidConnection() throws {
        let selectExpectation = XCTestExpectation(description: "handler was called for select")
        let testHash: UInt32 = 552
                
        sqlite3_close(eventHistoryDatabase.connection)
                
        eventHistoryDatabase.select(hash: testHash, from: nil, to: nil) { result in
            XCTAssertNotNil(result)
            XCTAssertEqual(-1, result.count)
            XCTAssertNil(result.newestOccurrence)
            XCTAssertNil(result.oldestOccurrence)
            selectExpectation.fulfill()
        }
        wait(for: [selectExpectation], timeout: 1)
    }
    
    func testDelete() throws {
        let insertExpectation = XCTestExpectation(description: "handler was called for insert")
        let selectExpectation = XCTestExpectation(description: "handler was called for select")
        let deleteExpectation = XCTestExpectation(description: "handler was called for delete")
        let testHash: UInt32 = 552
        
        eventHistoryDatabase.insert(hash: testHash, timestamp: Date()) { result in
            XCTAssertTrue(result)
            insertExpectation.fulfill()
        }
        wait(for: [insertExpectation], timeout: 1)
        
        eventHistoryDatabase.select(hash: testHash, from: nil, to: nil) { result in
            XCTAssertNotNil(result)
            XCTAssertEqual(1, result.count)
            selectExpectation.fulfill()
        }
        wait(for: [selectExpectation], timeout: 1)
        
        eventHistoryDatabase.delete(hash: testHash, from: nil, to: nil) { count in
            XCTAssertEqual(1, count)
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1)
    }
    
    func testDeleteNoConnection() throws {
        let deleteExpectation = XCTestExpectation(description: "handler was called for delete")
        let testHash: UInt32 = 552

        let connection = eventHistoryDatabase.connection
        defer {
            sqlite3_close(connection)
        }
        
        eventHistoryDatabase.connection = nil
        
        eventHistoryDatabase.delete(hash: testHash, from: nil, to: nil) { count in
            XCTAssertEqual(0, count)
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1)
    }
    
    func testDeleteInvalidConnection() throws {
        let deleteExpectation = XCTestExpectation(description: "handler was called for delete")
        let testHash: UInt32 = 552

        sqlite3_close(eventHistoryDatabase.connection)
        
        eventHistoryDatabase.delete(hash: testHash, from: nil, to: nil) { count in
            XCTAssertEqual(0, count)
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1)
    }
    
    // MARK: - Multi-Instance
    func testMultiInstance() throws {
        let dbName1 = "com.adobe.eventHistory1"
        let _ = EventHistoryDatabase(dbName: dbName1, dbQueue: testDispatchQueue, logger: MockLogger())
        
        let dbName2 = "com.adobe.eventHistory2"
        let _ = EventHistoryDatabase(dbName: dbName2, dbQueue: testDispatchQueue, logger: MockLogger())
        
        XCTAssertTrue(dbExists(dbName1))
        XCTAssertTrue(dbExists(dbName2))
    }
    
    private func dbExists(_ name: String) -> Bool {
        guard let dbFile = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(name) else {
            return false
        }
        return FileManager.default.fileExists(atPath: dbFile.path)
    }
}

extension EventHistoryDatabase {
    func cleanup() {
        let dbFileUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dbName)
        if let dbFile = dbFileUrl {
            try? FileManager.default.removeItem(at: dbFile)
        }
    }
}
