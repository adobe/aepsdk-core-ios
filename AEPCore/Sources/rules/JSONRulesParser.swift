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

import AEPServices
import Foundation
import SwiftRulesEngine

class JSONRulesParser {
    private static let LOG_LABEL = "JSONRulesParser"

    /// Parses the json rules to objects
    /// - Parameter data: data of json rules
    /// - Returns: an array of `LaunchRule`
    /// - Returns: empty array if json data are invalid or empty
    static func parse(_ data: Data) -> [LaunchRule] {
        let jsonDecoder = JSONDecoder()
        do {
            let root = try jsonDecoder.decode(JSONRuleRoot.self, from: data)
            return root.convert()
        } catch {
            Log.error(label: JSONRulesParser.LOG_LABEL, "Failed to encode json rules, the error is: \(error)")
            return []
        }
    }
}

/// Defines the custom type which is strictly mapped to the json rules's structure, then the Json decoder can easily parse json rules to Swift objects
struct JSONRuleRoot: Codable {
    var version: Int
    var rules: [JSONRule]

    /// Converts itself to `LaunchRule` objects, which can be used in `AEPRulesEngine`
    /// - Returns: an array of `LaunchRule` objects
    func convert() -> [LaunchRule] {
        var result = [LaunchRule]()
        for launchRule in rules {
            if let conditionExpression = launchRule.condition.convert() {
                let rule = LaunchRule(condition: conditionExpression)
                result.append(rule)
            }
        }
        return result
    }
}

struct JSONRule: Codable {
    var condition: JSONCondition
    var consequences: [JSONConsequence]
}

enum ConditionType: String, Codable {
    case group
    case matcher
}

class JSONCondition: Codable {
    var type: ConditionType
    var definition: JSONDefinition
    func convert() -> Evaluable? {
        switch type {
        case .group:
            if let operationStr = definition.logic, let subConditions = definition.conditions {
                var operands = [Evaluable]()
                for subCondition in subConditions {
                    if let operand = subCondition.convert() {
                        operands.append(operand)
                    }
                }
                return operands.count == 0 ? nil : LogicalExpression(operationName: operationStr, operands: operands)
            }
            return nil
        case .matcher:
            if let key = definition.key, let matcher = definition.matcher, let values = definition.values {
                if values.count == 1 {
                    return convert(key: key, matcher: matcher, anyCodable: values[0])
                }
                if values.count > 1 {
                    var operands = [Evaluable]()
                    for value in values {
                        if let operand = convert(key: key, matcher: matcher, anyCodable: value) {
                            operands.append(operand)
                        }
                    }
                    return operands.count == 0 ? nil : LogicalExpression(operationName: "or", operands: operands)
                }
            }
            return nil
        }
    }

    func convert(key: String, matcher: String, anyCodable: AnyCodable) -> Evaluable? {
        if let value = anyCodable.value {
            switch value {
            case is String:
                if let stringValue = anyCodable.value as? String {
                    return ComparisonExpression<MustacheToken, String>(lhs: Operand(mustache: key), operationName: matcher, rhs: Operand(stringLiteral: stringValue))
                }
            case is Int:
                if let intValue = anyCodable.value as? Int {
                    return ComparisonExpression<MustacheToken, Int>(lhs: Operand(mustache: key), operationName: matcher, rhs: Operand(integerLiteral: intValue))
                }
            case is Double:
                if let doubleValue = anyCodable.value as? Double {
                    return ComparisonExpression<MustacheToken, Double>(lhs: Operand(mustache: key), operationName: matcher, rhs: Operand(floatLiteral: doubleValue))
                }
            /// rules engine doesn't accept `Float` type, so convert it to `Double` object here.
            case is Float:
                if let floadValue = anyCodable.value as? Float {
                    return ComparisonExpression<MustacheToken, Double>(lhs: Operand(mustache: key), operationName: matcher, rhs: Operand(floatLiteral: Double(floadValue)))
                }
            default:
                return nil
            }
        }
        return nil
    }
}

struct JSONDefinition: Codable {
    let logic: String?
    let conditions: [JSONCondition]?
    let key: String?
    let matcher: String?
    let values: [AnyCodable]?
}

enum ConsequenceType: String, Codable {
    case url
    case add
    case mod
}

struct JSONDetail: Codable {
    let url: String?
}

struct JSONConsequence: Codable {
    let id: String
    let type: ConsequenceType
    // TODO: make the detail property an `AnyCodable` for now, the rules engine hasn't decided how to handle consequence yet, we will change it later.
    let detail: AnyCodable
}
