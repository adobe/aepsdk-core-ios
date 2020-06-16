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

@testable import AEPCore
import XCTest

class AEPDataQueueTests: XCTestCase {
    private let fileName = "db-aep-test-01"

    override func setUp() {
        AEPDataQueueServiceTests.removeDbFileIfExist(fileName)
        if let service = AEPDataQueueService.shared as? AEPDataQueueService {
            service.cleanCache()
        }
    }

    override func tearDown() {}

    private struct EventEntity: Codable {
        var id: UUID
        var timestamp: Date
        var name: String
    }

    /// add()
    func testAddDataEntityToDataQueue() throws {
        // Given
        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!
        let event = EventEntity(id: UUID(), timestamp: Date(), name: "event001")
        let data = try JSONEncoder().encode(event)
        let entity = DataEntity(uuid: event.id.uuidString, timestamp: event.timestamp, data: data)

        // When
        let result = queue.add(dataEntity: entity)

        // Then
        XCTAssertTrue(result)

        let sql = """
        SELECT * from \(AEPDataQueue.DEFAULT_TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertTrue(row[0].count == 4)
        XCTAssertEqual(event.id.uuidString, row[0]["uuid"])
        XCTAssertEqual("1", row[0]["id"])
        let dataString = String(data: data, encoding: .utf8)!
        XCTAssertEqual(dataString, row[0]["data"])
        XCTAssertEqual(event.timestamp.millisecondsSince1970, Int64(row[0]["timestamp"]!))
    }

    /// add()
    func testAddDataEntityWithoutData() throws {
        // Given
        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!
        let event = EventEntity(id: UUID(), timestamp: Date(), name: "event001")
        let entity = DataEntity(uuid: event.id.uuidString, timestamp: event.timestamp, data: nil)

        // When
        let result = queue.add(dataEntity: entity)

        // Then
        XCTAssertTrue(result)

        let sql = """
        SELECT * from \(AEPDataQueue.DEFAULT_TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertTrue(row[0].count == 4)
        XCTAssertEqual(event.id.uuidString, row[0]["uuid"])
        XCTAssertEqual("1", row[0]["id"])
        XCTAssertEqual("", row[0]["data"])
        XCTAssertEqual(event.timestamp.millisecondsSince1970, Int64(row[0]["timestamp"]!))
    }

    /// peek()
    func testPeekDataEntityFromQueue() throws {
        // Given
        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1...3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uuid: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.peek()!

        // Then
        let sql = """
        SELECT * from \(AEPDataQueue.DEFAULT_TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(3, row.count)
        XCTAssertEqual("1", row[0]["id"])
        XCTAssertEqual(result.uuid, row[0]["uuid"])
        let eventObj = try JSONDecoder().decode(EventEntity.self, from: result.data!)
        XCTAssertEqual(eventObj.id, events[0].id)
        XCTAssertEqual(eventObj.timestamp, events[0].timestamp)
        XCTAssertEqual(eventObj.name, events[0].name)
    }

    /// peek()
    func testPeekDataEntityWithoutData() throws {
        // Given

        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!
        let event = EventEntity(id: UUID(), timestamp: Date(), name: "event001")
        let entity = DataEntity(uuid: event.id.uuidString, timestamp: event.timestamp, data: nil)

        _ = queue.add(dataEntity: entity)

        // When
        let result = queue.peek()!

        // Then
        let sql = """
        SELECT * from \(AEPDataQueue.DEFAULT_TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(1, row.count)
        XCTAssertEqual(nil, result.data)
    }

    /// peek()
    func testPeekDataEntityFromEmptyQueue() throws {
        // Given

        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!

        // When
        // Then
        XCTAssertTrue(queue.peek() == nil)
    }

    /// pop()
    func testPopDataEntityFromQueue() throws {
        // Given
        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1...3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uuid: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.pop()!

        // Then
        let sql = """
        SELECT * from \(AEPDataQueue.DEFAULT_TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(2, row.count)
        XCTAssertEqual("2", row[0]["id"])
        let eventObj = try JSONDecoder().decode(EventEntity.self, from: result.data!)
        XCTAssertEqual(eventObj.id, events[0].id)
        XCTAssertEqual(eventObj.timestamp, events[0].timestamp)
        XCTAssertEqual(eventObj.name, events[0].name)
    }

    /// pop()
    func testPopDataEntityFromEmptyQueue() throws {
        // Given

        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!

        // When
        // Then
        XCTAssertTrue(queue.pop() == nil)
    }

    /// clear()
    func testClearQueue() throws {
        // Given
        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!

        for i in 1...3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            let entity = DataEntity(uuid: event.id.uuidString, timestamp: event.timestamp, data: nil)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.clear()

        // Then
        XCTAssertTrue(result)
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let tableExist = SQLiteWrapper.tableExist(database: connection, tableName: AEPDataQueue.DEFAULT_TABLE_NAME)

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertTrue(!tableExist)
    }

    /// thread-safe APIs
    func testConcurrentOperations() throws {
        // Given
        let dispatchQueue1 = DispatchQueue(label: "ThreadSafeDataQueueOperations.queue1", attributes: .concurrent)
        let dispatchQueue2 = DispatchQueue(label: "ThreadSafeDataQueueOperations.queue2", attributes: .concurrent)
        let dispatchQueue3 = DispatchQueue(label: "ThreadSafeDataQueueOperations.queue3", attributes: .concurrent)

        let queue = AEPDataQueueService.shared.initDataQueue(label: fileName)!

        let loop = 10
        let expectation = self.expectation(description: "Test sync")
        expectation.expectedFulfillmentCount = loop * 3

        // When
        for i in 1...loop {
            dispatchQueue1.async {
                do {
                    let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
                    let data = try JSONEncoder().encode(event)
                    let entity = DataEntity(uuid: event.id.uuidString, timestamp: event.timestamp, data: data)
                    let result = queue.add(dataEntity: entity)
                    XCTAssertTrue(result)
                    if i == 5 {
                        _ = queue.clear()
                    }
                    expectation.fulfill()
                } catch {
                    XCTFail()
                }
            }
        }

        for _ in 1...loop {
            dispatchQueue2.async {
                _ = queue.peek()
                expectation.fulfill()
            }
        }

        for _ in 1...loop {
            dispatchQueue3.async {
                _ = queue.pop()
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}
