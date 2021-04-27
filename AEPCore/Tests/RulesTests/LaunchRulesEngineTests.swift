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
@testable import AEPCoreMocks
import AEPServices
@testable import AEPRulesEngine

class LaunchRulesEngineTests: XCTestCase {
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
        let runtime = TestableExtensionRuntime()
        let event = Event(name: "test", type: "type", source: "source", data: [:])
        runtime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["devicename": "abc"]], status: .set))

        /// Then: this json rules should be parsed to `LaunchRule` objects
        let rules = JSONRulesParser.parse(data)
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        // ~state.com.adobe.module.lifecycle/lifecyclecontextdata.devicename
        let tokens = TokenFinder(event: event, extensionRuntime: runtime)
        let result = rulesEngine.replaceToken(for: (rules?[0].consequences[0])!, data: tokens)
        // http://adobe.com/device=abc

        let urlString = result.details["url"] as! String
        XCTAssertEqual("http://adobe.com/device=abc", urlString)
    }
}
