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
    /// - Parameter event: the `Event` against which to evaluate the rules
    /// - Returns: the  processed`Event`
    func process(event: Event) -> Event {
        // evaluate => consequences
        // replace token
        // modify/add data
        // dispatch pb/url/pii
        return event
    }
    
    func replaceToken(consequence: Consequence, data: Traversable) -> Consequence { 
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
                break
            }
        }
    }
    
    private func replaceToken(for value: String, data: Traversable) -> String {
        let template = Template(templateString: value, tagDelimiterPair: ("{%", "%}"))
        let transform = Transform()
        return template.render(data: data, transformers: transform)
    }
    
    private func generateConsequenceEvents(consequences: [Consequence]) -> [Event] {
        var events = [Event]()
        for consequence in consequences {
            if let event = consequence.generateConsequenceEvent() {
                events.append(event)
            }
        }
        return events
    }
    
    private func attachDataEvent() {}
}
