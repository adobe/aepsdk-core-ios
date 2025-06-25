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

import XCTest

@testable import AEPCore
@testable import AEPServices

/// Validations of this class are done against an online hash calculator: https://md5calc.com/hash/fnv1a32?str=
class EventData_FNV1A32Tests: XCTestCase {
    var dictionary: [String: Any] = [:]
    
    func testString() throws {
        // setup
        dictionary["key"] = "value"
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:value
        XCTAssertEqual(4007910315, result)
    }
    
    func testCharacter() throws {
        // setup
        dictionary["key"] = Character("a")
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:a
        XCTAssertEqual(135500217, result)
    }
    
    func testInt() throws {
        // setup
        dictionary["key"] = 552
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:552
        XCTAssertEqual(874166902, result)
    }
    
    func testInt8() throws {
        // setup
        dictionary["key"] = Int8(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testInt16() throws {
        // setup
        dictionary["key"] = Int16(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testInt32() throws {
        // setup
        dictionary["key"] = Int32(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testInt64() throws {
        // setup
        dictionary["key"] = Int64(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testUInt() throws {
        // setup
        dictionary["key"] = UInt(552)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:552
        XCTAssertEqual(874166902, result)
    }
    
    func testUInt8() throws {
        // setup
        dictionary["key"] = UInt8(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testUInt16() throws {
        // setup
        dictionary["key"] = UInt16(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testUInt32() throws {
        // setup
        dictionary["key"] = UInt32(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testUInt64() throws {
        // setup
        dictionary["key"] = UInt64(24)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:24
        XCTAssertEqual(2995581580, result)
    }
    
    func testFloat() throws {
        // setup
        dictionary["key"] = Float(5.52)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:5.52
        XCTAssertEqual(1449854826, result)
    }
        
    func testFloat32() throws {
        // setup
        dictionary["key"] = Float32(5.52)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:5.52
        XCTAssertEqual(1449854826, result)
    }
    
    func testFloat64() throws {
        // setup
        dictionary["key"] = Float64(5.52)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:5.52
        XCTAssertEqual(1449854826, result)
    }
    
    func testDouble() throws {
        // setup
        dictionary["key"] = 5.52
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:5.52
        XCTAssertEqual(1449854826, result)
    }
    
    func testBool() throws {
        // setup
        dictionary["key"] = false
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:false
        XCTAssertEqual(138493769, result)
    }
    
    func testOptionalString() throws {
        // setup
        let value: String? = "value"
        dictionary["key"] = value
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:value
        XCTAssertEqual(4007910315, result)
    }
    
    func testOptionalInt() throws {
        // setup
        let value: Int? = 552
        dictionary["key"] = value
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:552
        XCTAssertEqual(874166902, result)
    }
    
    func testOptionalDouble() throws {
        // setup
        let value: Double? = 5.52
        dictionary["key"] = value
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:5.52
        XCTAssertEqual(1449854826, result)
    }
    
    func testOptionalBool() throws {
        // setup
        let value: Bool? = false
        dictionary["key"] = value
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:false
        XCTAssertEqual(138493769, result)
    }
    
    func testAnyCodableString() throws {
        // setup
        dictionary["key"] = AnyCodable(stringLiteral: "value")
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:value
        XCTAssertEqual(4007910315, result)
    }
    
    func testAnyCodableInt() throws {
        // setup
        dictionary["key"] = AnyCodable(integerLiteral: 552)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:552
        XCTAssertEqual(874166902, result)
    }
    
    func testAnyCodableBool() throws {
        // setup
        dictionary["key"] = AnyCodable(booleanLiteral: false)
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:false
        XCTAssertEqual(138493769, result)
    }
    
    func testMaskKeyIsPresentInDictionary() throws {
        // setup
        dictionary["key"] = "value"
        dictionary["unusedKey"] = "unusedValue"
        let mask = ["key"]
        
        // test
        let result = dictionary.fnv1a32(mask: mask)
        
        // verify
        // key:value
        XCTAssertEqual(4007910315, result)
    }
    
    func testMaskKeyNotPresentInDictionary() throws {
        // setup
        dictionary["key"] = "value"
        let mask = ["404"]
        
        // test
        let result = dictionary.fnv1a32(mask: mask)
        
        // verify
        // no hash generated
        XCTAssertEqual(0, result)
    }
    
    func testDictionaryGetsAsciiSorted() throws {
        // setup
        dictionary["key"] = "value"
        dictionary["number"] = 1234
        dictionary["UpperCase"] = "abc"
        dictionary["_underscore"] = "score"
        let anotherDictionary: [String: Any] = [
            "_underscore": "score",
            "UpperCase": "abc",
            "number": 1234,
            "key": "value"
        ]
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        let result2 = anotherDictionary.fnv1a32(mask: nil)
        
        // verify
        // UpperCase:abc_underscore:scorekey:valuenumber:1234
        XCTAssertEqual(960895195, result)
        XCTAssertEqual(result, result2)
    }
    
    func testBigSort() throws {
        // setup
        dictionary["a"] = "1"
        dictionary["A"] = "2"
        dictionary["ba"] = "3"
        dictionary["Ba"] = "4"
        dictionary["Z"] = "5"
        dictionary["z"] = "6"
        dictionary["r"] = "7"
        dictionary["R"] = "8"
        dictionary["bc"] = "9"
        dictionary["Bc"] = "10"
        dictionary["1"] = 1
        dictionary["222"] = 222
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // 1:1222:222A:2Ba:4Bc:10R:8Z:5a:1ba:3bc:9r:7z:6
        XCTAssertEqual(2933724447, result)
    }
    
    func testArrayOfMaps() throws {
        // setup - equivalent to Android testGetFnv1aHash_ArrayOfMaps
        let map1: [String: Any] = [
            "aaa": "1",
            "zzz": true
        ]
        let map2: [String: Any] = [
            "number": 123,
            "double": 1.5
        ]
        let list: [Any] = [map1, map2]
        dictionary["key"] = list
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify flattened map string "key.0.aaa:1key.0.zzz:truekey.1.double:1.5key.1.number:123"
        XCTAssertEqual(2410759527, result)
    }
    
    func testArrayOfLists() throws {
        // setup - equivalent to Android testGetFnv1aHash_ArrayOfLists
        let innerList: [Any] = ["aaa", "zzz", 111]
        let innerList2: [Any] = ["2"]
        let list: [Any] = [innerList, innerList2]
        dictionary["key"] = list
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify flattened map string "key.0.0:aaakey.0.1:zzzkey.0.2:111key.1.0:2"
        XCTAssertEqual(2441202563, result)
    }
    
    func testWithEmptyMask() throws {
        // setup - equivalent to Android testGetFnv1aHash_WithEmptyMask
        dictionary["a"] = "1"
        dictionary["b"] = "2"
        let mask: [String] = []
        
        // test
        let result = dictionary.fnv1a32(mask: mask)
        
        // verify - no hash generated due to empty mask
        XCTAssertEqual(0, result)
    }
    
    func testNullAndEmptyMapValuesPresent_WithKeysForNullAndEmptyValuesInMask() throws {
        // setup - equivalent to Android testGetFnv1aHash_NullAndEmptyMapValuesPresent_WithKeysForNullAndEmptyValuesInMask
        dictionary["a"] = "1"
        dictionary["b"] = "2"
        dictionary["c"] = ""
        dictionary["d"] = NSNull()
        let mask = ["c", "d"]
        
        // test
        let result = dictionary.fnv1a32(mask: mask)
        
        // verify - no hash generated due to mask keys being present for null and empty values
        XCTAssertEqual(0, result)
    }
    
    func testNullAndEmptyMapValuesPresentInInnerMap_WithAllKeysInMask() throws {
        // setup - equivalent to Android testGetFnv1aHash_NullAndEmptyMapValuesPresentInInnerMap_WithAllKeysInMask
        let inner: [String: Any] = [
            "a": "1",
            "b": "2",
            "c": "",
            "d": NSNull()
        ]
        dictionary["inner"] = inner
        let mask = ["inner.a", "inner.b"]
        
        // test
        let result = dictionary.fnv1a32(mask: mask)
        
        // verify flattened map string "inner.a:1inner.b:2"
        XCTAssertEqual(3328417429, result)
    }
    
    func testNullAndEmptyMapValuesPresentInMultipleNestedInnerMaps() throws {
        // setup - equivalent to Android testGetFnv1aHash_NullAndEmptyMapValuesPresentInMultipleNestedInnerMaps
        let nestedNestedInner: [String: Any] = [
            "k": "5",
            "l": "6",
            "m": "",
            "n": NSNull()
        ]
        let nestedInner: [String: Any] = [
            "f": "3",
            "g": "4",
            "h": "",
            "i": NSNull(),
            "nestedNestedInner": nestedNestedInner
        ]
        let inner: [String: Any] = [
            "a": "1",
            "b": "2",
            "c": "",
            "d": NSNull(),
            "nestedInner": nestedInner
        ]
        dictionary["inner"] = inner
        let mask = [
            "inner.a",
            "inner.b",
            "inner.nestedInner.g",
            "inner.nestedInner.nestedNestedInner.l"
        ]
        
        // test
        let result = dictionary.fnv1a32(mask: mask)
        
        // verify flattened map string "inner.a:1inner.b:2inner.nestedInner.g:4inner.nestedInner.nestedNestedInner.l:6"
        XCTAssertEqual(4160127196, result)
    }
    
    func testNullAndEmptyMapValuesPresent_WithNoMask() throws {
        // setup - equivalent to Android testGetFnv1aHash_NullAndEmptyMapValuesPresent_WithNoMask
        dictionary["a"] = "1"
        dictionary["b"] = "2"
        dictionary["c"] = ""
        dictionary["d"] = NSNull()
        dictionary["e"] = 3
        dictionary["f"] = "4"
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify flattened map string "a:1b:2e:3f:4" (null and empty values are filtered out)
        XCTAssertEqual(3916945161, result)
    }
}
