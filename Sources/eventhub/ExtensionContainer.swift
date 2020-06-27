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
        
    init(_ type: Extension.Type, _ queue: DispatchQueue) {
        extensionQueue = queue
        eventOrderer = OperationOrderer<Event>()
        eventListeners = ThreadSafeArray<EventListenerContainer>()
        eventOrderer.setHandler(eventProcessor)
        
        // initialize the backing extension on the extension queue
        extensionQueue.async {
            self.exten = type.init()
            guard let unwrappedExtension = self.exten else { return }
            self.sharedState = SharedState(unwrappedExtension.name)
            self.sharedStateName = unwrappedExtension.name
            unwrappedExtension.onRegistered()
            self.eventOrderer.start()
        }
    }
}

extension ExtensionContainer {
    /// Registers an `EventListener` for the specified `EventType` and `EventSource`
    /// - Parameters:
    ///   - type: `EventType` to listen for
    ///   - source: `EventSource` to listen for
    ///   - listener: Function or closure which will be invoked whenever the `EventHub` receives an `Event` matching `type` and `source`
    public func registerListener(type: EventType, source: EventSource, listener: @escaping EventListener) {
        let listenerContainer = EventListenerContainer(listener: listener, type: type, source: source, triggerEventId: nil, timeoutTask: nil)
        eventListeners.append(listenerContainer)
    }
}

private extension ExtensionContainer {
    /// Handles event processing, called by the `OperationOrderer` owned by this `ExtensionContainer`
    /// - Parameter event: Event currently being processed
    /// - Returns: *true* if event processing should continue, *false* otherwise
    private func eventProcessor(_ event: Event) -> Bool {
        guard let _ = exten, exten!.readyForEvent(event) else { return false }

        // process events into "standard" listeners
        for listenerContainer in eventListeners.shallowCopy {
            if listenerContainer.shouldNotify(event) {
                listenerContainer.listener(event)
            }
        }
                
        return true
    }
}
