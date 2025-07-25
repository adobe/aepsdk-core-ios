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
import AEPRulesEngine

public class JSONRulesParser {
    fileprivate static let LOG_LABEL = "JSONRulesParser"

    /// Parses the json rules to objects
    /// - Parameter data: data of json rules
    /// - Returns: an array of `LaunchRule`
    static public func parse(_ data: Data) -> [LaunchRule]? {
        let jsonDecoder = JSONDecoder()
        do {
            let root = try jsonDecoder.decode(JSONRuleRoot.self, from: data)
            return root.convert()
        } catch {
            Log.error(label: JSONRulesParser.LOG_LABEL, "Failed to encode json rules, the error is: \(error)")
            return nil
        }
    }

    /// Parses the json rules to objects
    /// - Parameter data: data of json rules
    /// - Returns: an array of `LaunchRule`
    static public func parse(_ data: Data, runtime: ExtensionRuntime?) -> [LaunchRule]? {
        let jsonDecoder = JSONDecoder()
        do {
            let root = try jsonDecoder.decode(JSONRuleRoot.self, from: data)
            return root.convert(runtime)
        } catch {
            Log.error(label: JSONRulesParser.LOG_LABEL, "Failed to encode json rules, the error is: \(error)")
            return nil
        }
    }
}

/// Defines the custom type which is strictly mapped to the json rules's structure, then the Json decoder can easily parse json rules to Swift objects
struct JSONRuleRoot: Codable {
    var version: Int
    var rules: [JSONRule]

    /// Converts itself to `LaunchRule` objects, which can be used in `AEPRulesEngine`
    /// - Returns: an array of `LaunchRule` objects
    func convert(_ runtime: ExtensionRuntime? = nil) -> [LaunchRule] {
        var result = [LaunchRule]()
        for launchRule in rules {
            if let conditionExpression = launchRule.condition.convert(runtime) {
                var consequences = [RuleConsequence]()
                for consequence in launchRule.consequences {
                    if let id = consequence.id, let type = consequence.type, let dict = consequence.detailDict {
                        consequences.append(RuleConsequence(id: id, type: type, details: dict))
                    }
                }
                let rule = LaunchRule(condition: conditionExpression, consequences: consequences)
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
    case historical
}

enum EventHistorySearchType: String, Codable {
    case any
    case mostRecent
    case ordered
}

class JSONCondition: Codable {
    static let matcherMapping = ["eq": "equals",
                                 "ne": "notEquals",
                                 "gt": "greaterThan",
                                 "ge": "greaterEqual",
                                 "lt": "lessThan",
                                 "le": "lessEqual",
                                 "co": "contains",
                                 "nc": "notContains",
                                 "sw": "startsWith",
                                 "ew": "endsWith",
                                 "ex": "exists",
                                 "nx": "notExist"]

    var type: ConditionType
    var definition: JSONDefinition

    func convert(_ runtime: ExtensionRuntime? = nil) -> Evaluable? {
        switch type {
        case .group:
            if let operationStr = definition.logic, let subConditions = definition.conditions {
                var operands = [Evaluable]()
                for subCondition in subConditions {
                    if let operand = subCondition.convert(runtime) {
                        operands.append(operand)
                    }
                }
                return operands.count == 0 ? nil : LogicalExpression(operationName: operationStr, operands: operands)
            }
            return nil
        case .matcher:
            let values = definition.values ?? []
            if let key = definition.key, let matcher = definition.matcher {
                if values.count == 0 {
                    return convert(key: key, matcher: matcher, anyCodable: "")
                }
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
                    // For "ne" (not equals) and "nc" (not contains) matchers, use "and" logic instead of "or"
                    // This ensures all conditions must be true: value != A AND value != B AND value != C
                    let logicalOperation = (matcher == "ne" || matcher == "nc") ? "and" : "or"
                    return operands.count == 0 ? nil : LogicalExpression(operationName: logicalOperation, operands: operands)
                }
            }
            return nil
        case .historical:
            return extractHistoricalCondition(runtime)
        }
    }

    func extractHistoricalCondition(_ runtime: ExtensionRuntime?) -> Evaluable? {
        // ensure we have the required values to process this historical lookup
        guard let events = definition.events, let matcherString = definition.matcher, let runtime = runtime,
              let matcher = JSONCondition.matcherMapping[matcherString], let valueAsInt = definition.value?.intValue else {
            Log.warning(label: JSONRulesParser.LOG_LABEL,
                        "Failed to extract historical condition. " +
                        "Missing or invalid required fields in definition: \(definition)")
            return nil
        }

        var fromDate: Date?
        var toDate: Date?
        if let fromTs = definition.from {
            fromDate = Date(milliseconds: fromTs)
        }
        if let toTs = definition.to {
            toDate = Date(milliseconds: toTs)
        }

        // Default search type is `.any`. Replaced by a valid type from `definition.searchType` if provided.
        let searchType = definition.searchType.flatMap(EventHistorySearchType.init) ?? .any

        let requestEvents = events.map({
            EventHistoryRequest(mask: $0, from: fromDate, to: toDate)
        })

        let params: [Any] = [runtime, requestEvents, searchType]
        let historyOperand: Operand<Int>
        switch searchType {
        case .any, .ordered:
            historyOperand = Operand<Int>(function: getHistoricalEventCount, parameters: params)
        case .mostRecent:
            historyOperand = Operand<Int>(function: getMostRecentHistoricalEvent, parameters: params)
        }

        return ComparisonExpression(lhs: historyOperand, operationName: matcher, rhs: Operand(integerLiteral: valueAsInt))
    }

    /// Queries the EventHistory database for matching entries
    ///
    /// For an `.any` search (event order does not matter), the value returned will be the count of all matching events in EventHistory
    /// For an `.ordered` search (events must occur in the provided order), the value returned will be 1 if the events were found in the provided order, or 0 otherwise.
    /// If a database error occurred, this method will always return -1
    ///
    /// - Parameter parameters: An array of parameters containing, in order, an `ExtensionRuntime`, `[EventHistoryRequest]`, and an `EventHistorySearchType`.
    /// - Returns: the number of matching records for an `.any` search, or a boolean (1 or 0) indicating whether search conditions were met for an `.ordered` search.
    func getHistoricalEventCount(parameters: [Any]?) -> Int {
        guard let params = parameters,
              params.count >= 3,
              let runtime = params[0] as? ExtensionRuntime,
              let requestEvents = params[1] as? [EventHistoryRequest],
              let searchType = params[2] as? EventHistorySearchType else {
            return 0
        }
        // Early exit with error value for unsupported search types
        guard searchType != .mostRecent else {
            Log.warning(label: JSONRulesParser.LOG_LABEL, "Unsupported EventHistorySearchType 'mostRecent' in getHistoricalEventCount")
            return -1
        }

        var returnValue: Int = 0
        let semaphore = DispatchSemaphore(value: 0)

        runtime.getHistoricalEvents(requestEvents, enforceOrder: searchType == .ordered) { results in
            defer { semaphore.signal() }
            switch searchType {
            case .any:
                for result in results {
                    // If a database error is returned for any result, early exit and return the error value
                    guard result.count != -1 else {
                        returnValue = -1
                        break
                    }
                    returnValue += result.count
                }
            case .mostRecent:
                // Should be impossible to reach due to early exit guard
                returnValue = -1
            case .ordered:
                for result in results {
                    // If a database error is returned for any result, early exit and return the error value
                    guard result.count != -1 else {
                        returnValue = -1
                        break
                    }
                    // Early exit on ordered searches if any event result returned no records
                    if result.count == 0 {
                        returnValue = 0
                        break
                    }
                    returnValue = 1
                }
            }
        }

        semaphore.wait()
        return returnValue
    }

    /// Returns the index of the most recent historical event based on occurrence timestamp.
    /// If no events are found or an error occurs during lookup, the method returns `-1`.
    /// If duplicate ``EventHistoryRequest``s are provided, the index of the first instance will be returned.
    ///
    /// - Parameter parameters: An array expected to contain, in order:
    ///     - An ``ExtensionRuntime`` instance used to perform historical event lookups.
    ///     - An array of ``EventHistoryRequest`` objects specifying the search criteria.
    ///
    /// - Returns: The index of the event with the most recent occurrence, or `-1` if none are found or there is an error.
    func getMostRecentHistoricalEvent(parameters: [Any]?) -> Int {
        guard let params = parameters,
              params.count >= 2,
              let runtime = params[0] as? ExtensionRuntime,
              let requestEvents = params[1] as? [EventHistoryRequest] else {
            return -1
        }

        var mostRecentIndex = -1
        var mostRecentDate = Date.distantPast
        let semaphore = DispatchSemaphore(value: 0)

        runtime.getHistoricalEvents(requestEvents, enforceOrder: false) { eventResults in
            defer { semaphore.signal() }

            for (index, result) in eventResults.enumerated() {
                // If a database error is returned for any result, early exit and return the error value
                if result.count == -1 {
                    mostRecentIndex = -1
                    return
                }
                // Check that there is a newest occurrence date for this result
                guard let newestOccurrence = result.newestOccurrence else {
                    continue
                }
                // Check if the current result is newer than the current most recent date
                if newestOccurrence > mostRecentDate {
                    mostRecentDate = newestOccurrence
                    mostRecentIndex = index
                }
            }
        }

        semaphore.wait()

        return mostRecentIndex
    }

    func convert(key: String, matcher: String, anyCodable: AnyCodable) -> Evaluable? {
        guard let matcher = JSONCondition.matcherMapping[matcher] else {
            return nil
        }
        if let value = anyCodable.value {
            if matcher == "exists" || matcher == "notExist" {
                return ComparisonExpression(lhs: Operand<Any>(mustache: "{{\(key)}}"), operationName: matcher, rhs: Operand<Any>(mustache: ""))
            }
            switch value {
            case is String:
                if let stringValue = anyCodable.value as? String {
                    return ComparisonExpression(lhs: Operand<String>(mustache: "{{string(\(key))}}"), operationName: matcher, rhs: Operand(stringLiteral: stringValue))
                }
            case is Int:
                if let intValue = anyCodable.value as? Int {
                    return ComparisonExpression(lhs: Operand<Int>(mustache: "{{int(\(key))}}"), operationName: matcher, rhs: Operand(integerLiteral: intValue))
                }
            case is Double:
                if let doubleValue = anyCodable.value as? Double {
                    return ComparisonExpression(lhs: Operand<Double>(mustache: "{{double(\(key))}}"), operationName: matcher, rhs: Operand(floatLiteral: doubleValue))
                }
            case is Bool:
                if let boolValue = anyCodable.value as? Bool {
                    return ComparisonExpression(lhs: Operand<Bool>(mustache: "{{bool(\(key))}}"), operationName: matcher, rhs: Operand(booleanLiteral: boolValue))
                }
            /// rules engine doesn't accept `Float` type, so convert it to `Double` object here.
            case is Float:
                if let floatValue = anyCodable.value as? Float {
                    return ComparisonExpression(lhs: Operand<Float>(mustache: "{{double(\(key))}}"), operationName: matcher, rhs: Operand(floatLiteral: Double(floatValue)))
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
    let events: [[String: AnyCodable]]?
    let value: AnyCodable?
    let from: Int64?
    let to: Int64?
    let searchType: String?
}

struct JSONDetail: Codable {
    let url: String?
}

struct JSONConsequence: Codable {
    let id: String?
    let type: String?
    let detail: AnyCodable?
    let detailDict: [String: Any]?
    enum CodingKeys: CodingKey {
        case id
        case type
        case detail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(String.self, forKey: .id)
        type = try? container.decode(String.self, forKey: .type)
        detail = try? container.decode(AnyCodable.self, forKey: .detail)

        if let detailDictionaryValue = detail?.dictionaryValue {
            detailDict = detailDictionaryValue
        } else {
            detailDict = nil
        }
    }
}
