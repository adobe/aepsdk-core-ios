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

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

/// An implementation of protocol `DataQueue`
///    - implements a FIFO container (queue) for `DataEntity` objects
///    - `DataEntity` objects inside this queue will be persisted in SQLite database automatically
///    - the database operations is performed in series
class AEPDataQueue: DataQueue {
    public let databaseName: String
    public let databaseFilePath: FileManager.SearchPathDirectory
    public static let TABLE_NAME: String = "TB_AEP_DATA_ENTITY"
    
    private let serialQueue: DispatchQueue
    private let TB_KEY_UNIQUE_IDENTIFIER = "uniqueIdentifier"
    private let TB_KEY_TIMESTAMP = "timestamp"
    private let TB_KEY_DATA = "data"
    
    /// Creates a  new `DataQueue` with a database file path and a serial dispatch queue
    /// If it fails to create database or table, a `nil` will be returned.
    /// - Parameters:
    ///   - databaseName: the database name used to create SQLite database
    ///   - databaseFilePath: the SQLite database file will be stored in this directory, the default value is `.cachesDirectory`
    ///   - serialQueue: a serial dispatch queue used to perform database operations
    init?(databaseName: String, databaseFilePath: FileManager.SearchPathDirectory = .cachesDirectory, serialQueue: DispatchQueue) {
        self.databaseName = databaseName
        self.databaseFilePath = databaseFilePath
        self.serialQueue = serialQueue
        guard createTableIfNotExists(tableName: AEPDataQueue.TABLE_NAME) else {
            print("failed to initialize AEPDataQueue with provided database name: \(databaseName)")
            return nil
        }
    }
    
    func add(dataEntity: DataEntity) -> Bool {
        return serialQueue.sync {
            var dataString = ""
            if let data = dataEntity.data {
                dataString = String(data: data, encoding: .utf8) ?? ""
            }
            
            let insertRowStatement = """
            INSERT INTO \(AEPDataQueue.TABLE_NAME) (uniqueIdentifier, timestamp, data)
            VALUES ("\(dataEntity.uniqueIdentifier)", \(dataEntity.timestamp.millisecondsSince1970), '\(dataString)');
            """
            
            guard let connection = connect() else {
                return false
            }
            
            defer {
                _ = disconnect(database: connection)
            }
            
            let result = SQLiteWrapper.execute(database: connection, sql: insertRowStatement)
            return result
        }
    }
    
    func peek() -> DataEntity? {
        return serialQueue.sync {
            let queryRowStatement = """
            SELECT min(id),uniqueIdentifier,timestamp,data FROM \(AEPDataQueue.TABLE_NAME);
            """
            guard let connection = connect() else {
                return nil
            }
            defer {
                _ = disconnect(database: connection)
            }
            guard let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement), let firstColumn = result.first else {
                return nil
            }
            
            guard let uniqueIdentifier = firstColumn[TB_KEY_UNIQUE_IDENTIFIER], let dateString = firstColumn[TB_KEY_TIMESTAMP], let dataString = firstColumn[TB_KEY_DATA] else {
                return nil
            }
            guard let dateInt64 = Int64(dateString) else {
                return nil
            }
            let date = Date(milliseconds: dateInt64)
            guard !dataString.isEmpty else {
                return DataEntity(uniqueIdentifier: uniqueIdentifier, timestamp: date, data: nil)
            }
            let data = dataString.data(using: .utf8)
            return DataEntity(uniqueIdentifier: uniqueIdentifier, timestamp: date, data: data)
        }
    }
    
    func remove() -> Bool {
        return serialQueue.sync {
            guard let connection = connect() else {
                return false
            }
            defer {
                _ = disconnect(database: connection)
            }
            let deleteRowStatement = """
            DELETE FROM \(AEPDataQueue.TABLE_NAME) order by id limit 1;
            """
            guard SQLiteWrapper.execute(database: connection, sql: deleteRowStatement) else {
                return false
            }
            return true
        }
    }
    
    func clear() -> Bool {
        return serialQueue.sync {
            let dropTableStatement = """
            DROP TABLE IF EXISTS \(AEPDataQueue.TABLE_NAME);
            """
            guard let connection = connect() else {
                return false
            }
            defer {
                _ = disconnect(database: connection)
            }
            guard SQLiteWrapper.execute(database: connection, sql: dropTableStatement) else {
                return false
            }
            
            return true
        }
    }
    
    private func connect() -> OpaquePointer? {
        if let database = SQLiteWrapper.connect(databaseFilePath: databaseFilePath, databaseName: databaseName) {
            return database
        } else {
            return nil
        }
    }
    
    private func disconnect(database: OpaquePointer) {
        _ = SQLiteWrapper.disconnect(database: database)
    }
    
    private func createTableIfNotExists(tableName: String) -> Bool {
        guard let connection = connect() else {
            return false
        }
        defer {
            _ = disconnect(database: connection)
        }
        if SQLiteWrapper.tableExist(database: connection, tableName: AEPDataQueue.TABLE_NAME) {
            return true
        } else {
            let createTableStatement = """
            CREATE TABLE "\(tableName)" (
                "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
                "uniqueIdentifier"        TEXT NOT NULL UNIQUE,
                "timestamp"   INTEGER NOT NULL,
                "data"        TEXT
            );
            """
            let result = SQLiteWrapper.execute(database: connection, sql: createTableStatement)
            return result
        }
    }
}
