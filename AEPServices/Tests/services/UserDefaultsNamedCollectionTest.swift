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

@testable import AEPServices

class UserDefaultsNamedCollectionTest: XCTestCase {
    
    let service = UserDefaultsNamedCollection()
    
    func testSimpleStore() {
        let collectionName = "testName"
        let testKey = "testKey"
        let testValue: String = "testValue"
        service.set(collectionName: collectionName, key: testKey, value: testValue)
        XCTAssertEqual(service.get(collectionName: collectionName, key: testKey) as? String, testValue)
    }
    
    func testRemove() {
        let collectionName = "testName"
        let testKey = "testKey"
        let testValue: String = "testValue"
        service.set(collectionName: collectionName, key: testKey, value: testValue)
        service.remove(collectionName: collectionName, key: testKey)
        XCTAssertNil(service.get(collectionName: collectionName, key: testKey))
    }
    
    func testRemovaAll() {
        let collectionName = "testName"
        let testKey1 = "testKey1"
        let testValue1: String = "testValue1"
        let testKey2 = "testKey2"
        let testValue2 = "testValue2"
        
        service.set(collectionName: collectionName, key: testKey1, value: testValue1)
        service.set(collectionName: collectionName, key: testKey2, value: testValue2)
        
        service.removeAll(collectionName: collectionName)
        XCTAssertNil(service.get(collectionName: collectionName, key: testKey1))
        XCTAssertNil(service.get(collectionName: collectionName, key: testKey2))
    }
    
    func testNamespacing() {
        let collectionName = "testName"
        let collectionName2 = "testName2"
        let testKey = "testKey"
        let testValue: String = "testValue"
        let testValue2: String = "testValue2"
        
        service.set(collectionName: collectionName, key: testKey, value: testValue)
        service.set(collectionName: collectionName2, key: testKey, value: testValue2)
        
        let firstGet = service.get(collectionName: collectionName, key: testKey)
        let secondGet = service.get(collectionName: collectionName2, key: testKey)
        XCTAssertNotEqual(firstGet as? String, secondGet as? String)
        XCTAssertEqual(firstGet as? String, testValue)
        XCTAssertEqual(secondGet as? String, testValue2)
    }
}
