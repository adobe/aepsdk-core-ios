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
        AEPDataQueueServiceTests.removeDbFileIfExists(databaseName)
        if let service = DataQueueService.shared as? DataQueueService {
            service.cleanCache()
        }
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
}
