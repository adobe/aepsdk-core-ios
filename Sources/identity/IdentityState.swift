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
    private var lastValidConfig: [String: Any]? = nil
    
    /// Creates a new `IdentityState` with the given identity properties
    /// - Parameter identityProperties: <#identityProperties description#>
    init(identityProperties: IdentityProperties) {
        self.identityProperties = identityProperties
        self.identityProperties.load()
    }
    
    /// WIll queue a sync identifiers hit if there are any new valid identifiers to be synced (non null/empty id_type and id values),
    /// Updates the persistence values for the identifiers and ad id
    /// - Parameters:
    ///   - event: event corresponding to sync identifiers call or containing a new ADID value.
    ///   - configurationSharedState: config shared state corresponding to the event to be processed
    /// - Returns: The data to be used for Identity shared state
    mutating func syncIdentifiers(event: Event, configurationSharedState: [String: Any]) -> [String: Any]? {
        var currentEventValidConfig = [String: Any]()
        let privacyStatus = configurationSharedState[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown
        // do not even extract any data if the config is opt-out.
        guard privacyStatus != .optedOut else {
            // TODO: Add log
            return nil
        }
        
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
        guard currentEventValidConfig[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown != .optedOut else {
            // did process this event but can't sync the call.
            // TODO: Add log
            return nil
        }

        // TODO: Save push ID AMSDK-10262
        
        // generate customer ids
        let authState = event.authenticationState
        var customerIds = event.identifiers?.map({CustomIdentity(origin: IdentityConstants.VISITOR_ID_PARAMETER_KEY_CUSTOMER, type: $0.key, identifier: $0.value, authenticationState: authState)}) ?? []
        
        // update adid if changed and extract the new adid value as VisitorId to be synced
        if let adId = event.adId, shouldUpdateAdId(newAdID: adId.identifier ?? "") {
            // check if changed, update
            identityProperties.advertisingIdentifier = adId.identifier
            customerIds.append(adId)
        }
        
        // merge new identifiers with the existing ones and remove any VisitorIds with empty id values
        // empty adid is also removed from the customer_ids_ list by merging with the new ids then filtering out any empty ids
        
        // convert array of IDs to a dict of <identifier, ID>, then merge by taking the new ID for duplicate IDs
        identityProperties.customerIds = toIdDict(ids: identityProperties.customerIds).merging(toIdDict(ids: customerIds), uniquingKeysWith: { (_, new) in new }).map {$0.value}
        identityProperties.customerIds?.removeAll(where: {$0.identifier?.isEmpty ?? true}) // clean all identifiers by removing all that have a nil or empty identifier
        customerIds.removeAll(where: {$0.identifier?.isEmpty ?? true}) // clean all identifiers by removing all that have a nil or empty identifier
        
        // valid config: check if there's a need to sync. Don't if we're already up to date.
        if shouldSync(customerIds: customerIds, dpids: event.dpids, forceSync: event.forceSync, currentEventValidConfig: currentEventValidConfig) {
            // TODO: AMSDK-10261 queue in DB
            let _ = URL.buildIdentityHitURL(experienceCloudServer: "TODO", orgId: "TODO", identityProperties: identityProperties, dpids: event.dpids ?? [:])
        } else {
            // TODO: Log error
        }
        
        // save properties
        identityProperties.save()
        return identityProperties.toEventData()
    }
    
    /// Verifies if a sync network call is required. This method returns true if there is at least one identifier to be synced,
    /// at least one dpid, if force sync is true (bootup identity sync call) or if the
    /// last sync was more than `ttl_` seconds ago. Also, in order for a sync call to happen, the provided configuration should be
    /// valid: org id is valid and privacy status is opted in.
    /// - Parameters:
    ///   - customerIds: current customer ids that need to be synced
    ///   - dpids: current dpids that need to be synced
    ///   - forceSync: indicates if this is a force sync call
    ///   - currentEventValidConfig: the current configuration for the event
    /// - Returns: True if a sync should be made, false otherwise
    private mutating func shouldSync(customerIds: [CustomIdentity]?, dpids: [String: String]?, forceSync: Bool, currentEventValidConfig: [String: Any]) -> Bool {
        var syncForProps = true
        var syncForIds = true
        
        // check config
        if !canSyncForCurrentConfiguration(config: currentEventValidConfig) {
            // TOOD: Add log
            syncForProps = false
        }
        
        let needResync = Date().timeIntervalSince1970 - (identityProperties.lastSync?.timeIntervalSince1970 ?? 0) > identityProperties.ttl || forceSync
        let hasIds = !(customerIds?.isEmpty ?? false)
        let hasDpids = !(dpids?.isEmpty ?? false)
        
        if identityProperties.mid != nil && !hasIds && !hasDpids && !needResync {
            syncForIds = false
        } else if identityProperties.mid == nil {
            identityProperties.mid = MID()
        }
        
        return syncForIds && syncForProps
    }
    
    /// Inspects the current configuration to determine if a sync can be made, this is determined by if a valid org id is present and if the privacy is not set to opted-out
    /// - Parameter config: The current configuration
    /// - Returns: True if a sync can be made with the current configuration, false otherwise
    private func canSyncForCurrentConfiguration(config: [String: Any]) -> Bool {
        let orgId = config[ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID] as? String ?? ""
        let privacyStatus = config[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown
        return !orgId.isEmpty && privacyStatus != .optedOut
    }
    
    /// Determines if we should update the ad id with `newAdID`
    /// - Parameter newAdID: the new ad id
    /// - Returns: True if we should update the ad id, false otherwise
    private func shouldUpdateAdId(newAdID: String) -> Bool {
        if let existingAdId = identityProperties.advertisingIdentifier {
            return (!newAdID.isEmpty && existingAdId != newAdID) || (newAdID.isEmpty && !existingAdId.isEmpty)
        }
        // existing adId is empty or nil, so update as long as the new adId is not empty
        return !newAdID.isEmpty
    }
    
    /// Returns a dict where the key is the `identifier` of the identity and the value is the `CustomIdentity`
    /// - Parameter ids: a list of identities
    private func toIdDict(ids: [CustomIdentity]?) -> [String?: CustomIdentity] {
        guard let ids = ids else { return [:] }
        return Dictionary(uniqueKeysWithValues: ids.map{ ($0.identifier, $0) })
    }
}
