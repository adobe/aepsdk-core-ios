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
    
    func testInt() throws {
        // setup
        dictionary["key"] = 552
        
        // test
        let result = dictionary.fnv1a32(mask: nil)
        
        // verify
        // key:552
        XCTAssertEqual(874166902, result)
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
