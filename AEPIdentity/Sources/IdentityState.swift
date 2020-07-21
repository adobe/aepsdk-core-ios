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
import AEPEventHub
import AEPServices

/// Manages the business logic of the Identity extension
class IdentityState {
    
    private let LOG_TAG = "IdentityState"
    private(set) var identityProperties: IdentityProperties
    private(set) var hitQueue: HitQueuing
    #if DEBUG
    var lastValidConfig: [String: Any] = [:]
    #else
    private var lastValidConfig: [String: Any] = [:]
    #endif
    
    /// Creates a new `IdentityState` with the given identity properties
    /// - Parameter identityProperties: identity
    init(identityProperties: IdentityProperties, hitQueue: HitQueuing) {
        self.identityProperties = identityProperties
        self.identityProperties.loadFromPersistence()
        self.hitQueue = hitQueue
    }
    
    /// Determines if we have all the required pieces of information, such as configuration to process a sync identifiers call
    /// - Parameters:
    ///   - event: event corresponding to sync identifiers call or containing a new ADID value.
    ///   - configurationSharedState: config shared state corresponding to the event to be processed
    func readyForSyncIdentifiers(event: Event, configurationSharedState: [String: Any]) -> Bool {
        // org id is a requirement.
        // Use what's in current config shared state. if that's missing, check latest config.
        // if latest config doesn't have org id either, Identity can't proceed.
        if let orgId = configurationSharedState[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String, !orgId.isEmpty {
            lastValidConfig = configurationSharedState
        } else if lastValidConfig.isEmpty {
            // can't process this event, wait for a valid config and retry later
            return false
        }
        
        return true
    }
    
    /// Will queue a sync identifiers hit if there are any new valid identifiers to be synced (non null/empty id_type and id values),
    /// Updates the persistence values for the identifiers and ad id
    /// Assumes a valid config is in `lastValidConfig` from calling `readyForSyncIdentifiers`
    /// - Parameters:
    ///   - event: event corresponding to sync identifiers call or containing a new ADID value.
    /// - Returns: The data to be used for Identity shared state
    func syncIdentifiers(event: Event) -> [String: Any]? {
        // sanity check, config should never be empty
        if lastValidConfig.isEmpty {
            // TODO: Add log
            return nil
        }
        
        // Early exit if privacy is opt-out
        if lastValidConfig[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown == .optedOut {
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
        identityProperties.mergeAndCleanCustomerIds(customerIds)
        customerIds.removeAll(where: {$0.identifier?.isEmpty ?? true}) // clean all identifiers by removing all that have a nil or empty identifier
        
        // valid config: check if there's a need to sync. Don't if we're already up to date.
        if shouldSync(customerIds: customerIds, dpids: event.dpids, forceSync: event.forceSync, currentEventValidConfig: lastValidConfig) {
            queueHit(identityProperties: identityProperties, configSharedState: lastValidConfig, event: event)
        } else {
            // TODO: Log error
        }
        
        // save properties
        identityProperties.saveToPersistence()
        
        // return event data to be used in identity shared state
        return identityProperties.toEventData()
    }
    
    /// Invoked by the Identity extension each time we receive a network response for a processed hit
    /// - Parameters:
    ///   - hit: the hit that was processed
    ///   - response: the response data if any
    ///   - eventDispatcher: a function which when invoked dispatches an `Event` to the `EventHub`
    func handleHitResponse(hit: DataEntity, response: Data?, eventDispatcher: (Event) -> ()) {
        // regardless of response, update last sync time
        identityProperties.lastSync = Date()

        // check privacy here in case the status changed while response was in-flight
        if identityProperties.privacyStatus != .optedOut {
            // update properties
            handleNetworkResponse(response: response, eventDispatcher: eventDispatcher)

            // save
            identityProperties.saveToPersistence()
        }

        // dispatch events
        let eventData = identityProperties.toEventData()
        let updatedIdentityEvent = Event(name: "Updated Identity Response", type: .identity, source: .responseIdentity, data: eventData)
        eventDispatcher(updatedIdentityEvent)

        if let data = hit.data, let hit = try? JSONDecoder().decode(IdentityHit.self, from: data) {
            let identityResponse = hit.event.createResponseEvent(name: "Updated Identity Response", type: .identity, source: .responseIdentity, data: eventData)
            eventDispatcher(identityResponse)
        }
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
    private func shouldSync(customerIds: [CustomIdentity]?, dpids: [String: String]?, forceSync: Bool, currentEventValidConfig: [String: Any]) -> Bool {
        var syncForProps = true
        var syncForIds = true
        
        // check config
        if !canSyncForCurrentConfiguration(config: currentEventValidConfig) {
            // TOOD: Add log
            syncForProps = false
        }
        
        let needResync = Date().timeIntervalSince1970 - (identityProperties.lastSync?.timeIntervalSince1970 ?? 0) > identityProperties.ttl || forceSync
        let hasIds = !(customerIds?.isEmpty ?? true)
        let hasDpids = !(dpids?.isEmpty ?? true)
        
        if identityProperties.mid != nil && !hasIds && !hasDpids && !needResync {
            syncForIds = false
        } else if identityProperties.mid == nil {
            identityProperties.mid = MID()
        }
        
        return syncForIds && syncForProps
    }
    
    /// Updates and makes any required actions when the privacy status has updated
    /// - Parameters:
    ///   - event: the event triggering the privacy change
    ///   - eventDispatcher: a function which can dispatch an `Event` to the `EventHub`
    ///   - createSharedState: a function which can create Identity shared state
    func processPrivacyChange(event: Event, eventDispatcher: (Event) -> (), createSharedState: ([String: Any], Event) -> ()) {
        let newPrivacyStatus = event.data?[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? PrivacyStatus.unknown

        if newPrivacyStatus == identityProperties.privacyStatus {
            return
        }

        identityProperties.privacyStatus = newPrivacyStatus

        if newPrivacyStatus == .optedOut {
            identityProperties.mid = nil
            identityProperties.advertisingIdentifier = nil
            identityProperties.blob = nil
            identityProperties.locationHint = nil
            identityProperties.customerIds?.removeAll()

            // TODO: Clear AID from analytics
            
            // TODO: Update push ID AMSDK-10262
            identityProperties.saveToPersistence()
            createSharedState(identityProperties.toEventData(), event)
            // make sure we ignore events if we are opted out
            
        } else if identityProperties.mid == nil {
            // When changing privacy status from optedout, need to generate a new Experience Cloud ID for the user
            // Queue up a request to sync the new ID with the Identity Service
            let forceSyncEvent = event.forceSyncEvent()
            eventDispatcher(forceSyncEvent)
        }

        // update hit queue with privacy status
        hitQueue.handlePrivacyChange(status: newPrivacyStatus)
    }
    
    /// Updates the last valid config to `newConfig`
    /// - Parameter newConfig: The new configuration to replace the current last valid config
    func updateLastValidConfig(newConfig: [String: Any]) {
        lastValidConfig = newConfig
    }
    
    // MARK: Private APIs
    
    /// Inspects the current configuration to determine if a sync can be made, this is determined by if a valid org id is present and if the privacy is not set to opted-out
    /// - Parameter config: The current configuration
    /// - Returns: True if a sync can be made with the current configuration, false otherwise
    private func canSyncForCurrentConfiguration(config: [String: Any]) -> Bool {
        let orgId = config[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String ?? ""
        let privacyStatus = config[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown
        return !orgId.isEmpty && privacyStatus != .optedOut
    }
    
    /// Determines if we should update the ad id with `newAdID`
    /// - Parameter newAdID: the new ad id
    /// - Returns: True if we should update the ad id, false otherwise
    private func shouldUpdateAdId(newAdID: String) -> Bool {
        let existingAdId = identityProperties.advertisingIdentifier ?? ""
        return (!newAdID.isEmpty && newAdID != existingAdId) || (newAdID.isEmpty && !existingAdId.isEmpty)
    }
    
    /// Queues an Identity hit within the `hitQueue`
    /// - Parameters:
    ///   - identityProperties: Current identity properties
    ///   - configSharedState: Current configuration shared state
    ///   - event: event responsible for the hit
    private func queueHit(identityProperties: IdentityProperties, configSharedState: [String: Any], event: Event) {
        let server = configSharedState[IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER] as? String ?? IdentityConstants.Default.SERVER

        guard let orgId = configSharedState[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String else {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Dropping Identity hit, orgId is not present")
            return
        }

        guard let url = URL.buildIdentityHitURL(experienceCloudServer: server, orgId: orgId, identityProperties: identityProperties, dpids: event.dpids ?? [:]) else {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Dropping Identity hit, failed to create hit URL")
            return
        }

        guard let hitData = try? JSONEncoder().encode(IdentityHit(url: url, event: event)) else {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Dropping Identity hit, failed to encode IdentityHit")
            return
        }

        hitQueue.queue(entity: DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: hitData))
    }

    /// Parses the network response from an identity hit
    /// - Parameters:
    ///   - response: the network response
    ///   - eventDispatcher: a function which when invoked dispatches an `Event` to the `EventHub`
    private func handleNetworkResponse(response: Data?, eventDispatcher: (Event) -> ()) {
        guard let data = response, let identityResponse = try? JSONDecoder().decode(IdentityHitResponse.self, from: data) else {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Failed to decode Identity hit response")
            return
        }

        if let optOutList = identityResponse.optOutList, !optOutList.isEmpty {
            // Received opt-out response from ECID Service, so updating the privacy status in the configuration to opt-out.
            let updateConfig = [IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut]
            let event = Event(name: "Configuration Update From IdentityExtension", type: .configuration, source: .requestContent, data: [IdentityConstants.Configuration.UPDATE_CONFIG: updateConfig])
            eventDispatcher(event)
        }

        //something's wrong - n/w call returned an error. update the pending state.
        if let error = identityResponse.error {
            //should never happen bc we generate mid locally before n/w request.
            // Still, generate mid locally if there's none yet.
            identityProperties.mid = identityProperties.mid ?? MID()
            Log.error(label: "\(LOG_TAG):\(#function)", "Identity response returned error: \(error)")
            return
        }

        if let mid = identityResponse.mid, !mid.isEmpty {
            identityProperties.blob = identityResponse.blob
            identityProperties.locationHint = identityResponse.hint
            identityProperties.ttl = identityResponse.ttl ?? IdentityConstants.Default.TTL
        }

    }
}
