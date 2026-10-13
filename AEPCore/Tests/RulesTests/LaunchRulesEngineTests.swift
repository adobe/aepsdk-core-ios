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
    
    func testReevaluationCompletionFailure_SkipsReEvaluation() {
        // Given
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let mockInterceptor = MockRuleReevaluationInterceptor()
        mockInterceptor.shouldCallCompletionImmediately = true
        mockInterceptor.completionSuccessValue = false  // Simulate failure
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
        
        // Wait for async processing
        let expectation = XCTestExpectation(description: "Wait for processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - interceptor was called but completion reported failure
        XCTAssertTrue(mockInterceptor.onReevaluationTriggeredCalled)
        XCTAssertTrue(mockInterceptor.completionWasCalled)
        // Note: Re-evaluation is skipped when completion(false) is called,
        // schema consequences will not be processed
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
        
        // Call first completion with success
        firstCompletion?(true)
        
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
    var completionReceived: ((Bool) -> Void)?
    var completionWasCalled = false
    var shouldCallCompletionImmediately = false
    /// Whether to report success (true) or failure (false) when calling completion
    var completionSuccessValue = true
    var callCount = 0
    
    /// Track all events received (for multiple event tests)
    var allEventsReceived: [Event] = []
    
    func onReevaluationTriggered(event: Event, reevaluableRules: [LaunchRule], completion: @escaping (Bool) -> Void) {
        onReevaluationTriggeredCalled = true
        eventReceived = event
        reevaluableRulesReceived = reevaluableRules
        completionReceived = completion
        callCount += 1
        allEventsReceived.append(event)
        
        if shouldCallCompletionImmediately {
            completionWasCalled = true
            completion(completionSuccessValue)
        }
    }
    
    func reset() {
        onReevaluationTriggeredCalled = false
        eventReceived = nil
        reevaluableRulesReceived = nil
        completionReceived = nil
        completionWasCalled = false
        completionSuccessValue = true
        callCount = 0
        allEventsReceived.removeAll()
    }
}

// MARK: - forward-operational-data consequence

extension LaunchRulesEngineTests {
    private static let operationalDataType = "com.adobe.eventType.generic.operationalData"
    private static let requestContent = "com.adobe.eventSource.requestContent"
    private static let edgeIdentityType = "com.adobe.eventType.edgeIdentity"
    private static let responseOperationalData = "com.adobe.eventSource.responseOperationalData"

    private func forwardRule(detail: [String: Any], id: String = "RC-forward", conditionType: String = operationalDataType) -> [String: Any] {
        return [
            "condition": ["type": "group", "definition": ["logic": "and", "conditions": [
                ["type": "matcher", "definition": ["key": "~type", "matcher": "eq", "values": [conditionType]]],
                ["type": "matcher", "definition": ["key": "~source", "matcher": "eq", "values": [LaunchRulesEngineTests.requestContent]]]
            ]]],
            "consequences": [["id": id, "type": "forward-operational-data", "detail": detail]]
        ]
    }

    private func forwardRulesEngine(rules: [[String: Any]], runtime: TestableExtensionRuntime) -> LaunchRulesEngine? {
        let ruleSet: [String: Any] = ["version": 1, "rules": rules]
        guard let data = try? JSONSerialization.data(withJSONObject: ruleSet), let parsed = JSONRulesParser.parse(data) else {
            XCTFail("Could not parse forward-operational-data rule")
            return nil
        }
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        rulesEngine.replaceRules(with: parsed)
        runtime.resetDispatchedEventAndCreatedSharedStates()
        return rulesEngine
    }

    /// Rule matching operational-data events with a single forward-operational-data consequence.
    private func forwardRuleEngine(detail: [String: Any], runtime: TestableExtensionRuntime, conditionType: String = operationalDataType) -> LaunchRulesEngine? {
        return forwardRulesEngine(rules: [forwardRule(detail: detail, conditionType: conditionType)], runtime: runtime)
    }

    /// The rule shipped for consent bypass device attribute sync (all four attributes enabled).
    private var shippedDetail: [String: Any] {
        return [
            "type": LaunchRulesEngineTests.edgeIdentityType,
            "source": LaunchRulesEngineTests.responseOperationalData,
            "attributes": [
                ["path": ["timezone"], "enabled": true],
                ["path": ["tokens", "pushNotification"], "enabled": true],
                ["path": ["tokens", "liveActivityStart"], "enabled": true],
                ["path": ["tokens", "liveActivityUpdate"], "enabled": true]
            ]
        ]
    }

    /// Same as `shippedDetail` with `liveActivityStart` disabled.
    private var backendShapedDetail: [String: Any] {
        var detail = shippedDetail
        detail["attributes"] = [
            ["path": ["timezone"], "enabled": true],
            ["path": ["tokens", "pushNotification"], "enabled": true],
            ["path": ["tokens", "liveActivityStart"], "enabled": false],
            ["path": ["tokens", "liveActivityUpdate"], "enabled": true]
        ]
        return detail
    }

    private var backendShapedEventData: [String: Any] {
        return [
            "app": ["id": "com.adobe.ajo.MobileTestApp", "platform": "apnsSandbox"],
            "timezone": "America/Los_Angeles",
            // Same key name at a different level must never be picked up.
            "pushNotification": "decoy-top-level",
            "tokens": [
                "pushNotification": ["804EB6EDB22D"],
                "liveActivityStart": [["attributeType": "GameScoreLiveActivityAttributes", "value": "la-start"]],
                "liveActivityUpdate": [
                    ["liveActivityID": "Test2", "token": "t1"],
                    ["liveActivityID": "Test22", "token": "t2"],
                    ["liveActivityID": "Test23", "token": "t3"],
                    ["liveActivityID": "Test4", "token": "t4"]
                ]
            ]
        ]
    }

    private func operationalEvent(_ data: [String: Any]?) -> Event {
        return Event(name: "Device attributes for rules engine", type: LaunchRulesEngineTests.operationalDataType,
                     source: LaunchRulesEngineTests.requestContent, data: data)
    }

    func testForwardOperationalData_shippedRule_forwardsAllPathsAsChainedEvent() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: shippedDetail, runtime: runtime) else { return }
        let e1 = operationalEvent(backendShapedEventData)

        _ = rulesEngine.process(event: e1)

        XCTAssertEqual(1, runtime.dispatchedEvents.count)
        let e2 = runtime.dispatchedEvents[0]
        XCTAssertEqual("Forward operational data", e2.name)
        XCTAssertEqual(LaunchRulesEngineTests.edgeIdentityType, e2.type)
        XCTAssertEqual(LaunchRulesEngineTests.responseOperationalData, e2.source)
        XCTAssertNil(e2.responseID)
        XCTAssertEqual(e1.id, e2.parentID)
        var expected = backendShapedEventData
        expected.removeValue(forKey: "pushNotification")
        expected.removeValue(forKey: "app")
        XCTAssertEqual(expected as NSDictionary, e2.data as NSDictionary?)
    }

    func testForwardOperationalData_copiesOnlyEnabledPathsAsIs() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: backendShapedDetail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(backendShapedEventData))

        XCTAssertEqual(1, runtime.dispatchedEvents.count)
        let expected: [String: Any] = [
            "timezone": "America/Los_Angeles",
            "tokens": [
                "pushNotification": ["804EB6EDB22D"],
                "liveActivityUpdate": [
                    ["liveActivityID": "Test2", "token": "t1"],
                    ["liveActivityID": "Test22", "token": "t2"],
                    ["liveActivityID": "Test23", "token": "t3"],
                    ["liveActivityID": "Test4", "token": "t4"]
                ]
            ]
        ]
        XCTAssertEqual(expected as NSDictionary, runtime.dispatchedEvents[0].data as NSDictionary?)
    }

    func testForwardOperationalData_missingPathsSkipped_noEmptyContainers() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: backendShapedDetail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(["timezone": "Asia/Kolkata", "app": ["id": "x"]]))

        let expected: [String: Any] = ["timezone": "Asia/Kolkata"]
        XCTAssertEqual(expected as NSDictionary, runtime.dispatchedEvents.first?.data as NSDictionary?)
    }

    func testForwardOperationalData_onlyDisabledAttributes_dispatchesEmptyPayload() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: backendShapedDetail, runtime: runtime) else { return }
        let e1 = operationalEvent([
            "app": ["id": "x"],
            "tokens": ["liveActivityStart": [["attributeType": "A", "value": "v"]]]
        ])

        _ = rulesEngine.process(event: e1)

        XCTAssertEqual(1, runtime.dispatchedEvents.count)
        let e2 = runtime.dispatchedEvents[0]
        XCTAssertNil(e2.responseID)
        XCTAssertEqual(e1.id, e2.parentID)
        XCTAssertEqual(NSDictionary(), e2.data as NSDictionary?)
    }

    func testForwardOperationalData_nilEventData_alwaysDispatched() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: shippedDetail, runtime: runtime) else { return }
        let e1 = operationalEvent(nil)

        _ = rulesEngine.process(event: e1)

        XCTAssertEqual(1, runtime.dispatchedEvents.count)
        XCTAssertNil(runtime.dispatchedEvents[0].responseID)
        XCTAssertEqual(e1.id, runtime.dispatchedEvents[0].parentID)
        XCTAssertEqual(NSDictionary(), runtime.dispatchedEvents[0].data as NSDictionary?)
    }

    func testForwardOperationalData_nullValuesSkipped_emptyTokenForwarded() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: shippedDetail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent([
            "timezone": NSNull(),
            "tokens": ["pushNotification": "", "liveActivityUpdate": [Any](), "notAllowed": NSNull()],
            "notAllowed": NSNull()
        ]))

        XCTAssertEqual(1, runtime.dispatchedEvents.count)
        let e2 = runtime.dispatchedEvents.first
        XCTAssertNil(e2?.data?["timezone"])
        let tokens = e2?.data?["tokens"] as? [String: Any]
        XCTAssertEqual("", tokens?["pushNotification"] as? String)
        XCTAssertEqual(0, (tokens?["liveActivityUpdate"] as? [Any])?.count, "an empty array is a value")
        let expected: [String: Any] = [
            "tokens": ["pushNotification": "", "liveActivityUpdate": [Any]()]
        ]
        XCTAssertEqual(expected as NSDictionary, e2?.data as NSDictionary?)
    }

    func testForwardOperationalData_nullPushTokenNotForwarded() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: shippedDetail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent([
            "timezone": "Europe/London",
            "tokens": ["pushNotification": NSNull()]
        ]))

        XCTAssertEqual(["timezone": "Europe/London"] as NSDictionary,
                       runtime.dispatchedEvents.first?.data as NSDictionary?)
    }

    func testForwardOperationalData_nullParent_childPathNotFound() {
        let runtime = TestableExtensionRuntime()
        guard let rulesEngine = forwardRuleEngine(detail: shippedDetail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(["tokens": NSNull()]))

        let e2 = runtime.dispatchedEvents.first
        XCTAssertNil(e2?.data?["tokens"])
        XCTAssertEqual(NSDictionary(), e2?.data as NSDictionary?)
    }

    func testForwardOperationalData_sameKeyNameAtOtherLevel_notMatched() {
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail["attributes"] = [["path": ["tokens", "pushNotification"], "enabled": true]]
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(["pushNotification": "top-level-only"]))

        XCTAssertEqual(NSDictionary(), runtime.dispatchedEvents.first?.data as NSDictionary?)
    }

    func testForwardOperationalData_pathThroughNonDictionary_notMatched() {
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail["attributes"] = [["path": ["tokens", "0"], "enabled": true]]
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(["tokens": ["a", "b"]]))

        XCTAssertEqual(NSDictionary(), runtime.dispatchedEvents.first?.data as NSDictionary?,
                       "paths traverse dictionaries only, never array indexes")
    }

    func testForwardOperationalData_parentPathNotMatchedByChildRule() {
        // Exact path match: an enabled child path does not forward the parent, and vice versa.
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail["attributes"] = [["path": ["tokens", "pushNotification", "id"], "enabled": true]]
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(backendShapedEventData))

        XCTAssertNil(runtime.dispatchedEvents.first?.data?["tokens"])
        XCTAssertEqual(NSDictionary(), runtime.dispatchedEvents.first?.data as NSDictionary?)
    }

    func testForwardOperationalData_malformedEntriesSkipped() {
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail["attributes"] = [
            ["path": "timezone", "enabled": true],   // path not an array
            ["path": [], "enabled": true],           // empty path
            ["enabled": true],                       // no path
            ["path": ["timezone"], "enabled": "yes"], // enabled not a bool
            ["path": ["tokens", "pushNotification"], "enabled": true]
        ]
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(backendShapedEventData))

        let data = runtime.dispatchedEvents.first?.data
        XCTAssertNil(data?["timezone"])
        XCTAssertEqual(["804EB6EDB22D"], (data?["tokens"] as? [String: Any])?["pushNotification"] as? [String])
    }

    func testForwardOperationalData_duplicateEnabledPath_copiedOnce() {
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail["attributes"] = [["path": ["timezone"], "enabled": true], ["path": ["timezone"], "enabled": true]]
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(backendShapedEventData))

        let expected: [String: Any] = ["timezone": "America/Los_Angeles"]
        XCTAssertEqual(expected as NSDictionary, runtime.dispatchedEvents.first?.data as NSDictionary?)
    }

    func testForwardOperationalData_missingAttributes_dispatchesEmptyPayload() {
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail.removeValue(forKey: "attributes")
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(backendShapedEventData))

        XCTAssertEqual(1, runtime.dispatchedEvents.count)
        XCTAssertEqual(NSDictionary(), runtime.dispatchedEvents[0].data as NSDictionary?)
    }

    func testForwardOperationalData_missingTypeOrSource_nothingDispatched() {
        for missing in ["type", "source"] {
            let runtime = TestableExtensionRuntime()
            var detail = backendShapedDetail
            detail.removeValue(forKey: missing)
            guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

            _ = rulesEngine.process(event: operationalEvent(backendShapedEventData))

            XCTAssertTrue(runtime.dispatchedEvents.isEmpty, "missing '\(missing)' must not dispatch")
        }
    }

    func testForwardOperationalData_valueTypesPreserved() {
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail["attributes"] = [
            ["path": ["count"], "enabled": true],
            ["path": ["flag"], "enabled": true],
            ["path": ["nested"], "enabled": true]
        ]
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(["count": 3, "flag": true, "nested": ["a": ["b": 1]]]))

        let data = runtime.dispatchedEvents.first?.data
        XCTAssertEqual(3, data?["count"] as? Int)
        XCTAssertEqual(true, data?["flag"] as? Bool)
        XCTAssertEqual(["a": ["b": 1]] as NSDictionary, data?["nested"] as? NSDictionary)
    }

    func testForwardOperationalData_multipleMatchingRules_oneEventPerRule() {
        let runtime = TestableExtensionRuntime()
        var timezoneOnly = shippedDetail
        timezoneOnly["attributes"] = [["path": ["timezone"], "enabled": true], ["path": ["tokens", "pushNotification"], "enabled": false]]
        var pushOnly = shippedDetail
        pushOnly["attributes"] = [["path": ["tokens", "pushNotification"], "enabled": true]]
        guard let rulesEngine = forwardRulesEngine(rules: [forwardRule(detail: timezoneOnly, id: "rule-1"),
                                                           forwardRule(detail: pushOnly, id: "rule-2")],
                                                   runtime: runtime) else { return }
        let e1 = operationalEvent(backendShapedEventData)

        _ = rulesEngine.process(event: e1)

        XCTAssertEqual(2, runtime.dispatchedEvents.count)
        XCTAssertTrue(runtime.dispatchedEvents.allSatisfy { $0.responseID == nil && $0.parentID == e1.id })
        let payloads = runtime.dispatchedEvents.compactMap { $0.data as NSDictionary? }
        XCTAssertTrue(payloads.contains(["timezone": "America/Los_Angeles"] as NSDictionary))
        XCTAssertTrue(payloads.contains(["tokens": ["pushNotification": ["804EB6EDB22D"]]] as NSDictionary))
    }

    func testForwardOperationalData_forwardedEventMatchingSameRule_notForwardedAgain() {
        // The rule forwards to the same type/source it matches: the chain limit must stop the loop.
        let runtime = TestableExtensionRuntime()
        var detail = backendShapedDetail
        detail["type"] = LaunchRulesEngineTests.operationalDataType
        detail["source"] = LaunchRulesEngineTests.requestContent
        guard let rulesEngine = forwardRuleEngine(detail: detail, runtime: runtime) else { return }

        _ = rulesEngine.process(event: operationalEvent(backendShapedEventData))
        XCTAssertEqual(1, runtime.dispatchedEvents.count)

        _ = rulesEngine.process(event: runtime.dispatchedEvents[0])
        XCTAssertEqual(1, runtime.dispatchedEvents.count)
    }

    func testForwardOperationalData_otherConsequenceTokenBehaviorUnchanged() {
        // A bare token for an absent key still renders to an empty string for other consequence types.
        let runtime = TestableExtensionRuntime()
        let rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: runtime)
        let event = Event(name: "e", type: "type", source: "source", data: ["tokens": ["a": ["x"]]])
        let consequence = RuleConsequence(id: "c", type: "add", details: ["eventdata": ["missing": "{%notThere%}", "array": "{%tokens.a%}"]])

        let resolved = rulesEngine.replaceToken(for: consequence, data: TokenFinder(event: event, extensionRuntime: runtime))

        let eventData = resolved.details["eventdata"] as? [String: Any?]
        XCTAssertEqual("", eventData?["missing"] as? String)
        XCTAssertEqual("", eventData?["array"] as? String)
    }

    func testForwardOperationalData_reachesDedicatedTypeSourceListener() throws {
        let runtime = TestableExtensionRuntime()
        let engine = try XCTUnwrap(forwardRuleEngine(detail: shippedDetail, runtime: runtime))
        _ = engine.process(event: operationalEvent(backendShapedEventData))
        let consequence = try XCTUnwrap(runtime.dispatchedEvents.first)
        let listener = EventListenerContainer(listener: { _ in }, type: Self.edgeIdentityType,
                                              source: Self.responseOperationalData, triggerEventId: nil, timeoutTask: nil)
        XCTAssertTrue(listener.shouldNotify(consequence))
        XCTAssertFalse(listener.shouldNotify(Event(name: "wrong source", type: Self.edgeIdentityType,
                                                    source: Self.requestContent, data: consequence.data)))
        XCTAssertFalse(listener.shouldNotify(Event(name: "wrong type", type: EventType.edge,
                                                    source: Self.responseOperationalData, data: consequence.data)))
    }

    func testForwardOperationalData_unmatchedTypeOrSourceDispatchesNothing() throws {
        let runtime = TestableExtensionRuntime()
        let engine = try XCTUnwrap(forwardRuleEngine(detail: shippedDetail, runtime: runtime))
        _ = engine.process(event: Event(name: "wrong type", type: EventType.edge, source: Self.requestContent, data: backendShapedEventData))
        _ = engine.process(event: Event(name: "wrong source", type: Self.operationalDataType,
                                       source: EventSource.responseContent, data: backendShapedEventData))
        XCTAssertTrue(runtime.dispatchedEvents.isEmpty)
    }

    func testForwardOperationalData_legacyContextIsIgnoredAndOriginalEventIsUnchanged() throws {
        let runtime = TestableExtensionRuntime()
        var detail = shippedDetail
        detail["attributes"] = [["path": ["tokens"], "enabled": true]]
        detail["context"] = [["path": ["tokens", "pushNotification"]], ["path": ["app"]]]
        let engine = try XCTUnwrap(forwardRuleEngine(detail: detail, runtime: runtime))
        let original: [String: Any] = ["tokens": "scalar", "app": ["id": "test"], "notAllowed": "secret"]
        let event = operationalEvent(original)
        _ = engine.process(event: event)
        XCTAssertEqual(["tokens": "scalar"] as NSDictionary,
                       runtime.dispatchedEvents.first?.data as NSDictionary?)
        XCTAssertEqual(original as NSDictionary, event.data as NSDictionary?)
    }
}
