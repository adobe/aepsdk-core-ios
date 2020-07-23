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

class AEPIdentity: Extension {
    let runtime: ExtensionRuntime

    let name = IdentityConstants.EXTENSION_NAME
    let friendlyName = IdentityConstants.FRIENDLY_NAME
    let version = IdentityConstants.EXTENSION_VERSION
    let metadata: [String: String]? = nil
    private(set) var state: IdentityState?
    
    // MARK: Extension
    required init(runtime: ExtensionRuntime) {
        self.runtime = runtime

        guard let dataQueue = AEPServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: "\(name):\(#function)", "Failed to create Data Queue, Identity could not be initialized")
            return
        }

        let hitQueue = PersistentHitQueue(dataQueue: dataQueue, processor: IdentityHitProcessor(responseHandler: handleNetworkResponse(entity:responseData:)))
        let dataStore = NamedKeyValueStore(name: IdentityConstants.DATASTORE_NAME)
        let pushIdManager = PushIDManager(dataStore: dataStore, eventDispatcher: dispatch(event:))
        state = IdentityState(identityProperties: IdentityProperties(), hitQueue: hitQueue, pushIdManager: pushIdManager)
    }

    func onRegistered() {
        registerListener(type: .identity, source: .requestIdentity, listener: handleIdentityRequest)
        registerListener(type: .genericIdentity, source: .requestContent, listener: handleIdentityRequest)
        registerListener(type: .configuration, source: .requestIdentity, listener: receiveConfigurationIdentity(event:))
        registerListener(type: .configuration, source: .responseContent, listener: handleConfigurationResponse)
    }

    func onUnregistered() {}

    func readyForEvent(_ event: Event) -> Bool {
        if event.isSyncEvent || event.type == .genericIdentity {
            guard let configSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.value else { return false }
            return state?.readyForSyncIdentifiers(event: event, configurationSharedState: configSharedState) ?? false
        } else if event.type == .configuration && event.source == .requestIdentity {
            return MobileIdentities().areSharedStatesReady(event: event, sharedStateProvider: getSharedState(extensionName:event:))
        }

        return getSharedState(extensionName:  IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.status == .set
    }

    // MARK: Event Listeners

    private func handleIdentityRequest(event: Event) {
        if shouldIgnore(event: event) {
            Log.debug(label: "\(name):\(#function)", "Ignore Identity Request event, user is currently opted-out")
            return
        }
        
        if event.isSyncEvent || event.type == .genericIdentity {
            if let eventData = state?.syncIdentifiers(event: event) {
                createSharedState(data: eventData, event: event)
            }
        } else if let baseUrl = event.baseUrl {
            processAppendToUrl(baseUrl: baseUrl, event: event)
        } else if event.urlVariables {
            processGetUrlVariables(event: event)
        } else {
            processIdentifiersRequest(event: event)
        }
    }
    
    /// Handles the configuration response event
    /// - Parameter event: the configuration response event
    private func handleConfigurationResponse(event: Event) {
        if let privacyStatus = event.data?[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus {
            if privacyStatus == .optedOut {
                // send opt-out hit
                handleOptOut(event: event)
            }
            // if config contains new global privacy status, process the request
            state?.processPrivacyChange(event: event, eventDispatcher: dispatch(event:), createSharedState: createSharedState(data:event:))
        }

        // if config contains org id, update the latest configuration
        if let orgId = event.data?[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String, !orgId.isEmpty {
            // update to new config
            state?.updateLastValidConfig(newConfig: event.data ?? [:])
        }
    }

    /// Handles the getSdkIdentities API by collecting all the identities then dispatching a response event with the given identities
    /// - Parameter event: The event coming from the getSdkIdentities API
    private func receiveConfigurationIdentity(event: Event) {
        if shouldIgnore(event: event) {
            Log.debug(label: "\(name):\(#function)", "Ignore Configuration Identity event, user is currently opted-out")
            return
        }
        
        var mobileIdentities = MobileIdentities()
        mobileIdentities.collectIdentifiers(event: event, sharedStateProvider: getSharedState(extensionName:event:))

        guard let encodedIdentities = try? JSONEncoder().encode(mobileIdentities) else {
            // TODO: Error log
            return
        }

        let identitiesStr = String(data: encodedIdentities, encoding: .utf8)
        let eventData = [IdentityConstants.Configuration.ALL_IDENTIFIERS: identitiesStr]
        let responseEvent = event.createResponseEvent(name: "Configuration Response Identity Event", type: .configuration, source: .responseIdentity, data: eventData as [String : Any])
        dispatch(event: responseEvent)
    }

    // MARK: Event Handlers
    private func processAppendToUrl(baseUrl: String, event: Event) {
        guard let properties = state?.identityProperties else { return }
        guard let configurationSharedState = getSharedState(extensionName:  IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.value else { return }
        let analyticsSharedState = getSharedState(extensionName: "com.adobe.module.analytics", event: event)?.value ?? [:]
        let updatedUrl = URLAppender.appendVisitorInfo(baseUrl: baseUrl, configSharedState: configurationSharedState, analyticsSharedState: analyticsSharedState, identityProperties: properties)

        // dispatch identity response event with updated url
        let responseEvent = event.createResponseEvent(name: "Identity Appended URL", type: .identity, source: .responseIdentity, data: [IdentityConstants.EventDataKeys.UPDATED_URL: updatedUrl])
        dispatch(event: responseEvent)
    }

    private func processGetUrlVariables(event: Event) {
        guard let properties = state?.identityProperties else { return }
        guard let configurationSharedState = getSharedState(extensionName:  IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.value else { return }
        let analyticsSharedState = getSharedState(extensionName: "com.adobe.module.analytics", event: event)?.value ?? [:]
        let urlVariables = URLAppender.generateVisitorIdPayload(configSharedState: configurationSharedState, analyticsSharedState: analyticsSharedState, identityProperties: properties)

        // dispatch identity response event with url variables
        let responseEvent = event.createResponseEvent(name: "Identity URL Variables", type: .identity, source: .responseIdentity, data: [IdentityConstants.EventDataKeys.URL_VARIABLES: urlVariables])
        dispatch(event: responseEvent)
    }

    private func processIdentifiersRequest(event: Event) {
        let eventData = state?.identityProperties.toEventData()
        let responseEvent = event.createResponseEvent(name: "Identity Response Content", type: .identity, source: .responseIdentity, data: eventData)

        // dispatch identity response event with shared state data
        dispatch(event: responseEvent)
    }

    // MARK: Network Response Handler
    /// Invoked by the `IdentityHitProcessor` each time we receive a network response
    /// - Parameters:
    ///   - entity: The `DataEntity` that was processed by the hit processor
    ///   - responseData: the network response data if any
    private func handleNetworkResponse(entity: DataEntity, responseData: Data?) {
        state?.handleHitResponse(hit: entity, response: responseData, eventDispatcher: dispatch(event:))
    }
    
    /// Sends an opt-out network request if the current privacy status is opt-out
    /// - Parameter event: the event responsible for sending this opt-out hit
    private func handleOptOut(event: Event) {
        // TODO: AMSDK-10267 Check if AAM will handle the opt-out hit
        guard let configSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.value else { return }
        let privacyStatus = configSharedState[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? PrivacyStatus.unknown

        if privacyStatus == .optedOut {
            guard let orgId = configSharedState[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String else { return }
            guard let mid = state?.identityProperties.mid else { return }
            let server = configSharedState[IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER] as? String ?? IdentityConstants.DEFAULT_SERVER
            AEPServiceProvider.shared.networkService.sendOptOutRequest(orgId: orgId, mid: mid, experienceCloudServer: server)
        }
    }
    
    /// Determines if we should ignore an event
    /// - Parameter event: the event
    /// - Returns: Returns true if we should ignore this event (if user is opted-out)
    private func shouldIgnore(event: Event) -> Bool {
        let privacyStatus = getSharedState(extensionName:  IdentityConstants.SharedStateKeys.CONFIGURATION, event: event)?.value?[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus ?? .unknown
        return privacyStatus == .optedOut
    }
    
}
