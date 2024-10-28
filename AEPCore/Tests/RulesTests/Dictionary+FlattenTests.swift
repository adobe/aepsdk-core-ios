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

import XCTest

@testable import AEPCore

class EventDataFlattenerTests: XCTestCase {
    func testGetFlattenedDataDict() {
        /// Give: a nested event data dictionary
        let eventData: [String: Any] = ["key1": ["key11": "value11"], "key2": 2, "key3": ["key31": ["key32": "value32"], "key31-2": 31.2]]
        /// When: call `EventDataFlattener.getFlattenedDataDict` to flatten above event data
        let flattenedDictionary = eventData.flattening()
        /// Then
        let expectedResult: [String: Any] = ["key1.key11": "value11", "key2": 2, "key3.key31.key32": "value32", "key3.key31-2": 31.2]
        XCTAssertTrue(NSDictionary(dictionary: expectedResult).isEqual(to: NSDictionary(dictionary: flattenedDictionary) as! [AnyHashable: Any]))
    }
}
