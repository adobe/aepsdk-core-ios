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

@testable import AEPCore
import AEPCoreMocks
import XCTest

class LaunchRuleTransformerTests: XCTestCase {

    let mockRuntime = TestableExtensionRuntime()

    func testStringFromInt() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "string", parameter: 3)
        XCTAssertEqual("3", result as? String)
    }

    func testStringFromBool() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "string", parameter: true)
        XCTAssertEqual("true", result as? String)
    }

    func testStringFromDouble() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "string", parameter: 3.33)
        XCTAssertTrue((result as? String)?.starts(with: "3.3") ?? false)
    }

    func testStringFromString() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "string", parameter: "something")
        XCTAssertEqual("something", result as? String)
    }

    func testIntFromInt() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "int", parameter: 3)
        XCTAssertEqual(3, result as? Int)
    }

    func testIntFromBool() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "int", parameter: true)
        XCTAssertEqual(1, result as? Int)
    }

    func testIntFromDouble() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "int", parameter: 3.33)
        XCTAssertEqual(3, result as? Int)
    }

    func testIntFromStringValid() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "int", parameter: "3")
        XCTAssertEqual(3, result as? Int)
    }

    func testIntFromStringInvalid() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "int", parameter: "something")
        XCTAssertNil(result as? Int)
    }

    func testDoubleFromInt() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "double", parameter: 3)
        XCTAssertEqual(3, result as? Double)
    }

    func testDoubleFromBool() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "double", parameter: true)
        XCTAssertEqual(1, result as? Double)
    }

    func testDoubleFromDouble() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "double", parameter: 3.33)
        XCTAssertEqual(3.33, result as? Double ?? 0.0,accuracy: 0.01)
    }

    func testDoubleFromStringValid() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "double", parameter: "3.33")
        XCTAssertEqual(3.33, result as? Double ?? 0.0,accuracy: 0.01)
    }

    func testDoubleFromStringInvalid() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "double", parameter: "something")
        XCTAssertNil(result as? Double)
    }

    func testBoolFromInt0() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "bool", parameter: 0)
        XCTAssertFalse(result as? Bool ?? false)
    }

    func testBoolFromInt1() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "bool", parameter: 1)
        XCTAssertTrue(result as? Bool ?? false)
    }

    func testBoolFromIntRandom() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "bool", parameter: 5)
        XCTAssertFalse(result as? Bool ?? false)
    }

    func testBoolFromBool() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "bool", parameter: true)
        XCTAssertTrue(result as? Bool ?? false)
    }

    func testBoolFromDouble() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "bool", parameter: 1.0)
        XCTAssertTrue(result as? Bool ?? false)
    }

    func testBoolFromStringValid() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "bool", parameter: "true")
        XCTAssertTrue(result as? Bool ?? false)
    }

    func testBoolFromStringInvalid() {
        let transform = LaunchRuleTransformer(runtime: mockRuntime).transformer
        let result = transform.transform(name: "bool", parameter: "something")
        XCTAssertFalse(result as? Bool ?? false)
    }
}
