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

class MockEventHistoryDatabase: EventHistoryDatabase {
    
    var paramHash: UInt32?
    var paramFrom: Date?
    var paramTo: Date?
    var returnInsert: Bool = false
    var returnSelect: EventHistoryResult?
    var returnDelete: Int = 0
    
    init?() {
        super.init(dispatchQueue: DispatchQueue(label: "mockEventHistoryDatabase"))
    }
    
    override func insert(hash: UInt32, handler: ((Bool) -> Void)? = nil) {
        paramHash = hash
        handler?(returnInsert)
    }
    
    override func select(hash: UInt32, from: Date? = nil, to: Date? = nil, handler: @escaping (EventHistoryResult) -> Void) {
        paramHash = hash
        paramFrom = from
        paramTo = to
        handler(returnSelect ?? EventHistoryResult(count: 0))
    }
    
    override func delete(hash: UInt32, from: Date? = nil, to: Date? = nil, handler: ((Int) -> Void)? = nil) {
        paramHash = hash
        paramFrom = from
        paramTo = to
        handler?(returnDelete)
    }
}
