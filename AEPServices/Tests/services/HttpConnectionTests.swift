/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

@testable import AEPServices
import XCTest

class HttpConnectionTests: XCTestCase {
    func testResponseHttpHeader_Happy() throws {
        // setup
        let searchKey = "some-key"
        let response = HTTPURLResponse(url: URL(string: "https://someurl")!, statusCode: 200, httpVersion: nil, headerFields: ["some-key": "value"])
        let connection = HttpConnection(data: nil, response: response, error: nil)
        
        // test
        let iOS13Result = connection.responseHttpHeader(forKey: searchKey)
        let iOS12Result = connection.response?.lowercasedHeaders[searchKey.lowercased()] as? String
        
        // verify
        XCTAssertEqual("value", iOS13Result)
        XCTAssertEqual(iOS13Result, iOS12Result)
    }
    
    func testResponseHttpHeader_MisMatchedCasing() throws {
        // setup
        let searchKey = "some-key"
        let response = HTTPURLResponse(url: URL(string: "https://someurl")!, statusCode: 200, httpVersion: nil, headerFields: ["Some-Key": "value"])
        let connection = HttpConnection(data: nil, response: response, error: nil)
        
        // test
        let iOS13Result = connection.responseHttpHeader(forKey: searchKey)
        let iOS12Result = connection.response?.lowercasedHeaders[searchKey.lowercased()] as? String
        
        // verify
        XCTAssertEqual("value", iOS13Result)
        XCTAssertEqual(iOS13Result, iOS12Result)
    }
    
    func testResponseHttpHeader_MisMatchedCasingTwo() throws {
        // setup
        let searchKey = "Some-Key"
        let response = HTTPURLResponse(url: URL(string: "https://someurl")!, statusCode: 200, httpVersion: nil, headerFields: ["some-key": "value"])
        let connection = HttpConnection(data: nil, response: response, error: nil)
        
        // test
        let iOS13Result = connection.responseHttpHeader(forKey: searchKey)
        let iOS12Result = connection.response?.lowercasedHeaders[searchKey.lowercased()] as? String
        
        // verify
        XCTAssertEqual("value", iOS13Result)
        XCTAssertEqual(iOS13Result, iOS12Result)
    }
    
    func testResponseHttpHeader_DuplicateKeys() throws {
        // setup
        let searchKey = "some-key"
        let response = HTTPURLResponse(url: URL(string: "https://someurl")!, statusCode: 200, httpVersion: nil, headerFields: [
            "Some-Key": "value",
            "some-key": "anotherValue"])
        let connection = HttpConnection(data: nil, response: response, error: nil)
        
        // test
        let iOS13Result = connection.responseHttpHeader(forKey: searchKey)
        let iOS12Result = connection.response?.lowercasedHeaders[searchKey.lowercased()] as? String
        
        // verify
        /// in alignment with os behavior for `value(forHTTPHeaderField:)`,
        /// requesting a header with duplicate entries is non-deterministic
        let nonDeterministicResultMatchesOneValue13 = iOS13Result == "value" || iOS13Result == "anotherValue"
        let nonDeterministicResultMatchesOneValue12 = iOS12Result == "value" || iOS12Result == "anotherValue"
        XCTAssertTrue(nonDeterministicResultMatchesOneValue13)
        XCTAssertTrue(nonDeterministicResultMatchesOneValue12)
    }
    
    func testResponseHttpHeader_NoMatch() throws {
        // setup
        let searchKey = "something-else"
        let response = HTTPURLResponse(url: URL(string: "https://someurl")!, statusCode: 200, httpVersion: nil, headerFields: ["Some-Key": "value"])
        let connection = HttpConnection(data: nil, response: response, error: nil)
        
        // test
        let iOS13Result = connection.responseHttpHeader(forKey: searchKey)
        let iOS12Result = connection.response?.lowercasedHeaders[searchKey.lowercased()] as? String
        
        // verify
        XCTAssertNil(iOS13Result)
        XCTAssertEqual(iOS13Result, iOS12Result)
    }
    
    func testResponseHttpHeader_SpecialChars() throws {
        // setup
        let searchKey = "$om3-Ke?"
        let response = HTTPURLResponse(url: URL(string: "https://someurl")!, statusCode: 200, httpVersion: nil, headerFields: ["$om3-Ke?": "value"])
        let connection = HttpConnection(data: nil, response: response, error: nil)
        
        // test
        let iOS13Result = connection.responseHttpHeader(forKey: searchKey)
        let iOS12Result = connection.response?.lowercasedHeaders[searchKey.lowercased()] as? String
        
        // verify
        XCTAssertEqual("value", iOS13Result)
        XCTAssertEqual(iOS13Result, iOS12Result)
    }
    
    func testResponseHttpHeader_MixedCase() throws {
        // setup
        let searchKey = "soMe-KeY"
        let response = HTTPURLResponse(url: URL(string: "https://someurl")!, statusCode: 200, httpVersion: nil, headerFields: ["SOmE-kEy": "value"])
        let connection = HttpConnection(data: nil, response: response, error: nil)
        
        // test
        let iOS13Result = connection.responseHttpHeader(forKey: searchKey)
        let iOS12Result = connection.response?.lowercasedHeaders[searchKey.lowercased()] as? String
        
        // verify
        XCTAssertEqual("value", iOS13Result)
        XCTAssertEqual(iOS13Result, iOS12Result)
    }
}
