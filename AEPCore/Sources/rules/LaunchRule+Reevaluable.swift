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

/// Extension providing re-evaluation support for LaunchRule.
/// These methods help determine which rules can trigger re-evaluation
/// and which consequence types support the re-evaluation flow.
extension LaunchRule {
    
    /// Consequence types that support re-evaluation.
    /// Currently, only "schema" consequences are considered re-evaluable.
    static let reevaluableConsequenceTypes: Set<String> = ["schema"]
    
    /// Indicates whether this rule should trigger re-evaluation when matched.
    /// Reads from `meta["reEvaluate"]`, defaults to `false` if not present.
    public var reevaluable: Bool {
        return meta?["reEvaluate"] as? Bool ?? false
    }
    
    /// Returns `true` if this rule has at least one consequence type that supports re-evaluation.
    /// Currently, only "schema" consequences are considered re-evaluable.
    ///
    /// - Returns: `true` if the rule contains a consequence that supports re-evaluation, `false` otherwise.
    func hasReevaluableSupportedConsequence() -> Bool {
        for consequence in consequences {
            if LaunchRule.reevaluableConsequenceTypes.contains(consequence.type) {
                return true
            }
        }
        return false
    }
}
