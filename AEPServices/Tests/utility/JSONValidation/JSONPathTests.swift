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
@testable import AEPServicesMocks

class JSONPathTests: XCTestCase {

    // MARK: - Parsing Tests

    func testParse_SimpleKey() {
        let path: JSONPath = "key"
        XCTAssertEqual(path.components.count, 1)
        XCTAssertEqual(path.components[0], .key("key"))
    }

    func testParse_NestedKeys() {
        let path: JSONPath = "parent.child"
        XCTAssertEqual(path.components.count, 2)
        XCTAssertEqual(path.components[0], .key("parent"))
        XCTAssertEqual(path.components[1], .key("child"))
    }

    func testParse_ArrayIndex() {
        let path: JSONPath = "items[0]"
        XCTAssertEqual(path.components.count, 2)
        XCTAssertEqual(path.components[0], .key("items"))
        XCTAssertEqual(path.components[1], .index(0))
    }

    func testParse_ChainedArrayIndices() {
        let path: JSONPath = "matrix[0][1]"
        XCTAssertEqual(path.components.count, 3)
        XCTAssertEqual(path.components[0], .key("matrix"))
        XCTAssertEqual(path.components[1], .index(0))
        XCTAssertEqual(path.components[2], .index(1))
    }

    func testParse_KeyAfterArray() {
        let path: JSONPath = "users[0].name"
        XCTAssertEqual(path.components.count, 3)
        XCTAssertEqual(path.components[0], .key("users"))
        XCTAssertEqual(path.components[1], .index(0))
        XCTAssertEqual(path.components[2], .key("name"))
    }

    func testParse_Wildcards() {
        let path: JSONPath = "items[*].*.id"
        XCTAssertEqual(path.components.count, 4)
        XCTAssertEqual(path.components[0], .key("items"))
        XCTAssertEqual(path.components[1], .wildcardIndex)
        XCTAssertEqual(path.components[2], .wildcardKey)
        XCTAssertEqual(path.components[3], .key("id"))
    }

    // MARK: - Escaping Tests

    func testParse_EscapedDot() {
        let path: JSONPath = "user\\.name"
        XCTAssertEqual(path.components.count, 1)
        XCTAssertEqual(path.components[0], .key("user.name"))
    }

    func testParse_EscapedBrackets() {
        let path: JSONPath = "key\\[0\\]"
        XCTAssertEqual(path.components.count, 1)
        XCTAssertEqual(path.components[0], .key("key[0]"))
    }

    func testParse_EscapedWildcard() {
        let path: JSONPath = "\\*"
        XCTAssertEqual(path.components.count, 1)
        XCTAssertEqual(path.components[0], .key("*"))
    }

    func testParse_ComplexEscaping() {
        // "com.adobe.key"[0] -> key "com.adobe.key", index 0
        let path: JSONPath = "com\\.adobe\\.key[0]"
        XCTAssertEqual(path.components.count, 2)
        XCTAssertEqual(path.components[0], .key("com.adobe.key"))
        XCTAssertEqual(path.components[1], .index(0))
    }

    // MARK: - Edge Cases

    func testParse_Root() {
        let path = JSONPath.root
        XCTAssertTrue(path.isRoot)
        XCTAssertEqual(path.components.count, 0)
    }

    func testParse_EmptyString() {
        let path: JSONPath = ""
        XCTAssertEqual(path.components.count, 1)
        XCTAssertEqual(path.components[0], .key(""))
    }

    func testParse_InvalidArrayIndex_Crashes() {
        // "items[abc]" -> "abc" is not a valid Int.
        // This is strictly validated and causes a fatalError.
        // Cannot test fatalError in XCTest without a separate test runner/harness.
        // Uncommenting the line below should crash the test suite:
        // let _ = JSONPath("items[abc]")
    }

    // MARK: - Operations

    func testAppending_Component() {
        let root = JSONPath("users")
        let path = root.appending(.index(0))
        
        XCTAssertEqual(path.description, "users[0]")
        XCTAssertEqual(path.components.count, 2)
    }

    func testAppending_Path() {
        let part1 = JSONPath("users[0]")
        let part2 = JSONPath("profile.name")
        let combined = part1.appending(part2)
        
        XCTAssertEqual(combined.description, "users[0].profile.name")
        XCTAssertEqual(combined.components.count, 4)
    }

    func testParent() {
        let path = JSONPath("users[0].name")
        let parent = path.parent
        
        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.description, "users[0]")
        
        let grandParent = parent?.parent
        XCTAssertNotNil(grandParent)
        XCTAssertEqual(grandParent?.description, "users")
        
        let greatGrandParent = grandParent?.parent
        XCTAssertNotNil(greatGrandParent)
        XCTAssertTrue(greatGrandParent?.isRoot ?? false) // Parent of "users" is Root
        
        let rootParent = greatGrandParent?.parent
        XCTAssertNil(rootParent) // Parent of Root is nil
    }

    // MARK: - Description

    func testDescription() {
        let path = JSONPath.root
            .appending(.key("a"))
            .appending(.wildcardIndex)
            .appending(.wildcardKey)
            .appending(.index(1))
        
        XCTAssertEqual(path.description, "a[*].*[1]")
    }
}

