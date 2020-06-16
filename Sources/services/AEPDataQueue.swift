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

public class AEPDataQueue: DataQueue {
    public let databaseName: String
    public let databaseFilePath: FileManager.SearchPathDirectory
    public static let DEFAULT_TABLE_NAME: String = "TB_AEP_DATA_ENTITY"
    private let serialQueue: DispatchQueue
    
    init?(databaseName: String, databaseFilePath: FileManager.SearchPathDirectory = .cachesDirectory, serialQueue: DispatchQueue) {
        self.databaseName = databaseName
        self.databaseFilePath = databaseFilePath
        self.serialQueue = serialQueue
        guard createTableIfNotExist(tableName: AEPDataQueue.DEFAULT_TABLE_NAME) == true else {
            print("failed to initialize AEPDataQueue with provided database name: \(databaseName)")
            return nil
        }
    }
    
    public func add(dataEntity: DataEntity) -> Bool {
        return serialQueue.sync {
            var dataString = ""
            if let data = dataEntity.data {
                dataString = String(data: data, encoding: .utf8) ?? ""
            }
            
            let insertRowStatement = """
            INSERT INTO \(AEPDataQueue.DEFAULT_TABLE_NAME) (uuid, timestamp, data)
            VALUES ("\(dataEntity.uuid)", \(dataEntity.timestamp.millisecondsSince1970), '\(dataString)');
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
    
    public func peek() -> DataEntity? {
        return serialQueue.sync {
            let queryRowStatement = """
            SELECT min(id),uuid,timestamp,data FROM \(AEPDataQueue.DEFAULT_TABLE_NAME);
            """
            guard let connection = connect() else {
                return nil
            }
            defer {
                _ = disconnect(database: connection)
            }
            guard let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement), result.count == 1 else {
                return nil
            }
            
            guard let uuid = result[0]["uuid"], let dateString = result[0]["timestamp"], let dataString = result[0]["data"] else {
                return nil
            }
            guard let dateInt64 = Int64(dateString) else {
                return nil
            }
            let date = Date(milliseconds: dateInt64)
            guard !dataString.isEmpty else {
                return DataEntity(uuid: uuid, timestamp: date, data: nil)
            }
            let data = dataString.data(using: .utf8)
            return DataEntity(uuid: uuid, timestamp: date, data: data)
        }
    }
    
    public func pop() -> DataEntity? {
        return serialQueue.sync {
            let queryRowStatement = """
            SELECT min(id),uuid,timestamp,data FROM \(AEPDataQueue.DEFAULT_TABLE_NAME);
            """
            guard let connection = connect() else {
                return nil
            }
            defer {
                _ = disconnect(database: connection)
            }
            guard let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement), result.count == 1 else {
                return nil
            }
            
            guard let uuid = result[0]["uuid"], let dateString = result[0]["timestamp"], let dataString = result[0]["data"] else {
                return nil
            }
            guard let dateInt64 = Int64(dateString) else {
                return nil
            }
            let date = Date(milliseconds: dateInt64)
            let data = dataString.data(using: .utf8)
            
            let deleteRowStatement = """
            DELETE FROM \(AEPDataQueue.DEFAULT_TABLE_NAME) WHERE uuid = "\(uuid)";
            """
            guard SQLiteWrapper.execute(database: connection, sql: deleteRowStatement) == true else {
                return nil
            }
            return DataEntity(uuid: uuid, timestamp: date, data: data)
        }
    }
    
    public func clear() -> Bool {
        return serialQueue.sync {
            let dropTableStatement = """
            DROP TABLE IF EXISTS \(AEPDataQueue.DEFAULT_TABLE_NAME)
            """
            guard let connection = connect() else {
                return false
            }
            defer {
                _ = disconnect(database: connection)
            }
            guard SQLiteWrapper.execute(database: connection, sql: dropTableStatement) == true else {
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
    
    private func disconnect(database: OpaquePointer) -> Bool {
        if SQLiteWrapper.disconnect(database: database) == true {
            return true
        }
        return false
    }
    
    private func createTableIfNotExist(tableName: String) -> Bool {
        guard let connection = connect() else {
            return false
        }
        defer {
            _ = disconnect(database: connection)
        }
        if SQLiteWrapper.tableExist(database: connection, tableName: AEPDataQueue.DEFAULT_TABLE_NAME) {
            return true
        } else {
            let createTableStatement = """
            CREATE TABLE "\(tableName)" (
                "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
                "uuid"        TEXT NOT NULL UNIQUE,
                "timestamp"   INTEGER NOT NULL,
                "data"        TEXT
            );
            """
            let result = SQLiteWrapper.execute(database: connection, sql: createTableStatement)
            return result
        }
    }
}
