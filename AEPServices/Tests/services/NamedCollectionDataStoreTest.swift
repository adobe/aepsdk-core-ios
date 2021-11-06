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

class NamedCollectionDataStoreTest: XCTestCase {
    var store: NamedCollectionDataStore?

    let mockKeyValueService = MockKeyValueService()

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
        // Override the KeyValueStoreService with mock
        ServiceProvider.shared.namedKeyValueService = mockKeyValueService
        store = NamedCollectionDataStore(name: "testStore.")
    }

    func testGetIntFallback() {
        let defaultVal: Int = 0
        mockKeyValueService.getResult = nil
        XCTAssertEqual(store?.getInt(key: INT_KEY, fallback: defaultVal), defaultVal)
    }

    func testGetInt() {
        let putVal: Int = 1
        mockKeyValueService.getResult = putVal
        XCTAssertEqual(store?.getInt(key: INT_KEY), putVal)
    }

    func testSetInt() {
        let val: Int = 1
        store?.set(key: INT_KEY, value: val)
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Int, val)
    }

    func testIntSubscript() {
        let val: Int = 1
        store?[INT_KEY] = val
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Int, val)

        let val2: Any = 2
        mockKeyValueService.getResult = val2
        XCTAssertEqual(store?[INT_KEY], val2 as? Int)
    }

    func testGetDoubleFallback() {
        let defaultVal: Double = 0.0
        mockKeyValueService.getResult = nil
        XCTAssertEqual(store?.getDouble(key: DOUBLE_KEY, fallback: defaultVal), defaultVal)
    }

    func testGetDouble() {
        let putVal: Double = 1.0
        mockKeyValueService.getResult = putVal
        XCTAssertEqual(store?.getDouble(key: DOUBLE_KEY), putVal)
    }

    func testSetDouble() {
        let val: Double = 1.0
        store?.set(key: DOUBLE_KEY, value: val)
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Double, val)
    }

    func testDoubleSubscript() {
        let val: Double = 1.0
        store?[DOUBLE_KEY] = val
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Double, val)

        let val2: Any = 2.0
        mockKeyValueService.getResult = val2
        XCTAssertEqual(store?[DOUBLE_KEY], val2 as? Double)
    }

    func testGetStringFallback() {
        let defaultVal: String = "test"
        mockKeyValueService.getResult = nil
        XCTAssertEqual(store?.getString(key: STRING_KEY, fallback: defaultVal), defaultVal)
    }

    func testGetString() {
        let putVal: String = "test"
        mockKeyValueService.getResult = putVal
        XCTAssertEqual(store?.getString(key: STRING_KEY), putVal)
    }

    func testSetString() {
        let val: String = "test"
        store?.set(key: STRING_KEY, value: val)
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? String, val)
    }

    func testStringSubscript() {
        let val: String = "test"
        store?[STRING_KEY] = val
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? String, val)

        let val2: Any = "test2"
        mockKeyValueService.getResult = val2
        XCTAssertEqual(store?[STRING_KEY], val2 as? String)
    }

    func testGetLongFallback() {
        let defaultVal: Int64 = 0
        mockKeyValueService.getResult = nil
        XCTAssertEqual(store?.getLong(key: LONG_KEY, fallback: defaultVal), defaultVal)
    }

    func testGetLong() {
        let putVal: AnyCodable = 1
        mockKeyValueService.getResult = putVal
        XCTAssertEqual(store?.getLong(key: LONG_KEY), putVal.longValue)
    }

    func testSetLong() {
        let val: Int64 = 1
        store?.set(key: LONG_KEY, value: val)
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Int64, val)
    }

    func testLongSubscript() {
        let val: Int64 = 1
        store?[LONG_KEY] = val
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Int64, val)

        let val2: Any = 2
        mockKeyValueService.getResult = val2
        XCTAssertEqual(store?[LONG_KEY], val2 as? Int64)
    }

    func testGetFloatFallback() {
        let defaultVal: Float = 1.0
        mockKeyValueService.getResult = nil
        XCTAssertEqual(store?.getFloat(key: FLOAT_KEY, fallback: defaultVal), defaultVal)
    }

    func testGetFloat() {
        let putVal: Float = 1.0
        mockKeyValueService.getResult = putVal
        XCTAssertEqual(store?.getFloat(key: FLOAT_KEY), putVal)
    }

    func testSetFloat() {
        let val: Float = 1.0
        store?.set(key: FLOAT_KEY, value: val)
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Float, val)
    }

    func testFloatSubscript() {
        let val: Float = 1.0
        store?[FLOAT_KEY] = val
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Float, val)

        let val2: Any = 2.0
        mockKeyValueService.getResult = val2
        XCTAssertEqual(store?[FLOAT_KEY], val2 as? Float)
    }

    func testGetBoolFallback() {
        let defaultVal: AnyCodable = false
        mockKeyValueService.getResult = nil
        XCTAssertEqual(store?.getBool(key: BOOL_KEY, fallback: defaultVal.boolValue), defaultVal.boolValue)
    }

    func testGetBool() {
        let putVal: Bool = true
        mockKeyValueService.getResult = putVal
        XCTAssertEqual(store?.getBool(key: BOOL_KEY), putVal)
    }

    func testSetBool() {
        let val: Bool = true
        store?.set(key: BOOL_KEY, value: val)
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Bool, val)
    }

    func testBoolSubscript() {
        let val: Bool = false
        store?[BOOL_KEY] = val
        XCTAssertTrue(mockKeyValueService.setCalled)
        XCTAssertEqual(mockKeyValueService.setValue as? Bool, val)

        let val2: Any = true
        mockKeyValueService.getResult = val2
        XCTAssertEqual(store?[BOOL_KEY], val2 as? Bool)
    }

    func testGetArrayFallback() {
        let defaultArrVal: String = "test"
        let defaultVal: [String] = [defaultArrVal]
        mockKeyValueService.getResult = nil
        guard let arr = store?.getArray(key: ARRAY_KEY, fallback: defaultVal) else {
            XCTFail()
            return
        }
        let val = arr[0] as? String
        XCTAssertEqual(val, defaultArrVal)
    }

    func testGetArray() {
        let putArrVal: String = "test"
        let putVal: [String] = [putArrVal]
        mockKeyValueService.getResult = putVal
        guard let arr = store?.getArray(key: ARRAY_KEY) else {
            XCTFail()
            return
        }
        let val = arr[0] as? String
        XCTAssertEqual(val, putArrVal)
    }

    func testSetArray() {
        let val: String = "test"
        let putArrVal: [String] = [val]
        store?.set(key: ARRAY_KEY, value: putArrVal)
        XCTAssertTrue(mockKeyValueService.setCalled)
        guard let arr = mockKeyValueService.setValue as? [Any] else {
            XCTFail()
            return
        }
        let testVal = arr[0] as? String
        XCTAssertEqual(testVal, val)
    }

    func testArraySubscript() {
        let val: String = "test"
        let putArrVal: [String] = [val]
        store?[ARRAY_KEY] = putArrVal
        XCTAssertTrue(mockKeyValueService.setCalled)
        guard let arr = mockKeyValueService.setValue as? [Any] else {
            XCTFail()
            return
        }

        let testVal = arr[0] as? String
        XCTAssertEqual(testVal, val)

        let val2: String = "test2"
        let putArrVal2: Any = [val2]
        mockKeyValueService.getResult = putArrVal2
        guard let testArr2: [Any] = store?[ARRAY_KEY] else {
            XCTFail()
            return
        }

        let testVal2 = testArr2[0] as? String
        XCTAssertEqual(testVal2, val2)
    }

    func testGetDictFallback() {
        let defaultDictKey: String = "testKey"
        let defaultDictVal: String = "test"

        let defaultVal: [String: String] = [defaultDictKey: defaultDictVal]
        mockKeyValueService.getResult = nil
        guard let dict = store?.getDictionary(key: DICT_KEY, fallback: defaultVal) else {
            XCTFail()
            return
        }
        let val = dict[defaultDictKey] as? String
        XCTAssertEqual(val, defaultDictVal)
    }

    func testGetDict() {
        let putDictKey: String = "testKey"
        let putDictVal: String = "test"
        let putVal: [String: String] = [putDictKey: putDictVal]
        mockKeyValueService.getResult = putVal
        guard let dict = store?.getDictionary(key: DICT_KEY) else {
            XCTFail()
            return
        }
        let val = dict[putDictKey] as? String
        XCTAssertEqual(val, putDictVal)
    }

    func testSetDict() {
        let valKey: String = "testKey"
        let val: String = "test"
        let putDictVal = [valKey: val]

        store?.set(key: DICT_KEY, value: putDictVal)
        XCTAssertTrue(mockKeyValueService.setCalled)
        guard let dict = mockKeyValueService.setValue as? [AnyHashable: Any] else {
            XCTFail()
            return
        }

        let testVal = dict[valKey] as? String
        XCTAssertEqual(testVal, val)
    }

    func testDictSubscript() {
        let valKey: String = "testKey"
        let val: String = "test"
        let putDictVal: [String: String] = [valKey: val]
        store?[DICT_KEY] = putDictVal
        XCTAssertTrue(mockKeyValueService.setCalled)
        guard let dict = mockKeyValueService.setValue as? [AnyHashable: Any] else {
            XCTFail()
            return
        }

        let testVal = dict[valKey] as? String
        XCTAssertEqual(testVal, val)

        let val2Key: String = "test2Key"
        let val2: String = "test2"
        let putDictVal2: Any = [val2Key: val2]
        mockKeyValueService.getResult = putDictVal2
        guard let testDict2: [AnyHashable: Any] = store?[DICT_KEY] else {
            XCTFail()
            return
        }

        let testVal2 = testDict2[val2Key] as? String
        XCTAssertEqual(testVal2, val2)
    }

    func testGetCodableFallback() {
        let defaultVal: MockCoding = MockCoding(id: 0, name: "testName")
        mockKeyValueService.getResult = nil
        XCTAssertEqual(store?.getObject(key: OBJ_KEY, fallback: defaultVal)?.id, defaultVal.id)
    }

    func testGetCodable() {
        let putVal = MockCoding(id: 1, name: "testName")
        let defaultVal = MockCoding(id: 0, name: "fallback")
        mockKeyValueService.shouldEncode = true
        mockKeyValueService.getResult = putVal
        XCTAssertEqual(store?.getObject(key: OBJ_KEY, fallback: defaultVal)?.id, putVal.id)
    }

    func testSetCodable() {
        let val = MockCoding(id: 1, name: "testName")
        mockKeyValueService.shouldDecode = true
        store?.setObject(key: OBJ_KEY, value: val)
        XCTAssertTrue(mockKeyValueService.setCalled)
        let setVal = mockKeyValueService.setValue as? MockCoding
        XCTAssertEqual(setVal?.id, val.id)
    }

    func testCodableSubscript() {
        let val = MockCoding(id: 1, name: "testName")
        mockKeyValueService.shouldEncode = true
        store?[OBJ_KEY] = val
        XCTAssertTrue(mockKeyValueService.setCalled)
        let setVal = mockKeyValueService.setValue as? MockCoding
        XCTAssertEqual(setVal?.id, val.id)

        let val2 = MockCoding(id: 2, name: "testName2")
        mockKeyValueService.getResult = val2
        let subscriptResult: MockCoding? = store?[OBJ_KEY]
        XCTAssertEqual(subscriptResult?.id, val2.id)
    }

    func testSetDate() {
        let date = Date()
        store?.setObject(key: OBJ_KEY, value: date)

        XCTAssertTrue(mockKeyValueService.setCalled)
        if #available(iOS 13, tvOS 13, *) {
            let encodedDate = try? JSONEncoder().encode(date)
            XCTAssertEqual(mockKeyValueService.setValue as? Data, encodedDate)
        } else {
            XCTAssertEqual(mockKeyValueService.setValue as? Double, date.timeIntervalSince1970)
        }
    }
    func testGetDateCodable() {
        let date = Date()
        mockKeyValueService.getResult = try? JSONEncoder().encode(date)

        let persistedDate: Date? = store?.getObject(key: OBJ_KEY)
        XCTAssertEqual(persistedDate, date)
    }

    func testGetDateDouble() {
        let date = Date()
        mockKeyValueService.getResult = date.timeIntervalSince1970

        let persistedDate: Date? = store?.getObject(key: OBJ_KEY)
        XCTAssertEqual(persistedDate, date)
    }

    func testRemoveEmptyKey() {
        store?.remove(key: "")
        XCTAssertFalse(mockKeyValueService.removeCalled)
    }

    func testRemove() {
        store?.remove(key: INT_KEY)
        XCTAssertTrue(mockKeyValueService.removeCalled)
    }
}

class MockKeyValueService: NamedCollectionProcessing {
    var appGroup: String?
    func setAppGroup(_ appGroup: String?) {
        self.appGroup = appGroup
    }

    func getAppGroup() -> String? {
        return appGroup
    }

    var getResult: Any?
    var getCalled: Bool = false
    // helper to know if the mock is handling codable
    var shouldEncode: Bool = false
    func get(collectionName _: String, key _: String) -> Any? {
        getCalled = true
        if shouldEncode {
            let encoded = try? JSONEncoder().encode(getResult as? MockCoding)
            return encoded
        }

        return getResult
    }

    var setCalled: Bool = false
    var setValue: Any?
    // helper to know if the mock is handling codable
    var shouldDecode: Bool = false
    func set(collectionName _: String, key _: String, value: Any?) {
        setCalled = true
        if shouldDecode {
            if let data = value as? Data {
                setValue = try? JSONDecoder().decode(MockCoding.self, from: data)
            }
        } else {
            setValue = value
        }
    }

    var removeCalled: Bool = false
    func remove(collectionName _: String, key _: String) {
        removeCalled = true
    }

    var removeAllCalled: Bool = false
    func removeAll(collectionName _: String) {
        removeAllCalled = true
    }
}

/// Mock codable which should successfully persist
struct MockCoding: Codable {
    var id: Int
    var name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
