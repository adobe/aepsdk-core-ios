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
@testable import AEPServicesMocks

@available(tvOS, unavailable)
class FileSystemNamedCollectionTest: XCTestCase {
    let service = FileSystemNamedCollection()

    func testSimpleStore() {
        let collectionName = "testName"
        let testKey = "testKey"
        let testValue: String = "testValue"
        service.set(collectionName: collectionName, key: testKey, value: testValue)
        let retrievedValue = service.get(collectionName: collectionName, key: testKey) as? String
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue, testValue)
    }

    func testRemove() {
        let collectionName = "testName"
        let testKey = "testKey"
        let testValue: String = "testValue"
        service.set(collectionName: collectionName, key: testKey, value: testValue)
        service.remove(collectionName: collectionName, key: testKey)
        let retrievedValue = service.get(collectionName: collectionName, key: testKey) as? String
        XCTAssertNil(retrievedValue)
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
        XCTAssertNotNil(firstGet)
        XCTAssertNotNil(secondGet)
        XCTAssertNotEqual(firstGet as? String, secondGet as? String)
        XCTAssertEqual(firstGet as? String, testValue)
        XCTAssertEqual(secondGet as? String, testValue2)
    }
    
    func testNewFileCreationSetPerformance() {
        NamedCollectionDataStore.clear()
        
        let collectionName = "testName"
        let testKey = "testKey"
        let testValue: String = "testValue"
        
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 1
        if #available(iOS 13.0, tvOS 13.0, *) {
            // .03 - .04 avg with FileSystem
            measure(options: measureOptions, block: {
                for i in 0 ..< 100 {
                    service.set(collectionName: collectionName + "\(i)", key: testKey, value: testValue)
                }
            })
        }
    }
    
    func testExistingFileSetPerformance() {
        NamedCollectionDataStore.clear()
        
        let collectionName = "testName"
        let testKey = "testKey"
        let testValue: String = "testValue"
        
        service.set(collectionName: collectionName, key: testKey, value: testValue)
        
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 1
        if #available(iOS 13.0, tvOS 13.0, *) {
            // .038-.043s Avg with FileSystem
            measure(options: measureOptions, block: {
                for i in 0 ..< 100 {
                    service.set(collectionName: collectionName, key: testKey + "\(i)", value: testValue)
                }
            })
        }
    }
    
    func testGetPerformance() {
        NamedCollectionDataStore.clear()
        
        let collectionName = "testName"
        let testKey = "testKey"
        let testValue: String = "testValue"
        
        for i in 0 ..< 100 {
            service.set(collectionName: collectionName, key: testKey + "\(i)", value: testValue)
        }
        
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 1
        if #available(iOS 13.0, tvOS 13.0, *) {
            // .008 avg with FileSystem
            measure(options: measureOptions, block: {
                for i in 0 ..< 100 {
                    _ = service.get(collectionName: collectionName, key: testKey + "\(i)")
                }
            })
        }
    }
}
