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
import Foundation
import XCTest

@testable import AEPCore
import AEPServices
@testable import SwiftRulesEngine

class AEPRulesEngineTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTokenReplacement() {
        // When: load rules from a json file
        Log.logFilter = .debug
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_1", withExtension: "json"), let data = try? Data(contentsOf: url) else {
            XCTAssertTrue(false)
            return
        }
        /// Then: this json rules should be parsed to `LaunchRule` objects
        let rules = JSONRulesParser.parse(data)
        let rulesEngine = LaunchRulesEngine()
        // ~state.com.adobe.module.lifecycle/lifecyclecontextdata.devicename
        let result = rulesEngine.replaceToken(for: rules[0].consequences[0], data: ["~state": ["com": ["adobe": ["module": ["lifecycle/lifecyclecontextdata": ["devicename": "abc"]]]]]])
        // http://adobe.com/device=abc
        if let detail = result.detailDict["detail"], detail is [String: Any] {
            let url = (detail as! [String: Any])["url"] as! String
            XCTAssertEqual("http://adobe.com/device=abc", url)
        } else {
            XCTAssertTrue(false)
        }
    }
}

extension Array: Traversable {
    public subscript(traverse sub: String) -> Any? {
        if let index = Int(sub) {
            return self[index]
        }
        return nil
    }
}

extension Dictionary: Traversable where Key == String {
    public subscript(traverse sub: String) -> Any? {
        let result = self[sub]
        if result is AnyCodable {
            return (result as! AnyCodable).value
        }
        return result
    }
}
