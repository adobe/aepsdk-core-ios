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
struct EventListenerContainer {
    /// The `EventListener`
    let listener: EventListener
    
    /// The parent extension which registered this listener
    let parentExtensionName: String
    
    /// The `EventType` `listener` is listening for, nil if `listener` is a response listener
    let type: EventType?
    
    /// The `EventSource` `listener` is listening for, nil if `listener` is a response listener
    let source: EventSource?
    
    /// If `listener` was registered as a response listener, `triggerEventId` will equal the `Event.id` of the `Event` who will trigger the response `Event`
    let triggerEventId: UUID?
    
    /// Returns true if `listener` should be notified of the `Event`, false otherwise
    /// - Parameter event: An `Event` being dispatched by `EventHub`
    func shouldNotify(event: Event) -> Bool {
        if let listenerTriggerId = triggerEventId {
            return listenerTriggerId == event.responseID
        }
        
        return (event.type == type || type == .wildcard)
               && (event.source == source || source == .wildcard)
    }
}
