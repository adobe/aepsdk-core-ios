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
    private static let LAUNCH_RULE_TOKEN_LEFT_DELIMITER = "{%"
    private static let LAUNCH_RULE_TOKEN_RIGHT_DELIMITER = "%}"
    private static let CONSEQUENCE_EVENT_NAME = "Rules Consequence Event"
    private static let CONSEQUENCE_EVENT_DATA_KEY_ID = "id"
    private static let CONSEQUENCE_EVENT_DATA_KEY_TYPE = "type"
    private static let CONSEQUENCE_TYPE_ADD = "add"
    private static let CONSEQUENCE_TYPE_MOD = "mod"

    private let transform = Transform()
    private let extensionRuntime: ExtensionRuntime

    let rulesEngine: RulesEngine<LaunchRule>
    let rulesDownloader: RulesDownloader

    init(extensionRuntime: ExtensionRuntime) {
        let evaluator = ConditionEvaluator(options: .defaultOptions)
        rulesEngine = RulesEngine(evaluator: evaluator)
        rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())
        self.extensionRuntime = extensionRuntime
    }
    
    func trace(with tracer: @escaping RulesTracer){
        rulesEngine.trace(with: tracer)
    }
    
    /// Downloads the rules from the remote server
    /// - Parameter url: the `URL` of the remote urls
    func loadRemoteRules(from url: URL) {
        rulesDownloader.loadRulesFromUrl(rulesUrl: url) { data in
            guard let data = data else{
                return
            }
            
            let rules = JSONRulesParser.parse(data)
            self.rulesEngine.addRules(rules: rules)
            
        }
    }
    
    /// Reads the cached rules
    /// - Parameter url: the `URL` of the remote urls
    func loadCachedRules(for url: URL) {
        guard let data = rulesDownloader.loadRulesFromCache(rulesUrl: url) else{
            return
        }

        let rules = JSONRulesParser.parse(data)
        self.rulesEngine.addRules(rules: rules)
    }
    
    /// Evaluates all the current rules against the supplied `Event`.
    /// - Parameters:
    ///   - event: the `Event` against which to evaluate the rules
    ///   - sharedStates: the `SharedState`s registered to the `EventHub`
    /// - Returns: the  processed`Event`
    func process(event: Event) -> Event {
        let traversableTokenFinder = TokenFinder(event: event, extensionRuntime: extensionRuntime)
        let rules = rulesEngine.evaluate(data: traversableTokenFinder)
        var eventData = event.data
        for rule in rules {
            for consequence in rule.consequences {
                let consequenceWithConcreteValue = replaceToken(for: consequence, data: traversableTokenFinder)
                switch consequenceWithConcreteValue.type {
                case LaunchRulesEngine.CONSEQUENCE_TYPE_ADD:
                    guard let from = consequenceWithConcreteValue.eventData, let to = eventData else{
                        continue
                    }
                    eventData =  EventDataMerger.merging(to: to, from: from, overwrite: false)
                case LaunchRulesEngine.CONSEQUENCE_TYPE_MOD:                    
                    guard let from = consequenceWithConcreteValue.eventData, let to = eventData else{
                        continue
                    }
                    eventData =  EventDataMerger.merging(to: to, from: from, overwrite: true)
                    default:
                    if let event = generateConsequenceEvent(consequence: consequenceWithConcreteValue) {
                        extensionRuntime.dispatch(event: event)
                    }
                }
            }
        }
        event.data = eventData
        return event
    }

    /// Replace tokens inside the provided consequence with the right value
    /// - Parameters:
    ///   - consequence: the `Consequence` instance may contain tokens
    ///   - data: a `Traversable` collection with tokens and related values
    /// - Returns: a new instance of `Consequence`
    func replaceToken(for consequence: Consequence, data: Traversable) -> Consequence {
        let dict = replaceToken(in: consequence.detailDict, data: data)
        return Consequence(id: consequence.id, type: consequence.type, detailDict: dict)
    }
    
    private func replaceToken(in dict: [String: Any?], data: Traversable) -> [String: Any?] {
        var mutableDict = dict
        for (key, value) in mutableDict {
            switch value {
            case is String:
                mutableDict[key] = replaceToken(for: value as! String, data: data)
            case is [String: Any]:
                let valueDict = mutableDict[key] as! [String: Any]
                mutableDict[key] = replaceToken(in: valueDict, data: data)
            default:
                break
            }
        }
        return mutableDict
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
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_TYPE] = consequence.type
        return Event(name: LaunchRulesEngine.CONSEQUENCE_EVENT_NAME, type: EventType.rulesEngine, source: EventSource.responseContent, data: dict)
    }


}
