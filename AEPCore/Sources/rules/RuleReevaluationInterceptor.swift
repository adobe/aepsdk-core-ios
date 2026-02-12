/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Protocol for intercepting rule evaluation when reevaluable rules are triggered
public protocol RuleReevaluationInterceptor {
    /// Called when reevaluable rules match an event
    /// - Parameters:
    ///   - event: The event that triggered the rules
    ///   - reevaluableRules: Rules marked as reevaluable
    ///   - completion: Call when done with `true` for success (triggers re-evaluation) or `false` for failure (skips re-evaluation)
    func onReevaluationTriggered(
        event: Event,
        reevaluableRules: [LaunchRule],
        completion: @escaping (Bool) -> Void
    )
}

