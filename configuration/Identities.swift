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

/// Responsible for retrieving the configuration of the SDK and updating the shared state and dispatching configuration updates through the `EventHub`
class Identities: ExtensionContext<AEPConfiguration> {

    private let eventQueue = OperationOrderer<EventHandlerMapping>(ConfigurationConstants.EXTENSION_NAME)
    
    // MARK: Extension
    
    required override init() {
        eventQueue.setHandler({ return $0.handler($0.event) })
    }
    
    func registerListners(){
        
        registerListener(type: .genericIdentity, source: .requestContent, listener: receiveIdentitesRequest(event:))
    }

    // MARK: Event Listeners
    
    func receiveIdentitesRequest(event: Event) {
        eventQueue.add((event, handleIdentitiesRequest(event:)))
    }
    

    // MARK: Event Handlers
    private func handleIdentitiesRequest(event: Event) -> Bool {
       
        return true
    }
  

}
