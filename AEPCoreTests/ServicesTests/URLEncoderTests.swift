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
@testable import AEPCore

class URLEncoderTests: XCTestCase {
    
    /// Tests that encoding an empty value is still empty
    func testEncodeEmpty() {
        XCTAssertTrue(URLEncoder.encode(value: "").isEmpty)
    }
    
    /// Tests that spaces are encoded correctly
    func testEncodeSpaces() {
        XCTAssertEqual("%20%20%20", URLEncoder.encode(value: "   "))
    }
    
    /// Tests that bracket symbols are encoded correctly
    func testEncodeBrackets() {
        XCTAssertEqual("%5B%5D", URLEncoder.encode(value: "[]"))
    }
    
    /// Tests that a percent symbol is encoded correctly
    func testEncodePercent() {
        XCTAssertEqual("%25", URLEncoder.encode(value: "%"))
    }
    
    /// Tests that a plus sign is encoded correctly
    func testEncodePlus() {
        XCTAssertEqual("%2B", URLEncoder.encode(value: "+"))
    }
    
    /// Tests that we can encode a complex string
    func testEncodeComplex() {
        XCTAssertEqual("~%21%40%23%24%25%5E%26%2A%28%29-%2B%3D%7C%7D%7B%5D%5B%5C%2F.%3C%2C%3E", URLEncoder.encode(value: "~!@#$%^&*()-+=|}{][\\/.<,>"))
    }
    
    /// Tests that encoding an empty value is still empty
    func testDecodeEmpty() {
        XCTAssertTrue(URLEncoder.decode(value: "").isEmpty)
    }
    
    /// Tests that spaces are decoded correctly
    func testDecodeSpaces() {
        XCTAssertEqual(URLEncoder.decode(value: "%20%20%20"), "   ")
    }
    
    /// Tests that bracket symbols are decoded correctly
    func testDecodeBrackets() {
        XCTAssertEqual(URLEncoder.decode(value: "%5B%5D"), "[]")
    }
    
    /// Tests that a percent symbol is decoded correctly
    func testDecodedPercent() {
        XCTAssertEqual(URLEncoder.decode(value: "%25"), "%")
    }
    
    /// Tests that a plus sign is decoded correctly
    func testDecodePlus() {
        XCTAssertEqual(URLEncoder.decode(value: "%2B"), "+")
    }
    
    /// Tests that we can decode a complex string
    func testDecodeComplex() {
        XCTAssertEqual(URLEncoder.decode(value: "~%21%40%23%24%25%5E%26%2A%28%29-%2B%3D%7C%7D%7B%5D%5B%5C%2F.%3C%2C%3E"), "~!@#$%^&*()-+=|}{][\\/.<,>")
    }
    
    /// Tests that when a string cannot be decoded, nil is returned
    func testDecodeInvalidEncoding() {
        XCTAssertTrue(URLEncoder.decode(value: "%ZZ").isEmpty)
    }
    
}
