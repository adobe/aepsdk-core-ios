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

class AnyCodableTests: XCTestCase {

    func testDecodeSimpleTypes() throws {
        let jsonData = """
        {
            "stringKey": "stringValue",
            "boolKey": true,
            "doubleKey": 123.456,
            "intKey": 123,
            "intKey1": 1,
            "nullKey": null
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)
        
        XCTAssertEqual(decoded["stringKey"]?.value as! String, "stringValue")
        XCTAssertEqual(decoded["boolKey"]?.value as! Bool, true)
        XCTAssertEqual(decoded["doubleKey"]?.value as! Double, 123.456)
        XCTAssertEqual(decoded["intKey"]?.value as! Int, 123)
        XCTAssertEqual(decoded["intKey1"]?.value as! Int, 1)
        XCTAssertNil(decoded["nullKey"]?.value)
    }
    
    func testDecodeWithArrayAnyCodable() throws {
        let jsonData = """
        {
            "anyCodableArray": ["stringValue", true, 123.456, 123]
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)
        let anyCodableArray = decoded["anyCodableArray"]?.value as! [Any]
        
        XCTAssertEqual(anyCodableArray[0] as! String, "stringValue")
        XCTAssertEqual(anyCodableArray[1] as! Bool, true)
        XCTAssertEqual(anyCodableArray[2] as! Double, 123.456)
        XCTAssertEqual(anyCodableArray[3] as! Int, 123)
    }
    
    func testDecodeWithDictAnyCodable() throws {
        let jsonData = """
        {
            "anyCodableDict": {
                                "stringKey": "stringValue",
                                "boolKey": true,
                                "doubleKey": 123.456,
                                "intKey": 123
                              }
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)["anyCodableDict"]?.value as! [String: Any]
        
        XCTAssertEqual(decoded["stringKey"] as! String, "stringValue")
        XCTAssertEqual(decoded["boolKey"] as! Bool, true)
        XCTAssertEqual(decoded["doubleKey"] as! Double, 123.456)
        XCTAssertEqual(decoded["intKey"] as! Int, 123)
    }
    

    func testEncodeSimpleTypes() throws {
        //let doubleValue: AnyCodable = AnyCodable(doubleLiteral: 123.456)
        let dictionary: [String: AnyCodable] = [
            "stringKey": "stringValue",
            "boolKey": true,
            "doubleKey": 123.456,
            "intKey": 123,
            "intKey1": 1,
            "intKey2": 0,
            "intKey3": AnyCodable(NSNumber(0))
        ]

        let json = try JSONEncoder().encode(dictionary)
        let encodedJSONObject = try JSONSerialization.jsonObject(with: json, options: []) as! NSDictionary

        let expected = """
        {
            "stringKey": "stringValue",
            "boolKey": true,
            "doubleKey": 123.456,
            "intKey": 123,
            "intKey1": 1,
            "intKey2": 0,
            "intKey3": 0
        }
        """.data(using: .utf8)!
        let expectedJSONObject = try JSONSerialization.jsonObject(with: expected, options: []) as! NSDictionary

        XCTAssertEqual(encodedJSONObject, expectedJSONObject)
    }
    
    func testEncodeSimpleTypesFromDict() throws {
        let dictionary: [String: Any] = [
            "stringKey": "stringValue",
            "boolKey": true,
            "doubleKey": 123.456,
            "intKey": 123,
            "intKey1": 1,
            "intKey2": 0,
            "intKey3": NSNumber(0)
        ]

        let json = try JSONEncoder().encode(AnyCodable.from(dictionary: dictionary)!)
        let encodedJSONObject = try JSONSerialization.jsonObject(with: json, options: []) as! NSDictionary

        let expected = """
        {
            "stringKey": "stringValue",
            "boolKey": true,
            "doubleKey": 123.456,
            "intKey": 123,
            "intKey1": 1,
            "intKey2": 0,
            "intKey3": 0
        }
        """.data(using: .utf8)!
        let expectedJSONObject = try JSONSerialization.jsonObject(with: expected, options: []) as! NSDictionary

        XCTAssertEqual(encodedJSONObject, expectedJSONObject)
    }
    
    func testEncodeWithAnyCodableArray() throws {
        let dictionary: [String: AnyCodable] = [
            "anyCodableArray": ["stringValue", true, 123.456, 123]
        ]
        
        let json = try JSONEncoder().encode(dictionary)
        let encodedJSONObject = try JSONSerialization.jsonObject(with: json, options: []) as! NSDictionary
        
        let expected = """
        {
            "anyCodableArray": ["stringValue", true, 123.456, 123]
        }
        """.data(using: .utf8)!
        let expectedJSONObject = try JSONSerialization.jsonObject(with: expected, options: []) as! NSDictionary

        XCTAssertEqual(encodedJSONObject, expectedJSONObject)
    }


}
