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
}
