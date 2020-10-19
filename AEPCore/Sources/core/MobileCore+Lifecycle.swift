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

/// Defines the public interface for the Lifecycle extension
@objc
public extension MobileCore {
    /// Start a new lifecycle session or resume a previously paused lifecycle session. If a previously paused
    /// session timed out, then a new session is created. If a current session is running, then calling this
    /// method does nothing.
    /// - Parameter additionalContextData: Optional additional context for this session.
    @objc(lifecycleStart:)
    static func lifecycleStart(additionalContextData: [String: Any]?) {
        let data: [String: Any] = [CoreConstants.Keys.ACTION: CoreConstants.Lifecycle.START,
                                   CoreConstants.Keys.ADDITIONAL_CONTEXT_DATA: additionalContextData ?? [:]]
        let event = Event(name: CoreConstants.EventNames.LIFECYCLE_RESUME, type: EventType.genericLifecycle, source: EventSource.requestContent, data: data)
        MobileCore.dispatch(event: event)
    }

    /// Pauses the current lifecycle session. Calling pause on an already paused session updates the paused timestamp,
    /// having the effect of resetting the session timeout timer. If no lifecycle session is running,
    /// then calling this method does nothing.
    @objc(lifecyclePause)
    static func lifecyclePause() {
        let data = [CoreConstants.Keys.ACTION: CoreConstants.Lifecycle.PAUSE]
        let event = Event(name: CoreConstants.EventNames.LIFECYCLE_PAUSE, type: EventType.genericLifecycle, source: EventSource.requestContent, data: data)
        MobileCore.dispatch(event: event)
    }
}
