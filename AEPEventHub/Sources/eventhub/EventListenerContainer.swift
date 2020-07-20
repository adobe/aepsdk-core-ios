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

/// Contains an `EventListener` and additional information related to the listener
struct EventListenerContainer: Equatable {
    /// Equatable
    static func == (lhs: EventListenerContainer, rhs: EventListenerContainer) -> Bool {
            lhs.type == rhs.type &&
            lhs.source == rhs.source &&
            lhs.triggerEventId == rhs.triggerEventId
    }
    
    /// The `EventListener`
    let listener: EventListener
        
    /// The `EventType` `listener` is listening for, nil if `listener` is a response listener
    let type: EventType?
    
    /// The `EventSource` `listener` is listening for, nil if `listener` is a response listener
    let source: EventSource?
    
    /// If `listener` was registered as a response listener, `triggerEventId` will equal the `Event.id` of the `Event` who will trigger the response `Event`
    let triggerEventId: UUID?
    
    /// A DispatchWorkItem that is scheduled on the `EventHub` thread which will be executed after half a second if the listener has not already be notified to signify a timeout
    let timeoutTask: DispatchWorkItem?

    /// Returns true if `listener` should be notified of the `Event`, false otherwise
    /// - Parameter event: An `Event` being dispatched by `EventHub`
    func shouldNotify(_ event: Event) -> Bool {
        if let listenerTriggerId = triggerEventId {
            return listenerTriggerId == event.responseID
        }
        
        return (event.type == type || type == .wildcard)
               && (event.source == source || source == .wildcard)
    }
}

internal extension EventListenerContainer {
    /// Additional convenience initializer for constructing an `EventResponseListener` based `EventListenerContainer`
    /// - Parameters:
    ///     - listener: Closure to be executed when the matching event is received
    ///     - triggerEventId: The event `UUID` that this `EventResponseListener` is waiting for
    ///     - timeout: `DispatchWorkItem` to be invoked if the event is not received in time.
    init(listener: @escaping EventResponseListener, triggerEventId: UUID, timeout: DispatchWorkItem?) {
        self.init(listener: listener, type: nil, source: nil, triggerEventId: triggerEventId, timeoutTask: timeout)
    }
}
