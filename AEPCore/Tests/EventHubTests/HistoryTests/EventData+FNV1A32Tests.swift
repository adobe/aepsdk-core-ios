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
}
