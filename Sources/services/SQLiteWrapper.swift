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

import Foundation
import SQLite3

/// Helper class for  SQLite database operations
internal struct SQLiteWrapper {
    /// Connect SQLite database with provide database name and database file path.
    /// If the database file doesn't exist, a new database will be created and return a database connection
    /// - Parameters:
    ///   - databaseFilePath: the path to the database file
    ///   - databaseName: the database name
    /// - Returns: the database connection
    static func connect(databaseFilePath: FileManager.SearchPathDirectory, databaseName: String) -> OpaquePointer? {
        guard !databaseName.isEmpty else {
            print("Failed to open database - database name is empty")
            return nil
        }
        let fileURL = try? FileManager.default.url(for: databaseFilePath, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(databaseName)
        guard let url = fileURL else {
            print("Cannot create database connection due to invalid file path: SearchPathDirectory[\(databaseFilePath.rawValue)]/\(databaseName)")
            return nil
        }

        var database: OpaquePointer?
        if sqlite3_open(url.path, &database) != SQLITE_OK {
            print("Failed to open database at \(url.path)")
            return nil
        } else {
            print("Successfully opened connection to database at \(url.path)")
            return database
        }
    }

    /// Disconnect the database connection
    /// - Parameter database: the database connection
    /// - Returns: True, if the database connection is closed  successfully, otherwise false
    static func disconnect(database: OpaquePointer) -> Bool {
        let code = sqlite3_close(database)
        guard code == SQLITE_OK else {
            print("Failed to open database, error code \(code)")
            return false
        }
        return true
    }

    /// Execute the provided SQL statement
    /// - Parameters:
    ///   - database: the database connection
    ///   - sql: the SQL statement
    /// - Returns: True, if the SQL statement is executed  successfully, otherwise false
    static func execute(database: OpaquePointer, sql: String) -> Bool {
        if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
            let errMsg = String(cString: sqlite3_errmsg(database))
            print("Failed to execute SQL statement, error message: \(errMsg)")
            return false
        }
        return true
    }

    /// Execute the provide SQL statement
    /// - Parameters:
    ///   - database: the database connection
    ///   - sql: the SQL statement
    /// - Returns: an `Optional` result of a database  query
    static func query(database: OpaquePointer, sql: String) -> [[String: String]]? {
        var result: [[String: String]] = []
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare the SQL statement")
            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        var code = sqlite3_step(statement)
        while code == SQLITE_ROW {
            var dictionary: [String: String] = [:]

            for i in 0..<sqlite3_column_count(statement) {
                let column: String = String(cString: sqlite3_column_name(statement, i))
                if let rowValue = sqlite3_column_text(statement, i) {
                    let value: String = String(cString: rowValue)
                    dictionary[column] = value
                }
            }

            result.append(dictionary)
            code = sqlite3_step(statement)
        }

        guard code == SQLITE_DONE else {
            print("Failed to run sqlite3_step(), error code: \(code)")
            return nil
        }

        return result
    }

    /// Check existence of the database with provided database name
    /// - Parameters:
    ///   - database: the database connection
    ///   - tableName: the database name
    /// - Returns: True, if the database exists, otherwise false
    static func tableExist(database: OpaquePointer, tableName: String) -> Bool {
        let sql = "select count(*) from sqlite_master where type='table' and name='\(tableName)';"
        if let result = query(database: database, sql: sql), let firstColumn = result.first {
            if firstColumn[Array(firstColumn.keys)[0]] == "1" {
                return true
            }
        }
        return false
    }
}
