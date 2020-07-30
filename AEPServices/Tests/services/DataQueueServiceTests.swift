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

class DataQueueServiceTests: XCTestCase {
    let fileName = "db_aep_test_01"

    override func setUp() {
        DataQueueServiceTests.removeDbFileIfExists(fileName)
        if let service = DataQueueService.shared as? DataQueueService {
            service.cleanCache()
        }
    }

    override func tearDown() {}

    internal static func removeDbFileIfExists(_ fileName: String) {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try! FileManager.default.removeItem(at: fileURL)
        }
    }

    internal static func dbFileExists(_ fileName: String) -> Bool {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// initDataQueue()
    func testInitializeDataQueue() throws {
        // Given

        // When
        _ = DataQueueService.shared.getDataQueue(label: fileName)

        // Then
        XCTAssertTrue(DataQueueServiceTests.dbFileExists(fileName))
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)
        XCTAssertTrue(SQLiteWrapper.tableExists(database: connection!, tableName: SQLiteDataQueue.TABLE_NAME))
    }

    /// initDataQueue()
    func testInitializeDataQueueWithEmptyLabel() throws {
        // Given

        // When
        let result = DataQueueService.shared.getDataQueue(label: "")

        // Then
        XCTAssertNil(result)
    }

    /// initDataQueue()
    func testDataQueueInstanceShouldBeCached() throws {
        // Given
        let dataQueueFirst = DataQueueService.shared.getDataQueue(label: fileName)

        // When
        let dataQueueSecond = DataQueueService.shared.getDataQueue(label: fileName)

        // Then
        XCTAssertTrue(dataQueueFirst as AnyObject? === dataQueueSecond as AnyObject?)
    }
}
