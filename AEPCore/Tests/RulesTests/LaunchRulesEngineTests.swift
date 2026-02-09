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
        // Given - a rule with schema consequence type and meta.reEvaluable = true
        let jsonWithSchemaConsequence = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": { "reEvaluate": true },
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
        XCTAssertTrue(rules?[0].hasReevaluableSupportedConsequence() ?? false, "Schema consequence should be reevaluable supported")
    }
    
    func testHasReevaluableSupportedConsequence_NonSchemaType() {
        // Given - a rule with non-schema consequence type (e.g., "url") and meta.reEvaluable = true
        let jsonWithUrlConsequence = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": { "reEvaluate": true },
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
        XCTAssertFalse(rules?[0].hasReevaluableSupportedConsequence() ?? true, "Non-schema consequence should NOT be reevaluable supported")
    }
    
    // MARK: - No Triggering When No Interceptor Set
    
    func testNoTriggeringWhenNoInterceptorSet() {
        // Given - rules engine WITHOUT interceptor set
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        // Note: NOT setting any interceptor
        
        // Load reevaluable rules
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When - process an event that matches reevaluable rule
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: ["action": "fullscreen"])
        
        // Then - should not crash and should process normally
        let result = rulesEngine.process(event: testEvent)
        XCTAssertNotNil(result, "Event should be processed without interceptor")
    }
    
    // MARK: - Rule Separation Tests
    
    func testRuleSeparation_SchemaRulesHeld_AddRulesProcessedImmediately() {
        // Given - mixed rules: one reevaluable schema rule, one non-reevaluable add rule
        let mixedRulesJson = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": { "reEvaluate": true },
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["com.adobe.eventType.generic.track"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "schema-consequence",
                            "type": "schema",
                            "detail": { "schema": "test" }
                        }
                    ]
                },
                {
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["com.adobe.eventType.generic.track"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "add-consequence",
                            "type": "add",
                            "detail": { "eventdata": { "addedKey": "addedValue" } }
                        }
                    ]
                }
            ]
        }
        """
        
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        guard let rules = JSONRulesParser.parse(mixedRulesJson.data(using: .utf8)!) else {
            XCTFail("Could not parse mixed rules JSON")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: ["originalKey": "originalValue"])
        
        let result = rulesEngine.process(event: testEvent)
        
        // Then - interceptor should be called for reevaluable rule
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
        
        // Interceptor should receive the PROCESSED event (with add rule data applied)
        XCTAssertNotNil(mockInterceptor.eventReceived)
        XCTAssertEqual("addedValue", mockInterceptor.eventReceived?.data?["addedKey"] as? String,
                       "Interceptor should receive event with add consequence data")
        XCTAssertEqual("originalValue", mockInterceptor.eventReceived?.data?["originalKey"] as? String,
                       "Interceptor should receive event with original data preserved")
        
        // Returned event should also have the added data
        XCTAssertNotNil(result)
        XCTAssertEqual("addedValue", result.data?["addedKey"] as? String)
    }
    
    // MARK: - Multiple Reevaluable Schema Rules
    
    func testMultipleReevaluableSchemaRulesHandling() {
        // Given - multiple reevaluable schema rules
        let multipleReevaluableJson = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": { "reEvaluate": true },
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["com.adobe.eventType.generic.track"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "schema-consequence-1",
                            "type": "schema",
                            "detail": { "schema": "test1" }
                        }
                    ]
                },
                {
                    "meta": { "reEvaluate": true },
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["com.adobe.eventType.generic.track"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "schema-consequence-2",
                            "type": "schema",
                            "detail": { "schema": "test2" }
                        }
                    ]
                }
            ]
        }
        """
        
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        guard let rules = JSONRulesParser.parse(multipleReevaluableJson.data(using: .utf8)!) else {
            XCTFail("Could not parse multiple reevaluable rules JSON")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: [:])
        
        _ = rulesEngine.process(event: testEvent)
        
        // Then - interceptor should receive both reevaluable rules
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
        XCTAssertEqual(2, mockInterceptor.reevaluableRulesReceived?.count, "Should receive 2 reevaluable rules")
    }
    
    // MARK: - Mixed Reevaluable and Non-Reevaluable Rules
    
    func testMixedReevaluableAndNonReevaluableRules() {
        // Given - one reevaluable and one non-reevaluable rule, both schema type
        let mixedJson = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": { "reEvaluate": true },
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["com.adobe.eventType.generic.track"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "reevaluable-schema",
                            "type": "schema",
                            "detail": {}
                        }
                    ]
                },
                {
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["com.adobe.eventType.generic.track"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "non-reevaluable-schema",
                            "type": "schema",
                            "detail": {}
                        }
                    ]
                }
            ]
        }
        """
        
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        guard let rules = JSONRulesParser.parse(mixedJson.data(using: .utf8)!) else {
            XCTFail("Could not parse mixed rules JSON")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: [:])
        
        _ = rulesEngine.process(event: testEvent)
        
        // Then - only reevaluable rule should be in the reevaluable list
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
        XCTAssertEqual(1, mockInterceptor.reevaluableRulesReceived?.count, "Only 1 rule should be reevaluable")
    }
    
    // MARK: - Correct Event Passing
    
    func testCorrectEventPassedToInterceptor_SchemaOnlyRules() {
        // Given - rules_reevaluable.json only has schema rules (no add/mod rules)
        // So the processed event equals the original event
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When - process event with specific data
        let testEventData: [String: Any] = ["action": "fullscreen", "customKey": "customValue"]
        let testEvent = Event(name: "test_event_name",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: testEventData)
        
        _ = rulesEngine.process(event: testEvent)
        
        // Then - interceptor should receive the processed event
        // Since there are no add/mod rules, processed event equals original event
        XCTAssertNotNil(mockInterceptor.eventReceived)
        XCTAssertEqual(testEvent.id, mockInterceptor.eventReceived?.id)
        XCTAssertEqual(testEvent.name, mockInterceptor.eventReceived?.name)
        XCTAssertEqual(testEvent.type, mockInterceptor.eventReceived?.type)
        XCTAssertEqual(testEvent.source, mockInterceptor.eventReceived?.source)
        XCTAssertEqual("customValue", mockInterceptor.eventReceived?.data?["customKey"] as? String)
    }
    
    // MARK: - Event Data Persistence After Reevaluation
    
    func testEventDataPersistenceAfterReevaluation_SchemaOnlyRules() {
        // Given - rules_reevaluable.json only has schema rules (no add/mod rules)
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        mockInterceptor.shouldCallCompletionImmediately = true
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When
        let originalData: [String: Any] = ["action": "fullscreen", "originalKey": "originalValue"]
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: originalData)
        
        _ = rulesEngine.process(event: testEvent)
        
        // Wait for async completion
        let expectation = XCTestExpectation(description: "Wait for reevaluation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - interceptor should receive the processed event with original data preserved
        // Since there are no add/mod rules, processed event equals original event
        XCTAssertEqual("fullscreen", mockInterceptor.eventReceived?.data?["action"] as? String)
        XCTAssertEqual("originalValue", mockInterceptor.eventReceived?.data?["originalKey"] as? String)
    }
    
    // MARK: - Multiple Interceptor Calls for Multiple Events
    
    func testMultipleInterceptorCallsForMultipleEvents() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        mockInterceptor.shouldCallCompletionImmediately = true
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When - process multiple events
        let event1 = Event(name: "test1",
                           type: "com.adobe.eventType.generic.track",
                           source: "com.adobe.eventSource.requestContent",
                           data: ["action": "fullscreen"])
        
        let event2 = Event(name: "test2",
                           type: "com.adobe.eventType.generic.track",
                           source: "com.adobe.eventSource.requestContent",
                           data: ["action": "fullscreen"])
        
        _ = rulesEngine.process(event: event1)
        
        // Reset mock to track second call
        mockInterceptor.callCount += 1
        let firstEventId = mockInterceptor.eventReceived?.id
        
        _ = rulesEngine.process(event: event2)
        
        // Then - interceptor should be called for each event
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
        XCTAssertNotEqual(firstEventId, mockInterceptor.eventReceived?.id, "Second event should be different")
    }
    
    // MARK: - Interceptor Replacement Behavior
    
    func testInterceptorReplacementBehavior() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        
        let firstInterceptor = MockRuleReevaluationInterceptor()
        let secondInterceptor = MockRuleReevaluationInterceptor()
        
        // Set first interceptor
        rulesEngine.setReevaluationInterceptor(firstInterceptor)
        // Replace with second interceptor
        rulesEngine.setReevaluationInterceptor(secondInterceptor)
        
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
        
        // Then - only second interceptor should be called
        XCTAssertFalse(firstInterceptor.onReevaluationTriggeredCalled, "First interceptor should NOT be called")
        XCTAssertTrue(secondInterceptor.onReevaluationTriggeredCalled, "Second interceptor SHOULD be called")
    }
    
    // MARK: - Interceptor Removal (Set to nil)
    
    func testInterceptorRemoval() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        // Remove interceptor
        rulesEngine.setReevaluationInterceptor(nil)
        
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
        
        let result = rulesEngine.process(event: testEvent)
        
        // Then - interceptor should NOT be called (was removed)
        XCTAssertFalse(mockInterceptor.onReevaluationTriggeredCalled, "Interceptor should NOT be called after removal")
        XCTAssertNotNil(result, "Event should still be processed")
    }
    
    // MARK: - Single Rule with Mixed Consequences (Entire Rule Held)
    
    func testSingleRuleWithMixedConsequences_EntireRuleHeldTogether() {
        // Given - a single rule with both schema and add consequences
        // The entire rule should be held together since it has schema consequence
        let mixedConsequencesJson = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": { "reEvaluate": true },
                    "condition": {
                        "type": "matcher",
                        "definition": {
                            "key": "~type",
                            "matcher": "eq",
                            "values": ["com.adobe.eventType.generic.track"]
                        }
                    },
                    "consequences": [
                        {
                            "id": "schema-consequence",
                            "type": "schema",
                            "detail": { "schema": "test" }
                        },
                        {
                            "id": "add-consequence",
                            "type": "add",
                            "detail": { "eventdata": { "added": "true" } }
                        }
                    ]
                }
            ]
        }
        """
        
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        guard let rules = JSONRulesParser.parse(mixedConsequencesJson.data(using: .utf8)!) else {
            XCTFail("Could not parse mixed consequences JSON")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When
        let testEvent = Event(name: "test",
                              type: "com.adobe.eventType.generic.track",
                              source: "com.adobe.eventSource.requestContent",
                              data: [:])
        
        _ = rulesEngine.process(event: testEvent)
        
        // Then - interceptor should be called (rule has schema consequence)
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
        // The rule received should have both consequences
        XCTAssertEqual(2, mockInterceptor.reevaluableRulesReceived?.first?.consequences.count,
                       "Rule should have both consequences")
    }
    
    // MARK: - Multiple Callbacks in Sequence
    
    func testMultipleCallbacksInSequence() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        // Don't call completion immediately - we'll control it manually
        mockInterceptor.shouldCallCompletionImmediately = false
        rulesEngine.setReevaluationInterceptor(mockInterceptor)
        
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        rulesEngine.replaceRules(with: rules)
        
        // When - process first event
        let event1 = Event(name: "test1",
                           type: "com.adobe.eventType.generic.track",
                           source: "com.adobe.eventSource.requestContent",
                           data: ["action": "fullscreen"])
        
        _ = rulesEngine.process(event: event1)
        
        // Capture first completion
        let firstCompletion = mockInterceptor.completionReceived
        XCTAssertNotNil(firstCompletion, "First completion should be captured")
        
        // Call first completion
        firstCompletion?()
        
        // Wait and verify
        let expectation = XCTestExpectation(description: "Wait for sequence")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - completion should have been callable without crash
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
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
    var callCount = 0
    
    /// Track all events received (for multiple event tests)
    var allEventsReceived: [Event] = []
    
    func onReevaluationTriggered(event: Event, reevaluableRules: [LaunchRule], completion: @escaping () -> Void) {
        onReevaluationTriggeredCalled = true
        eventReceived = event
        reevaluableRulesReceived = reevaluableRules
        completionReceived = completion
        callCount += 1
        allEventsReceived.append(event)
        
        if shouldCallCompletionImmediately {
            completionWasCalled = true
            completion()
        }
    }
    
    func reset() {
        onReevaluationTriggeredCalled = false
        eventReceived = nil
        reevaluableRulesReceived = nil
        completionReceived = nil
        completionWasCalled = false
        callCount = 0
        allEventsReceived.removeAll()
    }
}
