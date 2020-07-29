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
@_implementationOnly import SwiftRulesEngine

/// A rules engine for Launch rules
struct LaunchRulesEngine {
    let rulesEngine: RulesEngine<LaunchRule>
    let rulesDownloader: RulesDownloader
    private static let LAUNCH_RULE_TOKEN_LEFT_DELIMITER = "{%"
    private static let LAUNCH_RULE_TOKEN_RIGHT_DELIMITER = "%}"
    private static let CONSEQUENCE_EVENT_NAME = "Rules Consequence Event"
    private static let CONSEQUENCE_EVENT_DATA_KEY_ID = "id"
    private static let CONSEQUENCE_EVENT_DATA_KEY_TYPE = "type"
    private let transform = Transform()
    
    init() {
        let evaluator = ConditionEvaluator(options: .defaultOptions)
        rulesEngine = RulesEngine(evaluator: evaluator)
        rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())
    }
    
    /// Downloads the rules from the remote server
    /// - Parameter url: the `URL` of the remote urls
    func loadRemoteRules(from url: URL) {}
    
    /// Reads the cached rules
    /// - Parameter url: the `URL` of the remote urls
    func loadCachedRules(for url: URL) {}
    
    /// Evaluates all the current rules against the supplied `Event`.
    /// - Parameters:
    ///   - event: the `Event` against which to evaluate the rules
    ///   - sharedStates: the `SharedState`s registered to the `EventHub`
    /// - Returns: the  processed`Event`
    func process(event: Event) -> Event {
        var eventCopy = event
        if let data = generateTraversableData(event: event) {
            let rules = rulesEngine.evaluate(data: data)
            for rule in rules {
                for consequence in rule.consequences {
                    let consequenceWithConcreteValue = replaceToken(for: consequence, data: data)
                    switch consequenceWithConcreteValue.type {
                    case .url, .pii, .pb:
                        if let event = generateConsequenceEvent(consequence: consequenceWithConcreteValue) {
                            EventHub.shared.dispatch(event: event)
                        }
                    case .add:
                        attachDataEvent(event: &eventCopy, consequenceWithConcreteValue: consequenceWithConcreteValue)
                    case .mod:
                        modifyDataEvent(event: &eventCopy, consequenceWithConcreteValue: consequenceWithConcreteValue)
                    }
                }
            }
        }
        return eventCopy
    }
    
    private func generateTraversableData(event: Event) -> Traversable? {
        // TODO: generate traversable data from current event and shared events
        return nil
    }
    
    /// Replace tokens inside the provided consequence with the right value
    /// - Parameters:
    ///   - consequence: the `Consequence` instance may contain tokens
    ///   - data: a `Traversable` collection with tokens and related values
    /// - Returns: a new instance of `Consequence`
    func replaceToken(for consequence: Consequence, data: Traversable) -> Consequence {
        var dict = consequence.detailDict
        replaceToken(in: &dict, data: data)
        return Consequence(id: consequence.id, type: consequence.type, detailDict: dict)
    }
    
    private func replaceToken(in dict: inout [String: Any], data: Traversable) {
        for (key, value) in dict {
            switch value {
            case is String:
                dict[key] = replaceToken(for: value as! String, data: data)
            case is [String: Any]:
                var valueDict = dict[key] as! [String: Any]
                replaceToken(in: &valueDict, data: data)
                dict[key] = valueDict
            default:
                return
            }
        }
    }
    
    private func replaceToken(for value: String, data: Traversable) -> String {
        let template = Template(templateString: value, tagDelimiterPair: (LaunchRulesEngine.LAUNCH_RULE_TOKEN_LEFT_DELIMITER, LaunchRulesEngine.LAUNCH_RULE_TOKEN_RIGHT_DELIMITER))
        return template.render(data: data, transformers: transform)
    }
    
    /// Generate a consequence event with provided consequence data
    /// - Parameter consequence: a consequence of the rule
    /// - Returns: a consequence `Event`
    private func generateConsequenceEvent(consequence: Consequence) -> Event? {
        var dict: [String: Any] = consequence.detailDict
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_ID] = consequence.id
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_TYPE] = consequence.type.rawValue
        return Event(name: LaunchRulesEngine.CONSEQUENCE_EVENT_NAME, type: .rulesEngine, source: .responseContent, data: dict)
    }
    
    private func attachDataEvent(event: inout Event, consequenceWithConcreteValue: Consequence) {
        // TODO: attach data to the incoming event
    }
    
    private func modifyDataEvent(event: inout Event, consequenceWithConcreteValue: Consequence) {
        // TODO: modify data of the incoming event
    }
}
