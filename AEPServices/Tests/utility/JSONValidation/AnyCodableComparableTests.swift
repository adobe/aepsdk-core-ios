/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import XCTest
import AEPServices
@testable import AEPServicesMocks

class AnyCodableComparableTests: XCTestCase {

    // MARK: - Optional Conformance

    func testOptional_WhenNil_ReturnsNil() {
        let optional: String? = nil
        XCTAssertNil(optional.toAnyCodable())
    }

    func testOptional_WhenValue_ReturnsUnwrappedValue() {
        let optional: String? = "test"
        let result = optional.toAnyCodable()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.value as? String, "test")
    }

    func testOptional_NestedOptional_UnwrapsRecursively() {
        let nested: String?? = "test"
        
        let result = nested.toAnyCodable()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.value as? String, "test")
    }

    // MARK: - Dictionary Conformance

    func testDictionary_ConvertsValuesToAnyCodable() {
        let dict: [String: Any] = [
            "string": "value",
            "int": 123,
            "bool": true
        ]
        
        let result = dict.toAnyCodable()
        
        XCTAssertNotNil(result)
        guard let value = result?.value as? [String: Any] else {
            XCTFail("Expected [String: Any] value")
            return
        }
        
        XCTAssertEqual(value["string"] as? String, "value")
        XCTAssertEqual(value["int"] as? Int, 123)
        XCTAssertEqual(value["bool"] as? Bool, true)
    }

    func testDictionary_NestedDictionary_RecursivelyConverts() {
        let dict: [String: Any] = [
            "nested": [
                "key": "value"
            ]
        ]
        
        let result = dict.toAnyCodable()
        
        XCTAssertNotNil(result)
    
        guard let unwrappedRoot = result?.value as? [String: Any] else {
            XCTFail("Root dictionary should be [String: Any]")
            return
        }
        
        if let nested = unwrappedRoot["nested"] as? [String: Any] {
             XCTAssertEqual(nested["key"] as? String, "value")
        } else if let nested = unwrappedRoot["nested"] as? [String: AnyCodable] {
             XCTAssertEqual(nested["key"]?.value as? String, "value")
        } else if let nestedAnyCodable = unwrappedRoot["nested"] as? AnyCodable,
                  let nested = nestedAnyCodable.value as? [String: Any] {
             XCTAssertEqual(nested["key"] as? String, "value")
        } else {
             XCTFail("Nested dictionary has unexpected type: \(type(of: unwrappedRoot["nested"] ?? "nil"))")
        }
    }

    // MARK: - String Conformance (JSON Parsing)

    func testString_ValidJSON_ParsesToAnyCodable() {
        let json = """
        {
            "key": "value",
            "number": 123
        }
        """
        
        let result = json.toAnyCodable()
        
        XCTAssertNotNil(result)
        // Should parse into a Dictionary (AnyCodable wrapping a dictionary)
        let dict = result?.value as? [String: Any]
        XCTAssertEqual(dict?["key"] as? String, "value")
        XCTAssertEqual(dict?["number"] as? Int, 123)
    }

    func testString_InvalidJSON_ReturnsSelf() {
        let notJson = "Just a regular string"
        
        // Since we now fallback to raw string if JSON parsing fails,
        // this should return the string wrapped in AnyCodable
        let result = notJson.toAnyCodable()
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.value as? String, notJson)
    }

    func testString_JSONList_ParsesToArray() {
        let jsonList = """
        ["one", "two"]
        """
        
        let result = jsonList.toAnyCodable()
        
        XCTAssertNotNil(result)
        let array = result?.value as? [Any]
        XCTAssertEqual(array?.count, 2)
        XCTAssertEqual(array?.first as? String, "one")
    }

    // MARK: - AnyCodable Conformance

    func testAnyCodable_ReturnsSelf() {
        let original = AnyCodable("test")
        let result = original.toAnyCodable()
        
        // Should be the same instance/value
        XCTAssertEqual(result?.value as? String, "test")
    }

    // MARK: - NetworkRequest Conformance

    func testNetworkRequest_WithValidJSONPayload_ConvertsPayload() {
        let jsonPayload = """
        {"key": "value"}
        """
        let request = NetworkRequest(
            url: URL(string: "https://example.com")!,
            httpMethod: .post,
            connectPayload: jsonPayload,
            httpHeaders: [:],
            connectTimeout: 5,
            readTimeout: 5
        )
        
        let result = request.toAnyCodable()
        
        XCTAssertNotNil(result)
        let dict = result?.value as? [String: Any]
        XCTAssertEqual(dict?["key"] as? String, "value")
    }

    func testNetworkRequest_WithInvalidPayload_ReturnsNil() {
        let invalidPayload = "not json"
        let request = NetworkRequest(
            url: URL(string: "https://example.com")!,
            httpMethod: .post,
            connectPayload: invalidPayload,
            httpHeaders: [:],
            connectTimeout: 5,
            readTimeout: 5
        )
        
        let result = request.toAnyCodable()
        
        XCTAssertNil(result)
    }
}

