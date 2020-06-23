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
class ExtensionContainer {
    
    /// The extension held in this container
    var exten: Extension? = nil
    
    /// The `SharedState` associated with the extension
    var sharedState: SharedState? = nil
    
    var sharedStateName: String? = nil
    
    /// The extension's dispatch queue
    let extensionQueue: DispatchQueue
    
    /// Operation Orderer queue of `Event` objects for this extension
    let eventOrderer: OperationOrderer<Event>
    
    /// Listeners array of `EventListeners` for this extension
    let eventListeners: ThreadSafeArray<EventListenerContainer>
    
    /// Listeners array of `EventListeners` that are listening for a specific response event
    let responseEventListeners: ThreadSafeArray<EventListenerContainer>
    
    init(_ type: Extension.Type, _ queue: DispatchQueue) {
        extensionQueue = queue
        eventOrderer = OperationOrderer<Event>()
        eventListeners = ThreadSafeArray<EventListenerContainer>()
        responseEventListeners = ThreadSafeArray<EventListenerContainer>()
        eventOrderer.setHandler(eventProcessor)
        
        // initialize the backing extension on the extension queue
        queue.async {
            self.exten = type.init()
            self.sharedState = SharedState(self.exten!.name)
            self.sharedStateName = self.exten!.name
            self.exten!.onRegistered()
            self.eventOrderer.start()
        }
    }
}

extension ExtensionContainer {
    public func registerListener(type: EventType, source: EventSource, preflight: @escaping EventListenerPreflight = { _ in true }, listener: @escaping EventListener) {
        let listenerContainer = EventListenerContainer(listener: listener, preflight: preflight,
                                                       type: type, source: source, triggerEventId: nil, timeoutTask: nil)
        eventListeners.append(listenerContainer)
    }
    
    public func registerResponseListener(triggerEvent: Event, timeout: TimeInterval, listener: @escaping EventResponseListener) {
        let timeoutTask = DispatchWorkItem {
            listener(nil)
            _ = self.responseEventListeners.filterRemove { $0.triggerEventId == triggerEvent.id }
        }
        extensionQueue.asyncAfter(deadline: DispatchTime.now() + timeout, execute: timeoutTask)
        let responseListenerContainer = EventListenerContainer(listener: listener, triggerEventId: triggerEvent.id, timeout: timeoutTask)
        responseEventListeners.append(responseListenerContainer)
    }
}

private extension ExtensionContainer {
    private func eventProcessor(_ event: Event) -> Bool {
        // process events into "standard" listeners
        for listenerContainer in eventListeners.shallowCopy {
            guard listenerContainer.preflight(event) else { return false }
            if listenerContainer.shouldNotify(event) {
                listenerContainer.listener(event)
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
