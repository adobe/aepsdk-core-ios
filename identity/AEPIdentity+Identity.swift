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

extension AEPIdentity: Identity {
    
    static func appendTo(url: URL?, completion: (URL?) -> ()) {
        appendTo(url: url) { (url, _) in
            completion(url)
        }
    }
    
    static func appendTo(url: URL?, completion: (URL?, Error?) -> ()) {
        // TODO: Figure out how to do error callbacks
        // Maybe the response event could hold an error to indicate an error
        
        let event = Event(name: "Append to URL", type: .identity, source: .requestIdentity, data: [IdentityConstants.EventDataKeys.BASE_URL: url?.absoluteURL ?? ""])
        
        EventHub.shared.registerResponseListener(parentExtension: AEPIdentity.self, triggerEvent: event) { (responseEvent) in
            // handle stuff
            let updatedUrlStr = responseEvent.data?[IdentityConstants.EventDataKeys.UPDATED_URL] as? String
            completion(URL(string: updatedUrlStr ?? ""), nil)
        }
        
        AEPCore.dispatch(event: event)
    }
    
    static func getIdentifiers(completion: (String) -> ()) {
        getIdentifiers { (identifiers, _) in
            completion(identifiers)
        }
    }
    
    static func getIdentifiers(completion: (String, Error) -> ()) {
        <#code#>
    }
    
    static func getExperienceCloudId(completion: (String?) -> ()) {
        <#code#>
    }
    
    static func syncIdentifier(identifierType: String, identifier: String, authenticationState: MobileVisitorAuthenticationState) {
        <#code#>
    }
    
    static func syncIdentifiers(identifiers: [String : String]?) {
        <#code#>
    }
    
    static func syncIdentifiers(identifiers: [String : String]?, authenticationState: MobileVisitorAuthenticationState) {
        <#code#>
    }
    
    static func getUrlVariables(completion: (String?) -> ()) {
        getUrlVariables { (variables, _) in
            completion(variables)
        }
    }
    
    static func getUrlVariables(completion: (String?, Error?) -> ()) {
        <#code#>
    }
    
}
