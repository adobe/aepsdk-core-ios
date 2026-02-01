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

import AEPServices

@testable import AEPCore
@testable import AEPRulesEngine

class JSONRulesParserTests: XCTestCase {
    private let EMPTY_JSON_RULE = """
    {
        "version": 1,
        "rules": []
    }
    """
    private let INVALID_JSON_RULE = """
    {
    """
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGenerateLaunchRules() {
        // When: load rules from a json file
        Log.logFilter = .debug
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_1", withExtension: "json"), let data = try? Data(contentsOf: url) else {
            XCTAssertTrue(false)
            return
        }
        /// Then: this json rules should be parsed to `LaunchRule` objects
        let rules = JSONRulesParser.parse(data)
        XCTAssertEqual(2, rules?.count)
        XCTAssertTrue(rules?[0].condition is LogicalExpression)

        XCTAssertTrue(rules?[1].condition is LogicalExpression)
        XCTAssertEqual("and", (rules?[1].condition as! LogicalExpression).operationName)

        let levelOneGroupAnd = rules?[0].condition as! LogicalExpression
        XCTAssertEqual("and", levelOneGroupAnd.operationName)

        XCTAssertTrue(levelOneGroupAnd.operands[0] is LogicalExpression)
        let levelTwoGroupOr = levelOneGroupAnd.operands[0] as! LogicalExpression
        XCTAssertEqual("or", levelTwoGroupOr.operationName)

        XCTAssertTrue(levelTwoGroupOr.operands[0] is LogicalExpression)
        let levelThreeGroupAnd = levelTwoGroupOr.operands[0] as! LogicalExpression
        XCTAssertEqual("and", levelThreeGroupAnd.operationName)

        XCTAssertTrue(levelThreeGroupAnd.operands[0] is ComparisonExpression<String, String>)
        let levelFourMatcherEQ = levelThreeGroupAnd.operands[0] as! ComparisonExpression<String, String>
        XCTAssertEqual("equals", levelFourMatcherEQ.operationName)
        XCTAssertEqual("<Value: com.adobe.eventType.lifecycle>", levelFourMatcherEQ.rhs.description)
    }

    func testGenerateLaunchRulesEmpty() {
        let rules = JSONRulesParser.parse(EMPTY_JSON_RULE.data(using: .utf8)!)
        XCTAssertEqual(0, rules?.count)
    }

    func testGenerateLaunchRulesInvalid() {
        let rules = JSONRulesParser.parse(INVALID_JSON_RULE.data(using: .utf8)!)
        XCTAssertNil(rules)
    }
    
    // MARK: - Reevaluable Flag Tests
    
    func testParseRulesWithMetaReevaluableTrue() {
        // Given: JSON with meta.reEvaluable = true (backend format)
        let jsonWithReevaluable = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": {
                        "reEvaluate": true
                    },
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
                            "id": "test-consequence",
                            "type": "schema",
                            "detail": {}
                        }
                    ]
                }
            ]
        }
        """
        
        // When
        let rules = JSONRulesParser.parse(jsonWithReevaluable.data(using: .utf8)!)
        
        // Then
        XCTAssertNotNil(rules)
        XCTAssertEqual(1, rules?.count)
        XCTAssertTrue(rules?[0].reevaluable ?? false, "Rule should be marked as reevaluable from meta")
    }
    
    func testParseRulesWithMetaReevaluableFalse() {
        // Given: JSON with meta.reEvaluable = false
        let jsonWithReevaluableFalse = """
        {
            "version": 1,
            "rules": [
                {
                    "meta": {
                        "reEvaluate": false
                    },
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
                            "id": "test-consequence",
                            "type": "schema",
                            "detail": {}
                        }
                    ]
                }
            ]
        }
        """
        
        // When
        let rules = JSONRulesParser.parse(jsonWithReevaluableFalse.data(using: .utf8)!)
        
        // Then
        XCTAssertNotNil(rules)
        XCTAssertEqual(1, rules?.count)
        XCTAssertFalse(rules?[0].reevaluable ?? true, "Rule should NOT be marked as reevaluable")
    }
    
    func testParseRulesWithoutMetaObject() {
        // Given: JSON without meta object at all (should default to false)
        let jsonWithoutMeta = """
        {
            "version": 1,
            "rules": [
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
                            "id": "test-consequence",
                            "type": "schema",
                            "detail": {}
                        }
                    ]
                }
            ]
        }
        """
        
        // When
        let rules = JSONRulesParser.parse(jsonWithoutMeta.data(using: .utf8)!)
        
        // Then
        XCTAssertNotNil(rules)
        XCTAssertEqual(1, rules?.count)
        XCTAssertFalse(rules?[0].reevaluable ?? true, "Rule without meta should default to NOT reevaluable")
    }
    
    func testParseRulesWithoutReevaluableFlag() {
        // Given: JSON without reevaluable flag (should default to false)
        let jsonWithoutReevaluable = """
        {
            "version": 1,
            "rules": [
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
                            "id": "test-consequence",
                            "type": "url",
                            "detail": {}
                        }
                    ]
                }
            ]
        }
        """
        
        // When
        let rules = JSONRulesParser.parse(jsonWithoutReevaluable.data(using: .utf8)!)
        
        // Then
        XCTAssertNotNil(rules)
        XCTAssertEqual(1, rules?.count)
        XCTAssertFalse(rules?[0].reevaluable ?? true, "Rule should default to NOT reevaluable")
    }
    
    func testParseRulesFromReevaluableJsonFile() {
        // Given: Load rules from the reevaluable test JSON file
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "rules_reevaluable", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            XCTFail("Could not load rules_reevaluable.json")
            return
        }
        
        // When
        let rules = JSONRulesParser.parse(data)
        
        // Then
        XCTAssertNotNil(rules)
        XCTAssertEqual(1, rules?.count)
        XCTAssertTrue(rules?[0].reevaluable ?? false, "Rule from reevaluable JSON should be marked as reevaluable")
        XCTAssertEqual("schema", rules?[0].consequences[0].type)
    }
}
