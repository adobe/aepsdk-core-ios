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

@testable import AEPCore

class MockEventHistoryDatabase: EventHistoryStore {
    let dispatchQueue = DispatchQueue(label: "mockEventHistoryDatabase")

    // MARK: - Primary backing arrays
    private(set) var paramHashesList: [UInt32] = []
    private(set) var paramTimestampsList: [Date] = []
    private(set) var paramFromList: [Date?] = []
    private(set) var paramToList: [Date?] = []

    // MARK: - Computed properties for most recent values
    var paramHash: UInt32? { paramHashesList.last }
    var paramTimestamp: Date? { paramTimestampsList.last }
    var paramFrom: Date? { paramFromList.last ?? nil }
    var paramTo: Date? { paramToList.last ?? nil }

    // MARK: - Mock return values
    var returnInsert: Bool = false
    var returnSelect: EventHistoryResult?
    var returnSelectResultsQueue: [EventHistoryResult] = []
    var returnDelete: Int = 0

    func insert(hash: UInt32, timestamp: Date, handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            self.paramHashesList.append(hash)
            self.paramTimestampsList.append(timestamp)
            handler?(self.returnInsert)
        }
    }

    func select(hash: UInt32, from: Date? = nil, to: Date? = nil, handler: @escaping (EventHistoryResult) -> Void) {
        dispatchQueue.async {
            self.paramHashesList.append(hash)
            self.paramFromList.append(from)
            self.paramToList.append(to)

            // Dequeue the next result if available
            let result: EventHistoryResult
            if !self.returnSelectResultsQueue.isEmpty {
                result = self.returnSelectResultsQueue.removeFirst()
            } else {
                result = self.returnSelect ?? EventHistoryResult(count: 0)
            }

            handler(result)
        }
    }

    func delete(hash: UInt32, from: Date? = nil, to: Date? = nil, handler: ((Int) -> Void)? = nil) {
        dispatchQueue.async {
            self.paramHashesList.append(hash)
            self.paramFromList.append(from)
            self.paramToList.append(to)
            handler?(self.returnDelete)
        }
    }
}
