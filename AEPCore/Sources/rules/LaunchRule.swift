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
import AEPRulesEngine

/// A `Rule` type represents the functions defined by Launch UI
public struct LaunchRule: Rule {
    public let condition: Evaluable
    public let consequences: [RuleConsequence]
    
    /// Indicates whether this rule should trigger re-evaluation when matched.
    /// When `true`, the rules engine will notify registered interceptors and allow them
    /// to update rules before processing consequences.
    public let reevaluable: Bool

    /// Creates a new LaunchRule instance.
    /// - Parameters:
    ///   - condition: The condition that must be satisfied for this rule to match
    ///   - consequences: The list of consequences to execute when the rule matches
    ///   - reevaluable: Whether this rule should trigger re-evaluation flow. Defaults to `false`.
    init(condition: Evaluable, consequences: [RuleConsequence], reevaluable: Bool = false) {
        self.condition = condition
        self.consequences = consequences
        self.reevaluable = reevaluable
    }
}
