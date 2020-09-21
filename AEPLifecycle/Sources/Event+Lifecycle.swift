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

import AEPCore
import Foundation

extension Event {
    /// Returns true if this event contains the start value for the Lifecycle action key
    var isLifecycleStartEvent: Bool {
        return actionValue == LifecycleConstants.START
    }

    /// Returns true if this event contains the pause value for the Lifecycle action key
    var isLifecyclePauseEvent: Bool {
        return actionValue == LifecycleConstants.PAUSE
    }

    /// Returns the additional data associated with a Lifecycle event
    var additionalData: [String: Any]? {
        return data?[LifecycleConstants.EventDataKeys.ADDITIONAL_CONTEXT_DATA] as? [String: Any]
    }

    /// Private helper to read the action value out of `data`
    private var actionValue: String? {
        return data?[LifecycleConstants.EventDataKeys.ACTION_KEY] as? String
    }
}
