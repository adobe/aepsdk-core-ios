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

import AEPServices

@testable import AEPCore
@testable import AEPCoreMocks
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
    
    // MARK: - Reevaluation Interceptor Tests
    
    func testSetReevaluationInterceptor() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        
        // When
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        // Then - no crash, interceptor is set (we can't directly verify since it's private)
        // The actual behavior is tested in the following tests
    }
    
    func testReevaluationInterceptorNotCalledForNonReevaluableRules() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        // Load non-reevaluable rules
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_1", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_1.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When - process an event that matches
        runtime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: [
            "lifecyclecontextdata": ["carriername": "AT&T", "devicename": "abc"]
        ], status: .set))
        
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.lifecycle",
                              source: "com.adobe.eventSource.responseContent",
                              data: ["lifecyclecontextdata": ["launchevent": true]])
        
        _ = rulesEngine.process(event: testEvent)
        
        // Then - interceptor should NOT be called (rules are not reevaluable)
        XCTAssertFalse(mockInterceptor.onReevaluationTriggeredCalled, "Interceptor should not be called for non-reevaluable rules")
    }
    
    func testReevaluationInterceptorCalledForReevaluableRules() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        // Load reevaluable rules
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When - process an event that matches the reevaluable rule
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: ["action": "fullscreen"])
        
        _ = rulesEngine.process(event: testEvent)
        
        // Then - interceptor SHOULD be called
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled, "Interceptor should be called for reevaluable rules")
        XCTAssertEqual(1, mockInterceptor.reevaluableRulesReceived?.count)
        XCTAssertNotNil(mockInterceptor.eventReceived)
        XCTAssertNotNil(mockInterceptor.completionReceived)
    }
    
    func testReevaluationCompletionTriggersReEvaluation() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        mockInterceptor.shouldCallCompletionImmediately = true
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        // Load reevaluable rules
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: ["action": "fullscreen"])
        
        _ = rulesEngine.process(event: testEvent)
        
        // Wait for async completion
        let expectation = XCTestExpectation(description: "Wait for re-evaluation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - completion was called, triggering re-evaluation
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
        XCTAssertTrue(mockInterceptor.completionWasCalled)
    }
    
    func testHasReevaluableSupportedConsequence_SchemaType() {
        // Given - a rule with schema consequence type
        let jsonWithSchemaConsequence = """
        {
            "version": 1,
            "reevaluable": true,
            "rules": [
                {
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["test"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "test-id",
                            "type": "schema",
                            "detail": {}
                        }
                    ]
                }
            ]
        }
        """
        
        // When
        let rules = JSONRulesParser.parse(jsonWithSchemaConsequence.data(using: .utf8)!)
        
        // Then
        XCTAssertNotNil(rules)
        XCTAssertEqual(1, rules?.count)
        XCTAssertTrue(rules?[0].hasReevaluableSupportedConsequence ?? false, "Schema consequence should be reevaluable supported")
    }
    
    func testHasReevaluableSupportedConsequence_NonSchemaType() {
        // Given - a rule with non-schema consequence type (e.g., "url")
        let jsonWithUrlConsequence = """
        {
            "version": 1,
            "reevaluable": true,
            "rules": [
                {
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["test"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "test-id",
                            "type": "url",
                            "detail": {}
                        }
                    ]
                }
            ]
        }
        """
        
        // When
        let rules = JSONRulesParser.parse(jsonWithUrlConsequence.data(using: .utf8)!)
        
        // Then
        XCTAssertNotNil(rules)
        XCTAssertEqual(1, rules?.count)
        XCTAssertFalse(rules?[0].hasReevaluableSupportedConsequence ?? true, "Non-schema consequence should NOT be reevaluable supported")
    }
}

// MARK: - Mock Interceptor

class MockRuleReevaluationInterceptor: RuleReevaluationInterceptor {
    var onReevaluationTriggeredCalled = false
    var eventReceived: Event?
    var reevaluableRulesReceived: [LaunchRule]?
    var completionReceived: (() -> Void)?
    var completionWasCalled = false
    var shouldCallCompletionImmediately = false
    
    func onReevaluationTriggered(event: Event, reevaluableRules: [LaunchRule], completion: @escaping () -> Void) {
        onReevaluationTriggeredCalled = true
        eventReceived = event
        reevaluableRulesReceived = reevaluableRules
        completionReceived = completion
        
        if shouldCallCompletionImmediately {
            completionWasCalled = true
            completion()
        }
    }
}
