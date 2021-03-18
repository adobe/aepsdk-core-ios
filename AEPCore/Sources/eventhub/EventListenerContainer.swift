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

/// Contains an `EventListener` and additional information related to the listener.
struct EventListenerContainer: Equatable {
    /// Equatable
    static func == (lhs: EventListenerContainer, rhs: EventListenerContainer) -> Bool {
        lhs.type == rhs.type &&
            lhs.source == rhs.source &&
            lhs.triggerEventId == rhs.triggerEventId
    }

    /// The `EventListener`
    let listener: EventListener

    /// The `EventType` for which `listener` is listening.
    /// If `listener` is an `EventResponseListener`, `type` will be `nil`.
    let type: String?

    /// The `EventSource` for which `listener` is listening.
    /// If `listener` is an `EventResponseListener`, `source` will be `nil`.
    let source: String?

    /// Holds a reference to the `Event.id` of the `Event` for which this `Event` is responding.
    /// If `listener` is an `EventListener`, `triggerEventId` will be `nil`.
    let triggerEventId: UUID?

    /// A DispatchWorkItem that is scheduled on the `EventHub` thread which will be executed after 500 ms
    /// provided the `listener` has not already been notified of a timeout
    let timeoutTask: DispatchWorkItem?

    /// Determines if `listener` should be notified of `event`
    /// - Parameter event: An `Event` being dispatched by the `EventHub`
    /// - Returns: True if `listener` should be notified of `event`
    func shouldNotify(_ event: Event) -> Bool {
        if event.responseID != nil {
            return event.responseID == triggerEventId || self.isWildcard
        }

        return (event.type == type || type == EventType.wildcard)
            && (event.source == source || source == EventSource.wildcard)
    }
}

internal extension EventListenerContainer {
    /// Additional convenience initializer for constructing an `EventListenerContainer` with a backing `EventResponseListener`
    /// - Parameters:
    ///     - listener: Closure to be executed when the matching event is received
    ///     - triggerEventId: The event `UUID` that this `EventResponseListener` is waiting for
    ///     - timeout: `DispatchWorkItem` to be invoked if the event is not received in time
    init(listener: @escaping EventResponseListener, triggerEventId: UUID, timeout: DispatchWorkItem?) {
        self.init(listener: listener, type: nil, source: nil, triggerEventId: triggerEventId, timeoutTask: timeout)
    }

    var isWildcard: Bool {
        return self.source == EventSource.wildcard && self.type == EventType.wildcard
    }
}
