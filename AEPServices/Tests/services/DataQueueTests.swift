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
import XCTest

class DataQueueTests: XCTestCase {
    private let fileName = "db-aep-test-01"

    override func setUp() {
        DataQueueServiceTests.removeDbFileIfExists(fileName)
        DataQueueServiceTests.removeDbFileIfExists(fileName + "-wal")
        DataQueueServiceTests.removeDbFileIfExists(fileName + "-shm")
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
        let queue = DataQueueService().getDataQueue(label: fileName)!
        let event = EventEntity(id: UUID(), timestamp: Date(), name: "event001")
        let data = try JSONEncoder().encode(event)
        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)

        // When
        let result = queue.add(dataEntity: entity)

        // Then
        XCTAssertTrue(result)

        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(4, row[0].count)
        XCTAssertEqual(event.id.uuidString, row[0]["uniqueIdentifier"])
        XCTAssertEqual("1", row[0]["id"])
        let dataString = String(data: data, encoding: .utf8)!
        XCTAssertEqual(dataString, row[0]["data"])
        XCTAssertEqual(event.timestamp.millisecondsSince1970, Int64(row[0]["timestamp"]!))
    }

    /// add()
    func testAddDataEntityWithoutData() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        let event = EventEntity(id: UUID(), timestamp: Date(), name: "event001")
        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: nil)

        // When
        let result = queue.add(dataEntity: entity)

        // Then
        XCTAssertTrue(result)

        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(4, row[0].count)
        XCTAssertEqual(event.id.uuidString, row[0]["uniqueIdentifier"])
        XCTAssertEqual("1", row[0]["id"])
        XCTAssertEqual("", row[0]["data"])
        XCTAssertEqual(event.timestamp.millisecondsSince1970, Int64(row[0]["timestamp"]!))
    }

    /// peek()
    func testPeekDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.peek()!

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(3, row.count)
        XCTAssertEqual("1", row[0]["id"])
        XCTAssertEqual(result.uniqueIdentifier, row[0]["uniqueIdentifier"])
        let eventObj = try JSONDecoder().decode(EventEntity.self, from: result.data!)
        XCTAssertEqual(eventObj.id, events[0].id)
        XCTAssertEqual(eventObj.timestamp, events[0].timestamp)
        XCTAssertEqual(eventObj.name, events[0].name)
    }

    /// peek(n)
    func testPeekAllDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let results = queue.peek(n: 3)!

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(3, results.count)
        XCTAssertEqual(3, row.count)
        XCTAssertEqual(results.first?.uniqueIdentifier, row[0]["uniqueIdentifier"])
        XCTAssertEqual(results[1].uniqueIdentifier, row[1]["uniqueIdentifier"])
        XCTAssertEqual(results.last?.uniqueIdentifier, row[2]["uniqueIdentifier"])
        let eventObj = try JSONDecoder().decode(EventEntity.self, from: (results.first?.data!)!)
        XCTAssertEqual(eventObj.id, events[0].id)
        XCTAssertEqual(eventObj.timestamp, events[0].timestamp)
        XCTAssertEqual(eventObj.name, events[0].name)

        let eventObj1 = try JSONDecoder().decode(EventEntity.self, from: results[1].data!)
        XCTAssertEqual(eventObj1.id, events[1].id)
        XCTAssertEqual(eventObj1.timestamp, events[1].timestamp)
        XCTAssertEqual(eventObj1.name, events[1].name)

        let eventObj2 = try JSONDecoder().decode(EventEntity.self, from: (results.last?.data!)!)
        XCTAssertEqual(eventObj2.id, events[2].id)
        XCTAssertEqual(eventObj2.timestamp, events[2].timestamp)
        XCTAssertEqual(eventObj2.name, events[2].name)
    }

    /// peek(n)
    func testPeekAllPlusOneDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let results = queue.peek(n: 4)!

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(3, results.count)
        XCTAssertEqual(3, row.count)
        XCTAssertEqual(results.first?.uniqueIdentifier, row[0]["uniqueIdentifier"])
        XCTAssertEqual(results[1].uniqueIdentifier, row[1]["uniqueIdentifier"])
        XCTAssertEqual(results.last?.uniqueIdentifier, row[2]["uniqueIdentifier"])
        let eventObj = try JSONDecoder().decode(EventEntity.self, from: (results.first?.data!)!)
        XCTAssertEqual(eventObj.id, events[0].id)
        XCTAssertEqual(eventObj.timestamp, events[0].timestamp)
        XCTAssertEqual(eventObj.name, events[0].name)

        let eventObj1 = try JSONDecoder().decode(EventEntity.self, from: results[1].data!)
        XCTAssertEqual(eventObj1.id, events[1].id)
        XCTAssertEqual(eventObj1.timestamp, events[1].timestamp)
        XCTAssertEqual(eventObj1.name, events[1].name)

        let eventObj2 = try JSONDecoder().decode(EventEntity.self, from: (results.last?.data!)!)
        XCTAssertEqual(eventObj2.id, events[2].id)
        XCTAssertEqual(eventObj2.timestamp, events[2].timestamp)
        XCTAssertEqual(eventObj2.name, events[2].name)
    }

    /// peek(n)
    func testPeekFewDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let results = queue.peek(n: 2)!

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(2, results.count)
        XCTAssertEqual(3, row.count)
        XCTAssertEqual(results.first?.uniqueIdentifier, row[0]["uniqueIdentifier"])
        XCTAssertEqual(results.last?.uniqueIdentifier, row[1]["uniqueIdentifier"])
        let eventObj = try JSONDecoder().decode(EventEntity.self, from: (results.first?.data!)!)
        XCTAssertEqual(eventObj.id, events[0].id)
        XCTAssertEqual(eventObj.timestamp, events[0].timestamp)
        XCTAssertEqual(eventObj.name, events[0].name)

        let eventObj1 = try JSONDecoder().decode(EventEntity.self, from: results[1].data!)
        XCTAssertEqual(eventObj1.id, events[1].id)
        XCTAssertEqual(eventObj1.timestamp, events[1].timestamp)
        XCTAssertEqual(eventObj1.name, events[1].name)
    }

    /// peek()
    func testPeekDataEntityWithoutData() throws {
        // Given

        let queue = DataQueueService().getDataQueue(label: fileName)!
        let event = EventEntity(id: UUID(), timestamp: Date(), name: "event001")
        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: nil)

        _ = queue.add(dataEntity: entity)

        // When
        let result = queue.peek()!

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(1, row.count)
        XCTAssertNil(result.data)
    }

    /// peek()
    func testPeekDataEntityFromEmptyQueue() throws {
        // Given

        let queue = DataQueueService().getDataQueue(label: fileName)!

        // When
        // Then
        XCTAssertNil(queue.peek())
    }

    /// remove()
    func testRemoveDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.remove()

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(2, row.count)
        XCTAssertEqual("2", row[0]["id"])
        XCTAssertTrue(result)
    }

    /// remove(n)
    func testRemoveAllDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.remove(n: 3)

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertTrue(result)
        XCTAssertTrue(row.isEmpty)
    }

    /// remove(n)
    func testRemoveAllPlusOneDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.remove(n: 4)

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertTrue(result)
        XCTAssertTrue(row.isEmpty)
    }

    /// remove(n)
    func testRemoveSomeDataEntityFromQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        var events: [EventEntity] = []
        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.remove(n: 2)

        // Then
        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertTrue(result)
        XCTAssertEqual(1, row.count)
        XCTAssertEqual("3", row[0]["id"])
    }

    /// remove()
    func testRemoveDataEntityFromEmptyQueue() throws {
        // Given

        let queue = DataQueueService().getDataQueue(label: fileName)!

        // When
        // Then
        XCTAssertTrue(queue.remove())
    }

    /// clear()
    func testClearQueue() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!

        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: nil)
            _ = queue.add(dataEntity: entity)
        }

        // When
        let result = queue.clear()

        // Then
        XCTAssertTrue(result)
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let tableExist = SQLiteWrapper.tableExists(database: connection, tableName: SQLiteDataQueue.TABLE_NAME)
        let tableEmpty = SQLiteWrapper.tableIsEmpty(database: connection, tableName: SQLiteDataQueue.TABLE_NAME)

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertTrue(tableExist)
        XCTAssertTrue(tableEmpty)
    }

    /// count()
    func testCount() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!

        for i in 1 ... 3 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: nil)
            queue.add(dataEntity: entity)
        }

        // When
        let result = queue.count()

        // Then
        XCTAssertEqual(3, result)
    }

    /// thread-safe APIs
    func testConcurrentOperations() throws {
        // Given
        let dispatchQueue1 = DispatchQueue(label: "ThreadSafeDataQueueOperations.queue1", attributes: .concurrent)
        let dispatchQueue2 = DispatchQueue(label: "ThreadSafeDataQueueOperations.queue2", attributes: .concurrent)
        let dispatchQueue3 = DispatchQueue(label: "ThreadSafeDataQueueOperations.queue3", attributes: .concurrent)

        let queue = DataQueueService().getDataQueue(label: fileName)!

        let loop = 10
        let expectation = self.expectation(description: "Test sync")
        expectation.expectedFulfillmentCount = loop * 3

        // When
        for i in 1 ... loop {
            dispatchQueue1.async {
                do {
                    let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
                    let data = try JSONEncoder().encode(event)
                    let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
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

        for _ in 1 ... loop {
            dispatchQueue2.async {
                _ = queue.peek()
                expectation.fulfill()
            }
        }

        for _ in 1 ... loop {
            dispatchQueue3.async {
                _ = queue.remove()
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testAddDataWithEmbeddedSingleQuoteSucceeds() throws {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        let event = EventEntity(id: UUID(), timestamp: Date(), name: "e'ventname")
        let data = try JSONEncoder().encode(event)
        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)

        // When
        let result = queue.add(dataEntity: entity)

        // Then
        XCTAssertTrue(result)

        let sql = """
        SELECT * from \(SQLiteDataQueue.TABLE_NAME)
        """
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        let row = SQLiteWrapper.query(database: connection, sql: sql)!

        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
        }

        XCTAssertEqual(4, row[0].count)
        XCTAssertEqual(event.id.uuidString, row[0]["uniqueIdentifier"])
        XCTAssertEqual("1", row[0]["id"])
        let dataString = String(data: data, encoding: .utf8)!
        XCTAssertEqual(dataString, row[0]["data"])
        XCTAssertEqual(event.timestamp.millisecondsSince1970, Int64(row[0]["timestamp"]!))
    }

    // MARK: - WAL

    /// A queue configured with `.wal` should be in WAL journal mode (persisted in the file header).
    func testDataQueueUsesWALJournalMode() {
        // Given
        let service = DataQueueService()
        service.setConfig(DataQueueConfig(journalMode: .wal), forLabel: fileName)
        let queue = service.getDataQueue(label: fileName)!
        _ = queue.add(dataEntity: DataEntity(data: nil))

        // When - read the journal mode via an independent connection to the same file
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)!
        defer {
            _ = SQLiteWrapper.disconnect(database: connection)
            queue.close()
        }
        let mode = SQLiteWrapper.query(database: connection, sql: "PRAGMA journal_mode;")?.first?.values.first

        // Then
        XCTAssertEqual("wal", mode?.lowercased())
    }

    /// A write should produce the `-wal` sidecar file while a `.wal` queue's connection is open.
    func testWALSidecarFileCreatedAfterWrite() throws {
        // Given
        let service = DataQueueService()
        service.setConfig(DataQueueConfig(journalMode: .wal), forLabel: fileName)
        let queue = service.getDataQueue(label: fileName)!
        defer { queue.close() }

        // When
        _ = queue.add(dataEntity: DataEntity(data: "x".data(using: .utf8)))

        // Then
        let cachesUrl = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let walPath = cachesUrl.appendingPathComponent(fileName + "-wal").path
        XCTAssertTrue(FileManager.default.fileExists(atPath: walPath))
    }

    /// After `close()`, every operation should safely no-op instead of touching a closed connection.
    func testOperationsReturnDefaultsAfterClose() {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!
        _ = queue.add(dataEntity: DataEntity(data: "x".data(using: .utf8)))

        // When
        queue.close()

        // Then
        XCTAssertFalse(queue.add(dataEntity: DataEntity(data: nil)))
        XCTAssertNil(queue.peek())
        XCTAssertNil(queue.peek(n: 3))
        XCTAssertFalse(queue.remove())
        XCTAssertFalse(queue.clear())
        XCTAssertEqual(0, queue.count())
    }

    /// Calling `close()` more than once should be safe.
    func testCloseIsIdempotent() {
        // Given
        let queue = DataQueueService().getDataQueue(label: fileName)!

        // When / Then - no crash on repeated close
        queue.close()
        queue.close()
    }
}
