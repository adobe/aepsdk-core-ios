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

/// A rules engine for Launch rules
public class LaunchRulesEngine {
    private let LOG_TAG = RulesConstants.LOG_MODULE_PREFIX
    private static let LAUNCH_RULE_TOKEN_LEFT_DELIMITER = "{%"
    private static let LAUNCH_RULE_TOKEN_RIGHT_DELIMITER = "%}"
    private static let CONSEQUENCE_EVENT_NAME = "Rules Consequence Event"
    private static let CONSEQUENCE_DISPATCH_EVENT_NAME = "Dispatch Consequence Result"
    private static let CONSEQUENCE_EVENT_DATA_KEY_ID = "id"
    private static let CONSEQUENCE_EVENT_DATA_KEY_TYPE = "type"
    private static let CONSEQUENCE_EVENT_DATA_KEY_DETAIL = "detail"
    private static let CONSEQUENCE_EVENT_DATA_KEY_CONSEQUENCE = "triggeredconsequence"
    private static let CONSEQUENCE_TYPE_ADD = "add"
    private static let CONSEQUENCE_TYPE_MOD = "mod"
    private static let CONSEQUENCE_TYPE_DISPATCH = "dispatch"
    private static let CONSEQUENCE_DETAIL_ACTION_COPY = "copy"
    private static let CONSEQUENCE_DETAIL_ACTION_NEW = "new"
    /// Do not process Dispatch consequence if chained event count is greater than max
    private static let MAX_CHAINED_CONSEQUENCE_COUNT = 1

    private let transformer: Transforming
    private let name: String
    private let rulesQueue: DispatchQueue
    private var waitingEvents: [Event]?
    private var dispatchChainedEventsCount: [UUID: Int] = [:]

    let extensionRuntime: ExtensionRuntime
    let evaluator: ConditionEvaluator
    let rulesEngine: RulesEngine<LaunchRule>

    /// Creates a new rules engine instance
    /// - Parameters:
    ///   - name: the unique name for the current instance
    ///   - extensionRuntime: the `extensionRuntime`
    public init(name: String, extensionRuntime: ExtensionRuntime) {
        self.name = name
        rulesQueue = DispatchQueue(label: "com.adobe.rulesengine.\(name)")
        transformer = LaunchRuleTransformer(runtime: extensionRuntime).transformer
        evaluator = ConditionEvaluator(options: .caseInsensitive)
        rulesEngine = RulesEngine(evaluator: evaluator, transformer: transformer)
        waitingEvents = [Event]()
        // you can enable the log when debugging rules engine
//        if RulesEngineLog.logging == nil {
//            RulesEngineLog.logging = RulesEngineNativeLogging()
//        }
        self.extensionRuntime = extensionRuntime
    }

    /// Register a `RulesTracer`
    /// - Parameter tracer: a `RulesTracer` closure to know result of rules evaluation
    func trace(with tracer: @escaping RulesTracer) {
        rulesEngine.trace(with: tracer)
    }

    /// Set a new set of rules, the new rules replace the current rules. A RulesEngine Reset event will be dispatched to trigger the reprocess for the waiting events.
    /// - Parameter rules: the array of new `LaunchRule`
    public func replaceRules(with rules: [LaunchRule]) {
        rulesQueue.sync {
            self.rulesEngine.clearRules()
            self.rulesEngine.addRules(rules: rules)
            Log.debug(label: self.LOG_TAG, "Successfully loaded \(rules.count) rule(s) into the (\(self.name)) rules engine.")
        }
        self.sendReprocessEventsRequest()
    }

    /// Adds provided rules to the current rules.
    /// - Parameter rules: the array of `LaunchRule`s to be added
    public func addRules(_ rules: [LaunchRule]) {
        rulesQueue.sync {
            self.rulesEngine.addRules(rules: rules)
            Log.debug(label: self.LOG_TAG, "Successfully added \(rules.count) rule(s) into the (\(self.name)) rules engine.")
        }
    }

    /// Evaluates all the current rules against the supplied `Event`.
    /// - Parameter event: the `Event` against which to evaluate the rules
    /// - Returns: the processed `Event`
    @discardableResult
    public func process(event: Event) -> Event {
        rulesQueue.sync {
            // if our waitingEvents array is nil, we know we have rules registered and can skip to evaluation
            guard let currentWaitingEvents = waitingEvents else {
                return evaluateRules(for: event)
            }

            // check if this is an event to kick processing of waitingEvents
            // otherwise, add the event to waitingEvents
            if (event.data?[RulesConstants.Keys.RULES_ENGINE_NAME] as? String) == name, event.source == EventSource.requestReset, event.type == EventType.rulesEngine {
                for currentEvent in currentWaitingEvents {
                    _ = evaluateRules(for: currentEvent)
                }
                waitingEvents = nil
            } else {
                waitingEvents?.append(event)
            }
            return evaluateRules(for: event)
        }
    }

    /// Evaluates the current rules against the supplied `Event`.
    ///
    /// Instead of dispatching consequence `Event`s for matching rules, this method returns 
    /// an array of `RuleConsequence` objects.
    ///
    /// Calling this method will not check for `self.waitingEvents`, but rather it's assumed that the caller
    /// will not invoke this message prior to configuration being available.
    ///
    /// - Parameter event: the `Event` against which to evaluate the rules
    /// - Returns: an array of `RuleConsequence` objects resulting from `event` being processed
    public func evaluate(event: Event) -> [RuleConsequence]? {
        rulesQueue.sync {
            return evaluateConsequence(for: event)
        }
    }

    /// Evaluates rules for an `Event` and returns an array of matching `RuleConsequence` instead of processing them.
    ///
    /// - Parameter event: the `Event` against which to evaluate the rules
    /// - Returns: an array of `RuleConsequence` objects resulting from `event` being processed
    private func evaluateConsequence(for event: Event) -> [RuleConsequence]? {
        let traversableTokenFinder = TokenFinder(event: event, extensionRuntime: extensionRuntime)
        let matchedRules = rulesEngine.evaluate(data: traversableTokenFinder)
        guard !matchedRules.isEmpty else {
            return nil
        }

        var tokenReplacedConsequences: [RuleConsequence] = []
        for rule in matchedRules {
            tokenReplacedConsequences.append(contentsOf: rule.consequences.map { replaceToken(for: $0, data: traversableTokenFinder)
            })
        }

        return tokenReplacedConsequences
    }

    private func evaluateRules(for event: Event) -> Event {
        let dispatchChainCount = dispatchChainedEventsCount.removeValue(forKey: event.id)
        let traversableTokenFinder = TokenFinder(event: event, extensionRuntime: extensionRuntime)
        var matchedRules: [LaunchRule]?
        matchedRules = rulesEngine.evaluate(data: traversableTokenFinder)
        guard let matchedRulesUnwrapped = matchedRules else {
            return event
        }

        var processedEvent = event
        for rule in matchedRulesUnwrapped {
            for consequence in rule.consequences {
                let consequenceWithConcreteValue = replaceToken(for: consequence, data: traversableTokenFinder)
                switch consequenceWithConcreteValue.type {
                case LaunchRulesEngine.CONSEQUENCE_TYPE_ADD:
                    guard let attachedEventData = processAttachDataConsequence(consequence: consequenceWithConcreteValue, eventData: processedEvent.data) else {
                        continue
                    }
                    processedEvent = processedEvent.copyWithNewData(data: attachedEventData)

                case LaunchRulesEngine.CONSEQUENCE_TYPE_MOD:
                    guard let modifiedEventData = processModifyDataConsequence(consequence: consequenceWithConcreteValue, eventData: processedEvent.data) else {
                        continue
                    }
                    processedEvent = processedEvent.copyWithNewData(data: modifiedEventData)

                case LaunchRulesEngine.CONSEQUENCE_TYPE_DISPATCH:

                    if let unwrappedDispatchCount = dispatchChainCount, unwrappedDispatchCount >= LaunchRulesEngine.MAX_CHAINED_CONSEQUENCE_COUNT {
                        Log.trace(label: LOG_TAG, "(\(self.name)) : Unable to process dispatch consequence, max chained dispatch consequences limit of \(LaunchRulesEngine.MAX_CHAINED_CONSEQUENCE_COUNT) met for this event uuid \(event.id)")
                        continue
                    }
                    guard let dispatchEvent = processDispatchConsequence(consequence: consequenceWithConcreteValue, processedEvent: processedEvent)  else {
                        continue
                    }
                    Log.trace(label: LOG_TAG, "(\(self.name)) : Generating new dispatch consequence result event \(dispatchEvent)")
                    extensionRuntime.dispatch(event: dispatchEvent)

                    // Keep track of dispatch consequence events to prevent triggering of infinite dispatch consequences
                    dispatchChainedEventsCount[dispatchEvent.id] = (dispatchChainCount ?? 0) + 1

                default:
                    if let event = generateConsequenceEvent(consequence: consequenceWithConcreteValue, parentEvent: processedEvent) {
                        Log.trace(label: LOG_TAG, "(\(self.name)) : Generating new consequence event \(event)")
                        extensionRuntime.dispatch(event: event)
                    }
                }
            }
        }

        return processedEvent
    }

    /// Process an attach data consequence event.  Attaches event data from the RuleConsequence to the triggering Event data without overwriting the original
    /// Event data. If either the event data from the RuleConsequence or the triggering Event data is nil then the processing is aborted.
    /// - Parameters:
    ///   - consequence: the RuleConsequence which contains the event data to attach
    ///   - eventData: the triggering Event data
    /// - Returns: event data with the RuleConsequence data attached to the triggering Event data, or nil if the processing fails
    private func processAttachDataConsequence(consequence: RuleConsequence, eventData: [String: Any]?) -> [String: Any]? {
        guard let from = consequence.eventData else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process an AttachDataConsequence Event, 'eventData' is missing from 'details'")
            return nil
        }
        guard let to = eventData else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process an AttachDataConsequence Event, 'eventData' is missing from original event")
            return nil
        }
        Log.trace(label: LOG_TAG, "(\(self.name)) : Attaching event data: \(PrettyDictionary.prettify(from)) to \(PrettyDictionary.prettify(to))\n")
        return EventDataMerger.merging(to: to, from: from, overwrite: false)
    }

    /// Process a modify data consequence event. Modifies the triggering Event data by merging the event data from the RuleConsequence onto it. If either
    /// the event data from the RuleConsequence or the triggering Event data is nil, then the processing is aborted.
    /// - Parameters:
    ///   - consequence: the RuleConsequence which contains the event data to merge
    ///   - eventData: the triggering Event data to modify
    /// - Returns: event data with the Event data modified with the RuleConsequence data, or nil if the processing fails
    private func processModifyDataConsequence(consequence: RuleConsequence, eventData: [String: Any]?) -> [String: Any]? {
        guard let from = consequence.eventData else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a ModifyDataConsequence Event, 'eventData' is missing from 'details'")
            return nil
        }
        guard let to = eventData else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a ModifyDataConsequence Event, 'eventData' is missing from original event")
            return nil
        }
        Log.trace(label: LOG_TAG, "(\(self.name)) : Modifying event data: \(PrettyDictionary.prettify(to)) with data: \(PrettyDictionary.prettify(from))\n")
        return EventDataMerger.merging(to: to, from: from, overwrite: true)
    }

    /// Process a dispatch consequence event. Generates a new Event from the details contained within the RuleConsequence.
    /// - Parameters:
    ///   - consequence: the RuleConsequence which contains details on the new Event to generate
    ///   - processedEvent: the dispatch consequence event to be processed
    /// - Returns: a new Event to be dispatched to the EventHub, or nil if the processing failed.
    private func processDispatchConsequence(consequence: RuleConsequence, processedEvent: Event) -> Event? {
        guard let type = consequence.eventType else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a DispatchConsequence Event, 'type' is missing from 'details'")
            return nil
        }
        guard let source = consequence.eventSource else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a DispatchConsequence Event, 'source' is missing from 'details'")
            return nil
        }
        guard let action = consequence.eventDataAction else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a DispatchConsequence Event, 'eventdataaction' is missing from 'details'")
            return nil
        }

        var dispatchEventData: [String: Any]?
        if action == LaunchRulesEngine.CONSEQUENCE_DETAIL_ACTION_COPY {
            dispatchEventData = processedEvent.data // copy event data from triggering event
        } else if action == LaunchRulesEngine.CONSEQUENCE_DETAIL_ACTION_NEW {
            dispatchEventData = consequence.eventData?.compactMapValues { $0 }
        } else {
            Log.error(label: LOG_TAG, "(\(self.name)) : Unable to process a DispatchConsequence Event, unsupported 'eventdataaction', expected values copy/new")
            return nil
        }

        return processedEvent.createChainedEvent(name: LaunchRulesEngine.CONSEQUENCE_DISPATCH_EVENT_NAME,
                                                 type: type,
                                                 source: source,
                                                 data: dispatchEventData)
    }

    /// Replace tokens inside the provided consequence with the right value
    /// - Parameters:
    ///   - consequence: the `Consequence` instance may contain tokens
    ///   - data: a `Traversable` collection with tokens and related values
    /// - Returns: a new instance of `Consequence`
    internal func replaceToken(for consequence: RuleConsequence, data: Traversable) -> RuleConsequence {
        let dict = replaceToken(in: consequence.details, data: data)
        return RuleConsequence(id: consequence.id, type: consequence.type, details: dict)
    }

    private func replaceToken(in value: Any, data: Traversable) -> Any {
        switch value {
        case let valString as String:
            return replaceToken(for: valString, data: data)
        case let nestedDict as [String: Any?]:
            return replaceToken(in: nestedDict, data: data)
        case let nestedArray as [Any]:
            return replaceToken(in: nestedArray, data: data)
        default:
            return value
        }
    }

    private func replaceToken(in dict: [String: Any?], data: Traversable) -> [String: Any?] {
        var mutableDict = dict
        for (key, value) in mutableDict {
            if let value = value {
                mutableDict[key] = replaceToken(in: value, data: data)
            }
        }
        return mutableDict
    }

    private func replaceToken(in array: [Any], data: Traversable) -> [Any] {
        return array.map { replaceToken(in: $0, data: data) }
    }

    private func replaceToken(for value: String, data: Traversable) -> String {
        let template = Template(templateString: value, tagDelimiterPair: (LaunchRulesEngine.LAUNCH_RULE_TOKEN_LEFT_DELIMITER, LaunchRulesEngine.LAUNCH_RULE_TOKEN_RIGHT_DELIMITER))
        return template.render(data: data, transformers: transformer)
    }

    private func sendReprocessEventsRequest() {
        extensionRuntime.dispatch(event: Event(name: name, type: EventType.rulesEngine, source: EventSource.requestReset, data: [RulesConstants.Keys.RULES_ENGINE_NAME: name]))
    }

    /// Generate a consequence event with provided consequence data
    /// - Parameter consequence: a consequence of the rule
    /// - Returns: a consequence `Event`
    private func generateConsequenceEvent(consequence: RuleConsequence, parentEvent: Event) -> Event? {
        var dict: [String: Any] = [:]
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_DETAIL] = consequence.details
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_ID] = consequence.id
        dict[LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_TYPE] = consequence.type
        return parentEvent.createChainedEvent(name: LaunchRulesEngine.CONSEQUENCE_EVENT_NAME, type: EventType.rulesEngine, source: EventSource.responseContent, data: [LaunchRulesEngine.CONSEQUENCE_EVENT_DATA_KEY_CONSEQUENCE: dict])
    }
}

/// Extend RuleConsequence with helper methods for processing Dispatch Consequence events.
extension RuleConsequence {
    public var eventSource: String? {
        return details["source"] as? String
    }

    public var eventType: String? {
        return details["type"] as? String
    }

    public var eventDataAction: String? {
        return details["eventdataaction"] as? String
    }
}
