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

class EventHistoryDatabaseTests: XCTestCase {
    let testDispatchQueue: DispatchQueue = DispatchQueue(label: "testEventHistoryQueue")
    var eventHistoryDatabase: EventHistoryDatabase!
    var dbConnection: OpaquePointer!
    let dbName = "com.adobe.eventHistory"
    let dbFilePath: FileManager.SearchPathDirectory = .cachesDirectory
    var dbFileUrl: URL?
    
    override func setUp() {
        eventHistoryDatabase = EventHistoryDatabase(dispatchQueue: testDispatchQueue)
        dbConnection = eventHistoryDatabase.connection
        dbFileUrl = try? FileManager.default.url(for: dbFilePath, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dbName)
    }
    
    override func tearDown() {
        sqlite3_close(dbConnection)
        if let dbFile = dbFileUrl {
            try? FileManager.default.removeItem(at: dbFile)
        }
    }
    
    func testInit() throws {
        XCTAssertTrue(FileManager.default.fileExists(atPath: dbFileUrl?.path ?? ""), "The database file failed to initialize")
        XCTAssertNotNil(eventHistoryDatabase.connection)
    }
    
    func testInsert() throws {
        let expectation = XCTestExpectation(description: "handler was called for insert")
        let testHash: UInt32 = 552
                
        eventHistoryDatabase.insert(hash: testHash) { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testInsertNoConnection() throws {
        let expectation = XCTestExpectation(description: "handler was called for insert")
        let testHash: UInt32 = 552
        eventHistoryDatabase.connection = nil
        
        eventHistoryDatabase.insert(hash: testHash) { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testSelect() throws {
        let insertExpectation = XCTestExpectation(description: "handler was called for insert")
        let selectExpectation = XCTestExpectation(description: "handler was called for select")
        let testHash: UInt32 = 552
        
        eventHistoryDatabase.insert(hash: testHash) { result in
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
        eventHistoryDatabase.connection = nil
                
        eventHistoryDatabase.select(hash: testHash, from: nil, to: nil) { result in
            XCTAssertNotNil(result)
            XCTAssertEqual(0, result.count)
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
        
        eventHistoryDatabase.insert(hash: testHash) { result in
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
        eventHistoryDatabase.connection = nil
        
        eventHistoryDatabase.delete(hash: testHash, from: nil, to: nil) { count in
            XCTAssertEqual(0, count)
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1)
    }
}
