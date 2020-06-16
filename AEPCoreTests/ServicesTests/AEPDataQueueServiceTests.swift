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

class AEPDataQueueServiceTests: XCTestCase {
    let fileName = "db_aep_test_01"
    override func setUp() {
        AEPDataQueueServiceTests.removeDbFileIfExist(fileName)
        if let service = AEPDataQueueService.shared as? AEPDataQueueService {
            service.cleanCache()
        }
    }

    override func tearDown() {}

    internal static func removeDbFileIfExist(_ fileName: String) {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try! FileManager.default.removeItem(at: fileURL)
        }
    }

    internal static func dbFileExist(_ fileName: String) -> Bool {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// initDataQueue()
    func testInitializeDataQueue() throws {
        // Given

        // When
        _ = AEPDataQueueService.shared.getDataQueue(label: fileName)

        // Then
        XCTAssertTrue(AEPDataQueueServiceTests.dbFileExist(fileName))
        let connection = SQLiteWrapper.connect(databaseFilePath: .cachesDirectory, databaseName: fileName)
        XCTAssertTrue(SQLiteWrapper.tableExist(database: connection!, tableName: AEPDataQueue.DEFAULT_TABLE_NAME))
    }

    /// initDataQueue()
    func testDataQueueInstanceShouldBeCached() throws {
        // Given
        let dataQueueFirst = AEPDataQueueService.shared.getDataQueue(label: fileName)

        // When
        let dataQueueSecond = AEPDataQueueService.shared.getDataQueue(label: fileName)

        // Then
        XCTAssertTrue(dataQueueFirst as AnyObject? === dataQueueSecond as AnyObject?)
    }
}
