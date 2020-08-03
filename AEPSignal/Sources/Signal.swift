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
import AEPCore
import AEPServices

@objc(AEPService)
public class Service: NSObject, Extension {
    
    // MARK: - Extension
    
    public let runtime: ExtensionRuntime
    
    public let name = SignalConstants.EXTENSION_NAME
    public let friendlyName = SignalConstants.FRIENDLY_NAME
    public let version = SignalConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }
    
    public func onRegistered() {
//        registerListener(type: .identity, source: .requestIdentity, listener: handleIdentityRequest)
//        registerListener(type: .genericIdentity, source: .requestContent, listener: handleIdentityRequest)
//        registerListener(type: .configuration, source: .requestIdentity, listener: receiveConfigurationIdentity(event:))
//        registerListener(type: .configuration, source: .responseContent, listener: handleConfigurationResponse)
        
        
    }
    
    public func onUnregistered() {}
    
    public func readyForEvent(_ event: Event) -> Bool {
        
//        if event.isSyncEvent || event.type == .genericIdentity {
//            guard let configSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.value else { return false }
//            return state?.readyForSyncIdentifiers(event: event, configurationSharedState: configSharedState) ?? false
//        } else if event.type == .configuration && event.source == .requestIdentity {
//            return MobileIdentities().areSharedStatesReady(event: event, sharedStateProvider: getSharedState(extensionName:event:))
//        }
        
        return getSharedState(extensionName: SignalConstants.Configuration.NAME, event: event)?.status == .set
    }
}
