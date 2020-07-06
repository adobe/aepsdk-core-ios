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

/// Manages the business logic of the Identity extension
struct IdentityState {
    
    private var identityProperties: IdentityProperties
    private var lastValidConfig: [String: Any]?
    private var db = AEPServiceProvider.shared.dataQueueService.getDataQueue(label: IdentityConstants.EXTENSION_NAME)
    
    mutating func syncIdentifiers(event: Event, configurationSharedState: [String: Any]) -> [String: Any]? {
        var currentEventValidConfig = [String: Any]()
        let privacyStatus = configurationSharedState[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown
        // do not even extract any data if the config is opt-out.
        guard privacyStatus != .optedOut else { return nil }
        
        // org id is a requirement.
        // Use what's in current config shared state. if that's missing, check latest config.
        // if latest config doesn't have org id either, Identity can't proceed.
        if let orgId = configurationSharedState[ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID] as? String, !orgId.isEmpty {
            lastValidConfig = configurationSharedState
        } else {
            if let lastValidConfig = lastValidConfig {
                currentEventValidConfig = lastValidConfig
            } else {
                // can't process this event.
                return nil
            }
        }
        
        // Check privacy status again from the valid config object, return if opt-out
        if currentEventValidConfig[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown == .optedOut {
            // did process this event but can't sync the call.
            return nil
        }

        // TODO: Save push ID
        
        let authState = event.authenticationState
        
        // generate customer ids
        var customerIds = event.identifiers?.map({CustomIdentity(origin: IdentityConstants.VISITOR_ID_PARAMETER_KEY_CUSTOMER, type: $0.key, identifier: $0.value, authenticationState: authState)})
        
        // read and update adid
        if let adId = event.adId {
            // check if changed, update
        }
        
        
        // merge new identifiers with the existing ones and remove any VisitorIds with empty id values
        // empty adid is also removed from the customer_ids_ list by merging with the new ids then filtering out any empty ids
        identityProperties.customerIds = toIdDict(ids: identityProperties.customerIds).merging(toIdDict(ids: customerIds), uniquingKeysWith: { (_, new) in new }).map {$0.value}
        identityProperties.customerIds?.removeAll(where: {$0.identifier?.isEmpty ?? true}) // clean all identifiers by removing all that have a nil or empty identifier
        customerIds?.removeAll(where: {$0.identifier?.isEmpty ?? true}) // clean all identifiers by removing all that have a nil or empty identifier
        
        // valid config: check if there's a need to sync. Don't if we're already up to date.
        if shouldSync() {
            let hitUrl = URL.buildIdentityHitURL(experienceCloudServer: "", orgId: "", identityProperties: identityProperties, dpids: event.dpids ?? [:])
            // TODO: queue in DB
        } else {
            // TODO: Log error
        }
        
        // save properties
        // extension should share state after with identity properties to event data
        return identityProperties.toEventData()
    }
    
    private func shouldSync() -> Bool {
        return false
    }
    
    /// Returns a dict where the key is the `identifier` of the identity and the value is the `CustomIdentity`
    /// - Parameter ids: a list of identities
    func toIdDict(ids: [CustomIdentity]?) -> [String?: CustomIdentity] {
        guard let ids = ids else { return [:] }
        return Dictionary(uniqueKeysWithValues: ids.map{ ($0.identifier, $0) })
    }
}
