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
@testable import AEPCoreMocks
@testable import AEPRulesEngine
import AEPServices

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
    
    func testTimestampUMatchers() {
        Log.logFilter = .debug
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_testTimestampu", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            XCTAssertTrue(false)
            return
        }
        
        let runtime = TestableExtensionRuntime()
        let event = Event(name: "test", type: "type", source: "source", data: [:])
        runtime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["devicename": "abc"]], status: .set))

        /// Then: this json rules should be parsed to `LaunchRule` objects
        let rules = JSONRulesParser.parse(data)
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let transformer = LaunchRuleTransformer(runtime: runtime)
        let traversableTokenFinder = TokenFinder(event: event, extensionRuntime: runtime)
        
        /// Then: this json rules should be parsed to `LaunchRule` objects
        XCTAssertEqual(1, rules?.count)
        XCTAssertTrue(rules?[0].condition is LogicalExpression)
        
        let context = Context(data: traversableTokenFinder, evaluator: rulesEngine.evaluator, transformer: transformer.transformer)
        
        let result = rules?.first?.condition.evaluate(in: context)
        XCTAssertEqual(true, result?.value)
    }
    
    func testAddRules() {
        Log.logFilter = .debug
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_1", withExtension: "json"), let data = try? Data(contentsOf: url) else {
            XCTAssertTrue(false)
            return
        }
        
        let runtime = TestableExtensionRuntime()
        runtime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["devicename": "abc"]], status: .set))

        /// Then: this json rules should be parsed to `LaunchRule` objects
        guard let rules = JSONRulesParser.parse(data) else {
            XCTFail("unable to properly parse rules")
            return
        }
        
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        XCTAssertEqual(0, rulesEngine.rulesEngine.rules.count)
        
        /// add rules to existing rules engine
        XCTAssertEqual(2, rules.count)
        
        rulesEngine.addRules(rules)
        XCTAssertEqual(2, rulesEngine.rulesEngine.rules.count)
        
        rulesEngine.addRules(rules)
        XCTAssertEqual(4, rulesEngine.rulesEngine.rules.count)
    }
    
    func testProcessWithCallback() {
        // setup
        Log.logFilter = .debug
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_1", withExtension: "json"), let data = try? Data(contentsOf: url) else {
            XCTAssertTrue(false)
            return
        }
        
        let runtime = TestableExtensionRuntime()
        let fakeLifecycleData = [
            "lifecyclecontextdata": [
                "carriername": "AT&T",
                "devicename": "abc"
            ]
        ]
        runtime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: fakeLifecycleData, status: .set))
        guard let rules = JSONRulesParser.parse(data) else {
            XCTFail("unable to properly parse rules")
            return
        }
        
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        XCTAssertEqual(0, rulesEngine.rulesEngine.rules.count)
        rulesEngine.addRules(rules)
        XCTAssertEqual(2, rulesEngine.rulesEngine.rules.count)
        
        let testEventData: [String: Any] = [
            "lifecyclecontextdata": [
                "launchevent": true
            ]
        ]
        let testEvent = Event(name: "testing_rules",
                              type: "com.adobe.eventType.lifecycle",
                              source: "com.adobe.eventSource.responseContent",
                              data: testEventData)
        
        // test
        let consequences = rulesEngine.evaluate(event: testEvent)
        
        // verify
        XCTAssertEqual(1, consequences?.count)
        let urlString = consequences?.first?.details["url"] as? String
        XCTAssertTrue(urlString?.contains("device=abc") ?? false) // verify token replacement occurred
    }
}
