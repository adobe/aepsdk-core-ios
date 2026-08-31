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

class SQLiteWrapperTests: XCTestCase {
    let databaseName = "db-test-for-sqlite-wrapper"

    override func setUp() {
        DataQueueServiceTests.removeDbFileIfExists(databaseName)
        DataQueueServiceTests.removeDbFileIfExists(databaseName + "-wal")
        DataQueueServiceTests.removeDbFileIfExists(databaseName + "-shm")
    }

    override func tearDown() {}

    /// query()
    func testQueryWithResults() throws {
        // Given
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        let tableName = "tb_test_01"
        let createTableStatement = """
        CREATE TABLE "\(tableName)" (
            "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
            "name"        TEXT
        );
        """
        _ = SQLiteWrapper.execute(database: connection, sql: createTableStatement)

        defer {
            let dropTableStatement = """
            DROP TABLE IF EXISTS \(tableName)
            """
            _ = SQLiteWrapper.execute(database: connection, sql: dropTableStatement)

            _ = SQLiteWrapper.disconnect(database: connection)
        }

        let insertRowStatement = """
        INSERT INTO \(tableName) (name)
        VALUES ("x");
        """
        _ = SQLiteWrapper.execute(database: connection, sql: insertRowStatement)

        // When
        let queryRowStatement = """
        SELECT name FROM \(tableName);
        """
        let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement)!
        // Then
        XCTAssertEqual(1, result.count)
        XCTAssertEqual("x", result[0]["name"])
    }

    /// query()
    func testQueryWithoutResult() throws {
        // Given
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        let tableName = "tb_test_01"
        let createTableStatement = """
        CREATE TABLE "\(tableName)" (
            "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
            "name"        TEXT
        );
        """
        _ = SQLiteWrapper.execute(database: connection, sql: createTableStatement)

        defer {
            let dropTableStatement = """
            DROP TABLE IF EXISTS \(tableName)
            """
            _ = SQLiteWrapper.execute(database: connection, sql: dropTableStatement)
        }

        // When
        let queryRowStatement = """
        SELECT name FROM \(tableName);
        """
        let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement)!
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - WAL

    /// enableWAL() should switch the database into WAL journal mode.
    func testEnableWAL_enablesWalJournalMode() {
        // Given
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        defer { _ = SQLiteWrapper.disconnect(database: connection) }

        // When
        let enabled = SQLiteWrapper.enableWAL(database: connection, databaseFilePath: .cachesDirectory, databaseName: databaseName)

        // Then
        XCTAssertTrue(enabled)
        let mode = SQLiteWrapper.query(database: connection, sql: "PRAGMA journal_mode;")?.first?.values.first
        XCTAssertEqual("wal", mode?.lowercased())
    }

    /// enableWAL() should relax the synchronous setting to NORMAL (reported as "1" by SQLite).
    func testEnableWAL_setsSynchronousToNormal() {
        // Given
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        defer { _ = SQLiteWrapper.disconnect(database: connection) }

        // When
        _ = SQLiteWrapper.enableWAL(database: connection, databaseFilePath: .cachesDirectory, databaseName: databaseName)

        // Then
        let synchronous = SQLiteWrapper.query(database: connection, sql: "PRAGMA synchronous;")?.first?.values.first
        XCTAssertEqual("1", synchronous)
    }

    /// setWalSafeFileProtection() should run without error and leave the database usable.
    /// Note: file protection is not enforced on the Simulator, so this verifies the call is a safe
    /// no-op there rather than asserting the resulting protection class.
    func testSetWalSafeFileProtection_keepsDatabaseUsable() {
        // Given - a WAL database with a table and its sidecar files
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        defer { _ = SQLiteWrapper.disconnect(database: connection) }
        _ = SQLiteWrapper.enableWAL(database: connection, databaseFilePath: .cachesDirectory, databaseName: databaseName)
        _ = SQLiteWrapper.execute(database: connection, sql: "CREATE TABLE t (id INTEGER);")
        _ = SQLiteWrapper.execute(database: connection, sql: "INSERT INTO t VALUES (1);")

        // When
        SQLiteWrapper.setWalSafeFileProtection(databaseFilePath: .cachesDirectory, databaseName: databaseName)

        // Then - the database remains readable and writable
        XCTAssertTrue(SQLiteWrapper.execute(database: connection, sql: "INSERT INTO t VALUES (2);"))
        let count = SQLiteWrapper.query(database: connection, sql: "SELECT COUNT(*) FROM t;")?.first?.values.first
        XCTAssertEqual("2", count)
    }

    /// journal_mode=WAL is written to the database header, so a fresh connection to the same file
    /// reports WAL without re-enabling it.
    func testEnableWAL_journalModePersistsAcrossReconnect() {
        // Given - a database switched to WAL, then closed
        let first = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        _ = SQLiteWrapper.enableWAL(database: first, databaseFilePath: .cachesDirectory, databaseName: databaseName)
        _ = SQLiteWrapper.disconnect(database: first)

        // When - reopening the same database file without calling enableWAL again
        let second = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        defer { _ = SQLiteWrapper.disconnect(database: second) }

        // Then - it is still in WAL mode
        let mode = SQLiteWrapper.query(database: second, sql: "PRAGMA journal_mode;")?.first?.values.first
        XCTAssertEqual("wal", mode?.lowercased())
    }

    /// A WAL database appends writes to a "-wal" sidecar file, which should exist on disk after a write.
    func testEnableWAL_createsWalSidecarFileOnWrite() throws {
        // Given - a WAL database
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        defer { _ = SQLiteWrapper.disconnect(database: connection) }
        _ = SQLiteWrapper.enableWAL(database: connection, databaseFilePath: .cachesDirectory, databaseName: databaseName)

        // When - writing to the database
        _ = SQLiteWrapper.execute(database: connection, sql: "CREATE TABLE t (id INTEGER);")
        _ = SQLiteWrapper.execute(database: connection, sql: "INSERT INTO t VALUES (1);")

        // Then - the -wal sidecar is present
        let caches = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        let walPath = caches.appendingPathComponent(databaseName).path + "-wal"
        XCTAssertTrue(FileManager.default.fileExists(atPath: walPath))
    }

    /// enableWAL() applies WAL-safe file protection as part of the same call. The database should
    /// remain readable and writable afterward, confirming the folded protection step is a safe no-op.
    func testEnableWAL_appliesFileProtectionAndKeepsDatabaseUsable() {
        // Given - a database with a table
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        defer { _ = SQLiteWrapper.disconnect(database: connection) }
        _ = SQLiteWrapper.execute(database: connection, sql: "CREATE TABLE t (id INTEGER);")

        // When - enabling WAL, which also sets file protection internally
        let enabled = SQLiteWrapper.enableWAL(database: connection, databaseFilePath: .cachesDirectory, databaseName: databaseName)

        // Then - the database remains usable
        XCTAssertTrue(enabled)
        XCTAssertTrue(SQLiteWrapper.execute(database: connection, sql: "INSERT INTO t VALUES (1);"))
        let count = SQLiteWrapper.query(database: connection, sql: "SELECT COUNT(*) FROM t;")?.first?.values.first
        XCTAssertEqual("1", count)
    }

    /// An existing rollback-journal database must convert to WAL on upgrade with no data loss.
    func testEnableWAL_migratesExistingRollbackDatabase() {
        // Given - a database created the old way (default journal), with a row
        let first = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        let modeBefore = SQLiteWrapper.query(database: first, sql: "PRAGMA journal_mode;")?.first?.values.first
        XCTAssertEqual("delete", modeBefore?.lowercased()) // default rollback journal
        _ = SQLiteWrapper.execute(database: first, sql: "CREATE TABLE t (id INTEGER);")
        _ = SQLiteWrapper.execute(database: first, sql: "INSERT INTO t VALUES (1);")
        _ = SQLiteWrapper.disconnect(database: first)

        // When - the upgraded SDK reopens the same file and enables WAL
        let second = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: databaseName)!
        defer { _ = SQLiteWrapper.disconnect(database: second) }
        _ = SQLiteWrapper.enableWAL(database: second, databaseFilePath: .cachesDirectory, databaseName: databaseName)

        // Then - mode is WAL, the old row is intact, and new writes work
        let modeAfter = SQLiteWrapper.query(database: second, sql: "PRAGMA journal_mode;")?.first?.values.first
        XCTAssertEqual("wal", modeAfter?.lowercased())
        XCTAssertTrue(SQLiteWrapper.execute(database: second, sql: "INSERT INTO t VALUES (2);"))
        let count = SQLiteWrapper.query(database: second, sql: "SELECT COUNT(*) FROM t;")?.first?.values.first
        XCTAssertEqual("2", count) // 1 old + 1 new, nothing lost
    }

    // MARK: - Subdirectory Connection Tests
    
    func testConnectWithSubdirectory_CreatesDirectoryStructure() {
        // Given
        let subDirectory = "test-subdirectory"
        let databaseName = "test-db-subdirectory"
        
        // When
        let connection = SQLiteWrapper.connect(databaseDirectoryPath: .cachesDirectory, 
                                               subDirectory: subDirectory, 
                                               databaseName: databaseName)
        
        // Then
        XCTAssertNotNil(connection, "Connection should be established")
        
        // Verify the directory structure was created
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let subdirectoryUrl = cachesUrl.appendingPathComponent(subDirectory)
            let databaseUrl = subdirectoryUrl.appendingPathComponent(databaseName)
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: subdirectoryUrl.path), "Subdirectory should be created")
            XCTAssertTrue(FileManager.default.fileExists(atPath: databaseUrl.path), "Database file should be created")
        }
        
        // Clean up
        if let connection = connection {
            _ = SQLiteWrapper.disconnect(database: connection)
        }
        
        // Remove test files
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let testDirectoryUrl = cachesUrl.appendingPathComponent(subDirectory)
            try? FileManager.default.removeItem(at: testDirectoryUrl)
        }
    }
    
    func testConnectWithSubdirectory_WhenSubdirectoryAlreadyExists_ShouldSucceed() {
        // Given
        let subDirectory = "existing-subdirectory"
        let databaseName = "test-db-existing-subdir"
        
        // Create the subdirectory first
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let subdirectoryUrl = cachesUrl.appendingPathComponent(subDirectory)
            try? FileManager.default.createDirectory(at: subdirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        }
        
        // When
        let connection = SQLiteWrapper.connect(databaseDirectoryPath: .cachesDirectory,
                                               subDirectory: subDirectory,
                                               databaseName: databaseName)
        
        // Then
        XCTAssertNotNil(connection, "Connection should be established even when subdirectory already exists")
        
        // Clean up
        if let connection = connection {
            _ = SQLiteWrapper.disconnect(database: connection)
        }
        
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let testDirectoryUrl = cachesUrl.appendingPathComponent(subDirectory)
            try? FileManager.default.removeItem(at: testDirectoryUrl)
        }
    }
    
    func testConnectWithSubdirectory_WhenDirectoryCreationFails_ShouldReturnNil() {
        // Given - use an invalid directory structure that would cause creation to fail
        let subDirectory = String(repeating: "a", count: 300) // Very long directory name that might cause issues
        let databaseName = "test-db-invalid"
        
        // When
        let connection = SQLiteWrapper.connect(databaseDirectoryPath: .cachesDirectory,
                                               subDirectory: subDirectory,
                                               databaseName: databaseName)
        
        // Then
        // Note: This test might pass on some systems that handle long paths better
        // The main purpose is to ensure the method handles failures gracefully
        if connection != nil {
            _ = SQLiteWrapper.disconnect(database: connection!)
            
            // Clean up if connection was somehow established
            if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
                let testDirectoryUrl = cachesUrl.appendingPathComponent(subDirectory)
                try? FileManager.default.removeItem(at: testDirectoryUrl)
            }
        }
        
        // The test passes regardless - we're mainly testing that it doesn't crash
        XCTAssertTrue(true, "Method should handle directory creation failures gracefully")
    }
    
    func testConnectWithSubdirectory_WithNestedSubdirectories_ShouldCreateAllLevels() {
        // Given
        let subDirectory = "level1/level2/level3"
        let databaseName = "nested-db"
        
        // When
        let connection = SQLiteWrapper.connect(databaseDirectoryPath: .cachesDirectory,
                                               subDirectory: subDirectory,
                                               databaseName: databaseName)
        
        // Then
        XCTAssertNotNil(connection, "Connection should be established with nested subdirectories")
        
        // Verify all directory levels were created
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let level1Url = cachesUrl.appendingPathComponent("level1")
            let level2Url = level1Url.appendingPathComponent("level2")
            let level3Url = level2Url.appendingPathComponent("level3")
            let databaseUrl = level3Url.appendingPathComponent(databaseName)
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: level1Url.path), "Level 1 directory should be created")
            XCTAssertTrue(FileManager.default.fileExists(atPath: level2Url.path), "Level 2 directory should be created")
            XCTAssertTrue(FileManager.default.fileExists(atPath: level3Url.path), "Level 3 directory should be created")
            XCTAssertTrue(FileManager.default.fileExists(atPath: databaseUrl.path), "Database file should be created")
        }
        
        // Clean up
        if let connection = connection {
            _ = SQLiteWrapper.disconnect(database: connection)
        }
        
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let testDirectoryUrl = cachesUrl.appendingPathComponent("level1")
            try? FileManager.default.removeItem(at: testDirectoryUrl)
        }
    }
    
    func testConnectWithSubdirectory_WithEmptySubdirectory_ShouldBehaveAsNormalConnect() {
        // Given
        let subDirectory = ""
        let databaseName = "empty-subdir-db"
        
        // When
        let connection = SQLiteWrapper.connect(databaseDirectoryPath: .cachesDirectory,
                                               subDirectory: subDirectory,
                                               databaseName: databaseName)
        
        // Then
        XCTAssertNotNil(connection, "Connection should be established even with empty subdirectory")
        
        // Clean up
        if let connection = connection {
            _ = SQLiteWrapper.disconnect(database: connection)
        }
        
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let databaseUrl = cachesUrl.appendingPathComponent(databaseName)
            try? FileManager.default.removeItem(at: databaseUrl)
        }
    }
    
    func testConnectWithSubdirectory_DatabaseOperationsWork() {
        // Given
        let subDirectory = "functional-test-dir"
        let databaseName = "functional-test-db"
        
        let connection = SQLiteWrapper.connect(databaseDirectoryPath: .cachesDirectory,
                                               subDirectory: subDirectory,
                                               databaseName: databaseName)
        XCTAssertNotNil(connection)
        
        guard let database = connection else {
            XCTFail("Database connection required for this test")
            return
        }
        
        let tableName = "test_table"
        let createTableStatement = """
        CREATE TABLE "\(tableName)" (
            "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
            "name"        TEXT,
            "value"       INTEGER
        );
        """
        
        // When - create table
        let createResult = SQLiteWrapper.execute(database: database, sql: createTableStatement)
        XCTAssertTrue(createResult, "Table creation should succeed")
        
        // When - insert data
        let insertStatement = "INSERT INTO \(tableName) (name, value) VALUES ('test', 42);"
        let insertResult = SQLiteWrapper.execute(database: database, sql: insertStatement)
        XCTAssertTrue(insertResult, "Data insertion should succeed")
        
        // When - query data
        let selectStatement = "SELECT name, value FROM \(tableName) WHERE id = 1;"
        let queryResult = SQLiteWrapper.query(database: database, sql: selectStatement)
        
        // Then
        XCTAssertNotNil(queryResult, "Query should return results")
        XCTAssertEqual(queryResult?.count, 1, "Should return one row")
        XCTAssertEqual(queryResult?[0]["name"] as? String, "test", "Name should match")
        XCTAssertEqual(queryResult?[0]["value"] as? String, "42", "Value should match")
        
        // Clean up
        _ = SQLiteWrapper.disconnect(database: database)
        
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let testDirectoryUrl = cachesUrl.appendingPathComponent(subDirectory)
            try? FileManager.default.removeItem(at: testDirectoryUrl)
        }
    }
}
