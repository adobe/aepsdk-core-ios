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

import Foundation
import AEPServices

class EventHistoryDatabase {
    let LOG_PREFIX = "Event History Database"

    let dispatchQueue: DispatchQueue

    let dbName = "com.adobe.eventHistory"
    let dbFilePath: FileManager.SearchPathDirectory = .cachesDirectory

    let tableName = "Events"
    let columnHash = "eventHash"
    let columnTimestamp = "timestamp"

    var connection: OpaquePointer?

    /// Default initializer.
    ///
    /// - Returns `nil` if the `DispatchQueue` cannot be initialized.
    init?(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
        guard createTable() else {
            Log.warning(label: LOG_PREFIX, "Failed to initialize Event History Database.")
            return nil
        }
        guard let dbConnection = connect() else {
            Log.warning(label: LOG_PREFIX, "Failed to connect to Event History Database.")
            return nil
        }
        self.connection = dbConnection
    }

    deinit {
        if let dbConnection = connection {
            disconnect(database: dbConnection)
        }
    }

    /// Inserts a record in the EventHistory database.
    ///
    /// Fails if a connection to the database cannot be established, and calls the `handler` with a value of `false`.
    ///
    /// - Parameters:
    ///   - hash: the hashed value representing an event.
    ///   - timestamp: the event timestamp
    ///   - handler: called with the `Bool` result of the insert statement.
    func insert(hash: UInt32, timestamp: Date, handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            // first verify we can get a connection handle
            guard let connection = self.connection else {
                handler?(false)
                return
            }

            let insertStatement = """
            INSERT INTO \(self.tableName) (\(self.columnHash), \(self.columnTimestamp))
            VALUES (\(hash), \(timestamp.millisecondsSince1970))
            """

            let result = SQLiteWrapper.execute(database: connection, sql: insertStatement)
            handler?(result)
        }
    }

    /// Queries the event history database to search for existence of an event.
    ///
    /// This method will count all records in the event history database that match the provided `hash` and are within
    /// the bounds of the provided `from` and `to` date.
    ///
    /// If no `from` date is provided, the search will use the beginning of event history
    /// as the lower bounds of the date range.
    ///
    /// If no `to` date is provided, the search will use `now` as the upper bounds
    /// of the date range.
    ///
    /// The `handler` will be called with an `EventHistoryResult`.
    ///
    /// If no database connection is available, the handler will be called with a count of 0.
    /// If there are no matching records, the handler will be called with count of 0.
    ///
    /// - Parameters:
    ///   - hash: the 32-bit FNV-1a hashed representation of an Event's data.
    ///   - from: represents the lower bounds of the date range to use when searching for the hash
    ///   - to: represents the upper bounds of the date range to use when searching for the hash
    ///   - handler: a callback which will contain `EventHistoryResult` representing matching events
    func select(hash: UInt32, from: Date? = nil, to: Date? = nil, handler: @escaping (EventHistoryResult) -> Void) {
        dispatchQueue.sync {
            // first verify we can get a connection handle
            guard let connection = self.connection else {
                Log.warning(label: self.LOG_PREFIX, "Unable to get a connection to the event history database.")
                handler(EventHistoryResult(count: -1))
                return
            }

            let selectStatement = """
            SELECT count(*) as count, min(\(self.columnTimestamp)) as "oldest", max(\(self.columnTimestamp)) as "newest"
            FROM \(self.tableName)
            WHERE \(self.columnHash) == \(hash)
            AND \(self.columnTimestamp) >= \(from?.millisecondsSince1970 ?? 0)
            AND \(self.columnTimestamp) <= \(to?.millisecondsSince1970 ?? Date().millisecondsSince1970)
            """

            // a nil result means something went wrong with the database query
            guard let result = SQLiteWrapper.query(database: connection, sql: selectStatement),
                  let row = result.first else {
                Log.warning(label: self.LOG_PREFIX, "An error occurred when attempting to query for event(s) '\(hash)' between \(String(describing: from)) and \(String(describing: to)).")
                handler(EventHistoryResult(count: -1))
                return
            }

            let count = Int(row["count"] ?? "0") ?? 0
            let oldest = Date(milliseconds: Int64(row["oldest"] ?? "0") ?? 0)
            let newest = Date(milliseconds: Int64(row["newest"] ?? "0") ?? 0)
            let queryResult = EventHistoryResult(count: count, oldest: oldest, newest: newest)
            handler(queryResult)
        }
    }

    /// Deletes records with a matching `hash` between the `from` and `to` values provided.
    ///
    /// If no `from` date is provided, the search will use the beginning of event history
    /// as the lower bounds of the date range.
    ///
    /// If no `to` date is provided, the search will use `now` as the upper bounds
    /// of the date range.
    ///
    /// - Parameters:
    ///   - hash: the 32-bit FNV-1a hashed representation of an Event's data.
    ///   - from: represents the lower bounds of the date range to use when searching for the hash
    ///   - to: represents the upper bounds of the date range to use when searching for the hash
    ///   - handler: a callback which will contain the number of records deleted
    func delete(hash: UInt32, from: Date? = nil, to: Date? = nil, handler: ((Int) -> Void)? = nil) {
        dispatchQueue.async {
            // first verify we can get a connection handle
            guard let connection = self.connection else {
                handler?(0)
                return
            }

            let deleteStatement = """
            DELETE FROM \(self.tableName)
            WHERE \(self.columnHash) == \(hash)
            AND \(self.columnTimestamp) >= \(from?.millisecondsSince1970 ?? 0)
            AND \(self.columnTimestamp) <= \(to?.millisecondsSince1970 ?? Date().millisecondsSince1970)
            """

            // a nil result means there was no query results to be returned
            guard let _ = SQLiteWrapper.query(database: connection, sql: deleteStatement) else {
                handler?(0)
                return
            }

            // doing "SELECT changes()" after a delete will return the number of records that were deleted
            guard let recordCount = SQLiteWrapper.query(database: connection, sql: "SELECT changes()") else {
                handler?(0)
                return
            }

            let count = Int(recordCount.first?.values.first ?? "0") ?? 0
            handler?(count)
        }
    }

    // MARK: - private methods

    private func connect() -> OpaquePointer? {
        if let database = SQLiteWrapper.connect(databaseFilePath: dbFilePath, databaseName: dbName) {
            return database
        } else {
            Log.warning(label: LOG_PREFIX, "Failed to connect to database: \(dbName).")
            return nil
        }
    }

    private func disconnect(database: OpaquePointer) {
        SQLiteWrapper.disconnect(database: database)
    }

    @discardableResult
    private func createTable() -> Bool {
        guard let connection = connect() else {
            return false
        }
        defer {
            disconnect(database: connection)
        }
        if SQLiteWrapper.tableExists(database: connection, tableName: tableName) {
            return true
        } else {
            let createTableStatement = """
            CREATE TABLE "\(tableName)" (
                "\(columnHash)"          INTEGER NOT NULL,
                "\(columnTimestamp)"     INTEGER NOT NULL,
                PRIMARY KEY("\(columnHash)", "\(columnTimestamp)")
            );
            """

            let result = SQLiteWrapper.execute(database: connection, sql: createTableStatement)
            if result {
                Log.trace(label: LOG_PREFIX, "Successfully created table '\(tableName)'.")
            } else {
                Log.warning(label: LOG_PREFIX, "Failed to create table '\(tableName)'.")
            }

            return result
        }
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
