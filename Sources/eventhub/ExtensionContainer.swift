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

/// Contains an `Extension` and additional information related to the extension
struct ExtensionContainer {
    
    /// The extension held in this container
    let exten: Extension
    
    /// The `SharedState` associated with the extension
    let sharedState: SharedState
    
    /// The extension's dispatch queue
    let extensionQueue: DispatchQueue
    
    /// Operation Orderer queue of `Event` objects for this extension
    let eventOrderer: OperationOrderer<Event>
    
    /// Listeners array of `EventListeners` for this extension
    let eventListeners: ThreadSafeArray<EventListenerContainer>
    
    /// Listeners array of `EventListeners` that are listening for a specific response event
    let responseEventListeners: ThreadSafeArray<EventListenerContainer>
    
    init(_ type: Extension.Type, _ queue: DispatchQueue) {
        exten = type.init()
        sharedState = SharedState(exten.name)
        extensionQueue = queue
        eventOrderer = OperationOrderer<Event>()
        eventListeners = ThreadSafeArray<EventListenerContainer>()
        responseEventListeners = ThreadSafeArray<EventListenerContainer>()
        eventOrderer.setHandler(eventProcessor)
    }
}

private extension ExtensionContainer {
    private func eventProcessor(_ event: Event) -> Bool {
        // process events into "standard" listeners
        eventListeners.shallowCopy.forEach {
            if ($0.shouldNotify(event: event)) {
                $0.listener(event)
            }
        }
        
        // process one-time listeners
        if let responseID = event.responseID {
            responseEventListeners.filterRemove {
                $0.triggerEventId == responseID
            }.forEach {
                $0.timeoutTask?.cancel()
                $0.listener(event)
            }
        }
        
        return true
    }
}
