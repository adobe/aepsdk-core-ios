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

class LifecycleExtension: Extension {
    typealias EventHandlerMapping = (event: Event, handler: (Event) -> (Bool)) // TODO: Move to event hub to make public?
    
    let name = "Lifecycle"
    let version = "0.0.1"
    
    private let eventQueue = OperationOrderer<EventHandlerMapping>("Lifecycle")
    
    // MARK: Extension
    required init() {
        eventQueue.setHandler({ return $0.handler($0.event) })
    }
    
    func onRegistered() {
        registerListener(type: .genericLifecycle, source: .requestContent, listener: receiveLifecycleRequest(event:))
        registerListener(type: .hub, source: .sharedState, listener: receiveSharedState(event:))
        eventQueue.start()
    }
    
    func onUnregistered() {}
    
    // MARK: Event Listeners
    private func receiveLifecycleRequest(event: Event) {
        // TODO
    }
    
    private func receiveSharedState(event: Event) {
        // TODO uncomment when Configuration is merged
//        guard let stateOwner = event.data?[EventHubConstants.Keys.EVENT_STATE_OWNER]?.stringValue else { return }
//
//        if stateOwner == ConfigurationConstants.EXTENSION_NAME {
//            eventQueue.start()
//        }
    }
}
