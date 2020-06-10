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
    
    static func appendTo(url: URL?, completion: @escaping (URL?) -> ()) {
        appendTo(url: url) { (url, _) in
            completion(url)
        }
    }
    
    static func appendTo(url: URL?, completion: @escaping (URL?, Error?) -> ()) {
        let data = [IdentityConstants.EventDataKeys.BASE_URL: url?.absoluteString ?? ""]
        let event = Event(name: "Append to URL", type: .identity, source: .requestIdentity, data: data)
        
        EventHub.shared.registerResponseListener(parentExtension: AEPIdentity.self, triggerEvent: event) { (responseEvent) in
            // TODO: AMSDK-10182 Handle error
            let updatedUrlStr = responseEvent.data?[IdentityConstants.EventDataKeys.UPDATED_URL] as? String
            completion(URL(string: updatedUrlStr ?? ""), nil)
        }
        
        AEPCore.dispatch(event: event)
    }
    
    static func getIdentifiers(completion: @escaping ([MobileVisitorId]?) -> ()) {
        getIdentifiers { (identifiers, _) in
            completion(identifiers)
        }
    }
    
    static func getIdentifiers(completion: @escaping ([MobileVisitorId]?, Error?) -> ()) {
        let event = Event(name: "Get Identifiers", type: .identity, source: .requestIdentity, data: nil)
        
        EventHub.shared.registerResponseListener(parentExtension: AEPIdentity.self, triggerEvent: event) { (responseEvent) in
            let identifiers = responseEvent.data?[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [MobileVisitorId]
            // TODO: AMSDK-10182 Handle error
            completion(identifiers, nil)
        }
        
        AEPCore.dispatch(event: event)
    }
    
    static func getExperienceCloudId(completion: @escaping (String?) -> ()) {
        let event = Event(name: "Get experience cloud ID", type: .identity, source: .requestIdentity, data: nil)
        
        EventHub.shared.registerResponseListener(parentExtension: AEPIdentity.self, triggerEvent: event) { (responseEvent) in
            let experienceCloudId = responseEvent.data?[IdentityConstants.EventDataKeys.VISITOR_ID_MID] as? String
            completion(experienceCloudId)
        }
        
        AEPCore.dispatch(event: event)
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
        AEPCore.dispatch(event: event)
    }
    
    static func getUrlVariables(completion: @escaping (String?) -> ()) {
        getUrlVariables { (variables, _) in
            completion(variables)
        }
    }
    
    static func getUrlVariables(completion: @escaping (String?, Error?) -> ()) {
        let event = Event(name: "Get URL variables", type: .identity, source: .requestIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: true])
        
        EventHub.shared.registerResponseListener(parentExtension: AEPIdentity.self, triggerEvent: event) { (responseEvent) in
            let urlVariables = responseEvent.data?[IdentityConstants.EventDataKeys.URL_VARIABLES] as? String
            // TODO: AMSDK-10182 Handle error
            completion(urlVariables, nil)
        }
        
        AEPCore.dispatch(event: event)
    }
    
}
