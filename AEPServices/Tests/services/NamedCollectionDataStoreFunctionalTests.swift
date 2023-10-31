//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//
import XCTest

@testable import AEPServices
@testable import AEPServicesMocks

import Foundation

class NamedCollectionDataStoreFunctionalTests: XCTestCase {
    var store: NamedCollectionDataStore?

    var keyPrefix = "com.adobe.mobile.datastore.testStore."
    let INT_KEY = "INT_KEY"
    let STRING_KEY = "STRING_KEY"
    let DOUBLE_KEY = "DOUBLE_KEY"
    let LONG_KEY = "LONG_KEY"
    let FLOAT_KEY = "FLOAT_KEY"
    let BOOL_KEY = "BOOL_KEY"
    let ARRAY_KEY = "ARRAY_KEY"
    let DICT_KEY = "DICT_KEY"
    let OBJ_KEY = "OBJECT_KEY"

    override func setUp() {
        NamedCollectionDataStore.clear()
        ServiceProvider.shared.reset()
        store = NamedCollectionDataStore(name: "testStore")
    }

    func testGetIntFallback() {
        let defaultVal: Int = 0
        XCTAssertEqual(store?.getInt(key: INT_KEY, fallback: defaultVal), defaultVal)
    }

    func testInt() {
        let val: Int = 1
        store?.set(key: INT_KEY, value: val)
        XCTAssertEqual(store?.getInt(key: INT_KEY), val)
    }

    func testIntSubscript() {
        let val: Int = 1
        store?[INT_KEY] = val
        XCTAssertEqual(store?[INT_KEY], val)
    }

    func testGetDoubleFallback() {
        let defaultVal: Double = 0.0
        XCTAssertEqual(store?.getDouble(key: DOUBLE_KEY, fallback: defaultVal), defaultVal)
    }

    func testDouble() {
        let val: Double = 1.0
        store?.set(key: DOUBLE_KEY, value: val)
        XCTAssertEqual(store?.getDouble(key: DOUBLE_KEY), val)
    }

    func testDoubleSubscript() {
        let val: Double = 1.0
        store?[DOUBLE_KEY] = val
        XCTAssertEqual(store?[DOUBLE_KEY], val)
    }

    func testGetStringFallback() {
        let defaultVal: String = "test"
        XCTAssertEqual(store?.getString(key: STRING_KEY, fallback: defaultVal), defaultVal)
    }

    func testString() {
        let val: String = "test"
        store?.set(key: STRING_KEY, value: val)
        XCTAssertEqual(store?.getString(key: STRING_KEY), val)
    }

    func testStringSubscript() {
        let val: String = "test"
        store?[STRING_KEY] = val
        XCTAssertEqual(store?[STRING_KEY], val)
    }

    func testGetLongFallback() {
        let defaultVal: Int64 = 0
        XCTAssertEqual(store?.getLong(key: LONG_KEY, fallback: defaultVal), defaultVal)
    }

    func testLong() {
        let val: Int64 = 1
        store?.set(key: LONG_KEY, value: val)
        XCTAssertEqual(store?.getLong(key: LONG_KEY), val)
    }

    func testLongSubscript() {
        let val: Int64 = 1
        store?[LONG_KEY] = val
        XCTAssertEqual(store?[LONG_KEY], val)
    }

    func testGetFloatFallback() {
        let defaultVal: Float = 1.0
        XCTAssertEqual(store?.getFloat(key: FLOAT_KEY, fallback: defaultVal), defaultVal)
    }

    func testSetFloat() {
        let val: Float = 1.0
        store?.set(key: FLOAT_KEY, value: val)
        XCTAssertEqual(store?.getFloat(key: FLOAT_KEY), val)
    }

    func testFloatSubscript() {
        let val: Float = 1.0
        store?[FLOAT_KEY] = val
        XCTAssertEqual(store?[FLOAT_KEY], val)
    }

    func testGetBoolFallback() {
        let defaultVal: AnyCodable = false
        XCTAssertEqual(store?.getBool(key: BOOL_KEY, fallback: defaultVal.boolValue), defaultVal.boolValue)
    }

    func testBool() {
        let val: Bool = true
        store?.set(key: BOOL_KEY, value: val)
        XCTAssertEqual(store?.getBool(key: BOOL_KEY), val)
    }

    func testBoolSubscript() {
        let val: Bool = false
        store?[BOOL_KEY] = val
        XCTAssertEqual(store?[BOOL_KEY], val)
    }

    func testGetArrayFallback() {
        let defaultArrVal: String = "test"
        let defaultVal: [String] = [defaultArrVal]
        guard let arr = store?.getArray(key: ARRAY_KEY, fallback: defaultVal) else {
            XCTFail()
            return
        }
        let val = arr[0] as? String
        XCTAssertEqual(val, defaultArrVal)
    }

    func testArray() {
        let testVal: [Any] = [1,2,3,4,5]
        store?.set(key: ARRAY_KEY, value: testVal)
        let getVal = store?.getArray(key: ARRAY_KEY)
        var intArrayVal = getVal as! [Int]
        intArrayVal.sort()
        for i in 0...(intArrayVal.count-1) {
            XCTAssertEqual(intArrayVal[i], i+1)
        }
    }

    func testArraySubscript() {
        let val: String = "test"
        let putArrVal: [Any] = [val]
        store?[ARRAY_KEY] = putArrVal
        guard let testArr: [Any] = store?[ARRAY_KEY] else {
            XCTFail()
            return
        }

        let testVal = testArr[0] as? String
        XCTAssertEqual(testVal, val)
    }

    func testGetDictFallback() {
        let defaultDictKey: String = "testKey"
        let defaultDictVal: String = "test"

        let defaultVal: [String: String] = [defaultDictKey: defaultDictVal]
        guard let dict = store?.getDictionary(key: DICT_KEY, fallback: defaultVal) else {
            XCTFail()
            return
        }
        let val = dict[defaultDictKey] as? String
        XCTAssertEqual(val, defaultDictVal)
    }

    func testDictionary() {
        let testVal: [AnyHashable: Any] = ["key1": "val1", "key2": "val2"]
        store?.set(key: DICT_KEY, value: testVal)
        let getVal = store?.getDictionary(key: DICT_KEY)
        XCTAssertEqual(getVal?["key1"] as? String, "val1")
        XCTAssertEqual(getVal?["key2"] as? String, "val2")
    }

    func testDictSubscript() {
        let valKey: String = "testKey"
        let val: String = "test"
        let putDictVal: [AnyHashable: String] = [valKey: val]
        store?[DICT_KEY] = putDictVal
        guard let testDict: [AnyHashable: Any] = store?[DICT_KEY] else {
            XCTFail()
            return
        }

        let testVal = testDict[valKey] as? String
        XCTAssertEqual(testVal, val)
    }

    func testGetCodableFallback() {
        let defaultVal: MockCoding = MockCoding(id: 0, name: "testName")
        XCTAssertEqual(store?.getObject(key: OBJ_KEY, fallback: defaultVal)?.id, defaultVal.id)
    }

    func testCodable() {
        let val = MockCoding(id: 1, name: "testName")
        let defaultVal = MockCoding(id: 0, name: "fallback")
        store?.setObject(key: OBJ_KEY, value: val)
        XCTAssertEqual(store?.getObject(key: OBJ_KEY, fallback: defaultVal)?.id, val.id)
    }

    func testCodableSubscript() {
        let val = MockCoding(id: 1, name: "testName")
        store?[OBJ_KEY] = val

        let subscriptResult: MockCoding? = store?[OBJ_KEY]
        XCTAssertEqual(subscriptResult?.id, val.id)
    }

    func testDate() {
        let date = Date()
        store?.setObject(key: OBJ_KEY, value: date)

        if #available(iOS 13, tvOS 13, *) {
            let persistedDate: Date? = store?.getObject(key: OBJ_KEY)
            XCTAssertEqual(persistedDate, date)
        } else {
            let persistedDate: Double? = store?.getObject(key: OBJ_KEY)
            XCTAssertEqual(persistedDate, date.timeIntervalSince1970)
        }
    }

    func testRemove() {
        store?.set(key: INT_KEY, value: "1")
        store?.remove(key: INT_KEY)
        XCTAssertNil(store?.getInt(key: INT_KEY))
    }

    // Make sure file writing does not corrupt when done on multiple threads
    func testMultiThreadingSimple() {
        let threadCount = 10
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = threadCount
        for i in 0 ..< threadCount {
            DispatchQueue.global().async {
                self.store?.set(key: self.INT_KEY, value: i)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(store?.getInt(key: INT_KEY))
    }

    // Make sure storage is not corrupted with multiple Store instances and multi threading
    func testMultiThreadingMultipleStores() {
        let threadCount = 10
        let expectation = XCTestExpectation()
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = threadCount
        let stores = ThreadSafeDictionary<Int, NamedCollectionDataStore>(identifier: "stores")
        let storeBaseName = "testStore."
        for i in 0 ..< threadCount {
            DispatchQueue.global().async {
                let store = NamedCollectionDataStore(name: storeBaseName + "\(i)")
                stores[i] = store
                store.set(key: self.INT_KEY, value: i)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)

        for i in 0 ..< threadCount {
            XCTAssertEqual(i, stores[i]?.getInt(key: INT_KEY))
        }
    }
}
