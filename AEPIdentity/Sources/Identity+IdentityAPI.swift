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

extension Identity: IdentityAPI {
    
    static func appendTo(url: URL?, completion: @escaping (URL?, AEPError?) -> ()) {
        let data = [IdentityConstants.EventDataKeys.BASE_URL: url?.absoluteString ?? ""]
        let event = Event(name: "Append to URL", type: .identity, source: .requestIdentity, data: data)
        
        MobileCore.dispatch(event: event) { (responseEvent) in
            guard let responseEvent = responseEvent else {
                completion(nil, .callbackTimeout)
                return
            }
            
            guard let updatedUrlStr = responseEvent.data?[IdentityConstants.EventDataKeys.UPDATED_URL] as? String else {
                completion(nil, .unexpected)
                return
            }
            
            completion(URL(string: updatedUrlStr), nil)
        }
    }
    
    static func getIdentifiers(completion: @escaping ([Identifiable]?, AEPError?) -> ()) {
        let event = Event(name: "Get Identifiers", type: .identity, source: .requestIdentity, data: nil)
        
        MobileCore.dispatch(event: event) { (responseEvent) in
            guard let responseEvent = responseEvent else {
                completion(nil, .callbackTimeout)
                return
            }
            
            guard let identifiers = responseEvent.data?[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [Identifiable] else {
                completion(nil, .unexpected)
                return
            }
            
            completion(identifiers, nil)
        }
    }
    
    static func getExperienceCloudId(completion: @escaping (String?) -> ()) {
        let event = Event(name: "Get experience cloud ID", type: .identity, source: .requestIdentity, data: nil)
        
        MobileCore.dispatch(event: event) { (responseEvent) in
            let experienceCloudId = responseEvent?.data?[IdentityConstants.EventDataKeys.VISITOR_ID_MID] as? String
            completion(experienceCloudId)
        }
    }
    
    static func syncIdentifier(identifierType: String, identifier: String, authenticationState: MobileVisitorAuthenticationState) {
        syncIdentifiers(identifiers: [identifierType: identifier], authenticationState: authenticationState)
    }
    
    static func syncIdentifiers(identifiers: [String : String]?) {
        syncIdentifiers(identifiers: identifiers, authenticationState: .unknown)
    }
    
    static func syncIdentifiers(identifiers: [String : String]?, authenticationState: MobileVisitorAuthenticationState) {
        var eventData = [String: Any]()
        eventData[IdentityConstants.EventDataKeys.IDENTIFIERS] = identifiers
        eventData[IdentityConstants.EventDataKeys.AUTHENTICATION_STATE] = authenticationState
        eventData[IdentityConstants.EventDataKeys.FORCE_SYNC] = false
        eventData[IdentityConstants.EventDataKeys.IS_SYNC_EVENT] = true
        
        let event = Event(name: "ID Sync", type: .identity, source: .requestIdentity, data: eventData)
        MobileCore.dispatch(event: event)
    }
    
    static func getUrlVariables(completion: @escaping (String?, AEPError?) -> ()) {
        let event = Event(name: "Get URL variables", type: .identity, source: .requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])
        
         MobileCore.dispatch(event: event) { (responseEvent) in
            guard let responseEvent = responseEvent else {
                completion(nil, .callbackTimeout)
                return
            }
            
            let urlVariables = responseEvent.data?[IdentityConstants.EventDataKeys.URL_VARIABLES] as? String
            completion(urlVariables, nil)
        }
    }
    
}
