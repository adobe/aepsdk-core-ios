//
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


import XCTest

@testable import AEPServices
@testable import AEPCore

class SDKInstanceIdentifierTests: XCTestCase {
    
    let maxCharacterLength = 100

    let validIdentifiers = [
        "hello-world",
        "hello_world",
        "hello.world",
        "hello!",
        "world?",
        "(hello)",
        "[hello]",
        "{hello}",
        "hello's",
        "hello\"s",
        "&",
        "%",
        "#",
        "*",
        "@hello",
        "\u{21}", // unicode for '!'
        "美美",
        "请您首先亲临任一网点更新邮寄地址"
        ]
    
    let invalidIdentifiers = [
        "", // empty string
        " ", // space
        "   ", // tab
        "hello/world", // forward slash
        "hello\\world", // backward slash
        "hello world",
        "https://adobe.com",
        ":",
        "$",
        "<>",
        "+",
        "=",
        "|",
        "`", // backtick
        "/usr/",
        "//usr",
        "~usr",
        "\u{24}", // unicode for '$'
        "\u{00AD}", // soft hyphen control character
        "\u{1F496}", // heart emoji symbol
        "\u{000A}", // newline character
        "\u{000D}", // newline character
        "\u{0085}", // newline character
        "\u{2028}", // newline character
        "\u{2029}", // newline character
        "\u{0009}", // whitespace character
        ]
    
    override func setUp() {
    }
    
    func testDefaultInitializedFromEnum() {
        let instance: SDKInstanceIdentifier = .default
        
        XCTAssertEqual(nil, instance.id)
        XCTAssertEqual("default-instance", instance.description)
    }
    
    func testDefaultInitializedFromInit() {
        guard let instance = SDKInstanceIdentifier(id: "default-instance") else {
            XCTFail("SDKInstanceIdentifier init returned nil.")
            return
        }
        
        XCTAssertEqual(nil, instance.id)
        XCTAssertEqual("default-instance", instance.description)
    }
    
    func testIDInitializedFromEnum() {
        let instance: SDKInstanceIdentifier = .id("happy")
        
        XCTAssertEqual("happy", instance.id)
        XCTAssertEqual("happy", instance.description)
    }
    
    func testIDInitializedFromInit() {
        guard let instance = SDKInstanceIdentifier(id: "happy") else {
            XCTFail("SDKInstanceIdentifier init returned nil.")
            return
        }
        
        XCTAssertEqual("happy", instance.id)
        XCTAssertEqual("happy", instance.description)
    }
    
    func testEmptyStringFailsInitialization() {
        XCTAssertNil(SDKInstanceIdentifier(id: ""))
    }
    
    func testEmptyStringInitalizedFromEnum() {
        let instance: SDKInstanceIdentifier = .id("")
        
        XCTAssertEqual("", instance.id)
        XCTAssertEqual("", instance.description)
    }
    
    func testStringExtensionInstanceAwareName() {
        let instance: SDKInstanceIdentifier = .id("tenant")
        let string = "message"
        XCTAssertEqual("message-tenant", string.instanceAwareName(for: instance))
    }
    
    func testStringExtensionInstanceAwareNameDefault() {
        let instance: SDKInstanceIdentifier = .default
        let string = "message"
        XCTAssertEqual("message", string.instanceAwareName(for: instance))
    }
    
    func testStringExtensionInstanceAwareFilename() {
        let instance: SDKInstanceIdentifier = .id("tenant")
        let string = "filename"
        XCTAssertEqual("aep.tenant.filename", string.instanceAwareFilename(for: instance))
    }
    
    func testStringExtensionInstanceAwareFilenameDefault() {
        let instance: SDKInstanceIdentifier = .default
        let string = "filename"
        XCTAssertEqual("filename", string.instanceAwareFilename(for: instance))
    }
    
    func testListOfValidNamesPassInitialization() {
        for i in validIdentifiers {
            XCTAssertNotNil(SDKInstanceIdentifier(id: i), "SDKInstanceIdentifier init returned nil for id '\(i)' but expected to pass.")
        }
    }
    
    func testListOfValidNamesPassFileCreation() {
        NamedCollectionDataStore.clear()
        for i in validIdentifiers {
            XCTAssertEqual("testValue", createFile(name: i))
        }
        print("Application directory: \(NSHomeDirectory())")
    }
    
    func testListOfInvalidNamesFailInitialization() {
        for i in invalidIdentifiers {
            XCTAssertNil(SDKInstanceIdentifier(id: i), "SDKInstanceIdentifier init returned non-nil for id '\(i)' but expected init to fail with nil.")
        }
    }
    
    func testLongIdentifier150charactersPassesInitialization() {
        var id = ""
        for _ in 1...maxCharacterLength {
            id.append("a")
        }
        
        XCTAssertNotNil(SDKInstanceIdentifier(id: id), "SDKInstanceIdentifier init returned nil for id '\(id)' but expected to pass.")
    }
    
    func testLongIdentifier151charactersFailsInitialization() {
        var id = ""
        for _ in 1...(maxCharacterLength+1) {
            id.append("a")
        }
        
        XCTAssertNil(SDKInstanceIdentifier(id: id), "SDKInstanceIdentifier init returned non-nil for id '\(id)' but expected init to fail with nil.")
    }
    
    func createFile(name: String) -> String? {
        let service = FileSystemNamedCollection()
        service.set(collectionName: "com.adobe.instance.test." + name, key: "testKey", value: "testValue")
        return service.get(collectionName: "com.adobe.instance.test." + name, key: "testKey") as? String
    }
}
