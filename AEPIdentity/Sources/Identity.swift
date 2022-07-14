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

import AEPCore
import AEPServices
import Foundation

@objc(AEPMobileIdentity) public class Identity: NSObject, Extension {
    public let runtime: ExtensionRuntime

    public let name = IdentityConstants.EXTENSION_NAME
    public let friendlyName = IdentityConstants.FRIENDLY_NAME
    public static let extensionVersion = IdentityConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    private(set) var state: IdentityState?

    // MARK: Extension

    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()

        guard let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: "\(name):\(#function)", "Failed to create Data Queue, Identity could not be initialized")
            return
        }

        let hitQueue = PersistentHitQueue(dataQueue: dataQueue, processor: IdentityHitProcessor(responseHandler: handleNetworkResponse(hit:responseData:)))

        let dataStore = NamedCollectionDataStore(name: IdentityConstants.DATASTORE_NAME)
        let pushIdManager = PushIDManager(dataStore: dataStore, eventDispatcher: dispatch(event:))
        state = IdentityState(identityProperties: IdentityProperties(), hitQueue: hitQueue, pushIdManager: pushIdManager)
    }

    public func onRegistered() {
        registerListener(type: EventType.identity, source: EventSource.requestIdentity, listener: handleIdentityRequest)
        registerListener(type: EventType.genericIdentity, source: EventSource.requestContent, listener: handleIdentityRequest)
        registerListener(type: EventType.configuration, source: EventSource.requestIdentity, listener: receiveConfigurationIdentity(event:))
        registerListener(type: EventType.configuration, source: EventSource.responseContent, listener: handleConfigurationResponse)
        registerListener(type: EventType.analytics, source: EventSource.responseIdentity, listener: handleAnalyticsResponseIdentity)
        registerListener(type: EventType.audienceManager, source: EventSource.responseContent, listener: handleAudienceResponse(event:))
        registerListener(type: EventType.genericIdentity, source: EventSource.requestReset, listener: handleRequestReset)

        // fast boot identity without waiting for configuration
        state?.boot(createSharedState: createSharedState(data:event:))
    }

    public func onUnregistered() {
        state?.hitQueue.close()
    }

    public func readyForEvent(_ event: Event) -> Bool {
        guard let state = state else { return false }

        guard state.forceSyncIdentifiers(configSharedState: getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: nil, resolution: .lastSet)?.value, event: event, createSharedState: createSharedState(data:event:)) else { return false }

        // skip waiting for latest configuration if it is getExperienceCloudId event or getIdentifiers event
        if event.isGetIdentifierEvent {
            Log.trace(label: "\(name):\(#function)", "Processing get identifier event without waiting for configuration [event:(\(event.name)) id:(\(event.id)].")
            return true
        } else if event.isSyncEvent || event.type == EventType.genericIdentity {
            guard let configSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, resolution: .lastSet)?.value else {
                Log.trace(label: "\(name):\(#function)", "Waiting for the Configuration shared state value before processing [event:(\(event.name)) id:(\(event.id)].")
                return false
            }
            return state.readyForSyncIdentifiers(event: event, configurationSharedState: configSharedState)
        } else if event.type == EventType.configuration, event.source == EventSource.requestIdentity {
            let areSharedStatesReady = MobileIdentities().areSharedStatesReady(event: event, sharedStateProvider: getSharedState(extensionName:event:))

            if !areSharedStatesReady {
                Log.trace(label: "\(name):\(#function)", "Waiting for the Mobile Identities states to be set before processing [event:(\(event.name)) id:(\(event.id)].")
            }

            return areSharedStatesReady
        } else if event.type == EventType.identity, event.source == EventSource.requestIdentity, ( event.baseUrl != nil ||  event.urlVariables ) {

            // analytics shared state will be null if analytics extension is not registered. Wait for analytics shared only if the status is pending or none
            if let analyticsSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.ANALYTICS, event: event), analyticsSharedState.status != .set {
                Log.trace(label: "\(name):\(#function)", "Waiting for the Analytics shared state to be set before processing [event:(\(event.name)) id:(\(event.id)].")
                return false
            }
        }

        let isConfigSharedStateSet = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, resolution: .lastSet)?.value != nil

        if !isConfigSharedStateSet {
            Log.trace(label: "\(name):\(#function)", "Waiting for the Configuration shared state to be set before processing [event:(\(event.name)) id:(\(event.id)].")
        }

        return isConfigSharedStateSet
    }

    // MARK: Event Listeners

    private func handleIdentityRequest(event: Event) {
        if event.isSyncEvent || event.type == EventType.genericIdentity {
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
        // if config contains org id, update the latest configuration
        if let orgId = event.data?[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String, !orgId.isEmpty {
            // update to new config
            state?.updateLastValidConfig(newConfig: event.data ?? [:])
        }

        if let privacyStatusStr = event.data?[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? String {
            let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown
            if privacyStatus == .optedOut {
                // send opt-out hit
                handleOptOut(event: event)
            }
            // if config contains new global privacy status, process the request
            state?.processPrivacyChange(event: event, createSharedState: createSharedState(data:event:))
        }
    }

    /// Handles the getSdkIdentities API by collecting all the identities then dispatching a response event with the given identities
    /// - Parameter event: The event coming from the getSdkIdentities API
    private func receiveConfigurationIdentity(event: Event) {
        if shouldIgnore(event: event) {
            let responseEvent = event.createResponseEvent(name: IdentityConstants.EventNames.CONFIGURATION_RESPONSE_IDENTITY_EVENT,
                                                          type: EventType.configuration,
                                                          source: EventSource.responseIdentity,
                                                          data: nil)
            dispatch(event: responseEvent)
            Log.debug(label: "\(name):\(#function)", "Ignore Configuration Identity event, user is currently opted-out")
            return
        }

        var mobileIdentities = MobileIdentities()
        mobileIdentities.collectIdentifiers(event: event, sharedStateProvider: getSharedState(extensionName:event:))

        guard let encodedIdentities = try? JSONEncoder().encode(mobileIdentities) else {
            Log.error(label: name, "Failed to encode mobile entities, processing of configuration identity event failed.")
            return
        }

        let identitiesStr = String(data: encodedIdentities, encoding: .utf8)
        let eventData = [IdentityConstants.Configuration.ALL_IDENTIFIERS: identitiesStr]
        let responseEvent = event.createResponseEvent(name: IdentityConstants.EventNames.CONFIGURATION_RESPONSE_IDENTITY_EVENT,
                                                      type: EventType.configuration,
                                                      source: EventSource.responseIdentity,
                                                      data: eventData as [String: Any])
        dispatch(event: responseEvent)
    }
    /// Handles the analytics response event and dispatch an "AVID Sync" event
    /// - Parameter event: the analytics response event
    private func handleAnalyticsResponseIdentity(event: Event) {
        state?.handleAnalyticsResponse(event: event, eventDispatcher: dispatch(event:))
    }

    /// Handles Audience Response Content events containing a flag which signals if the opt-out hit was sent by the Audience Extension.
    /// If the flag is false, the Identity extension will send an opt-out hit to the configured Identity server.
    /// - Parameter event: The event coming from the Audience Manager extension
    private func handleAudienceResponse(event: Event) {
        if event.optOutHitSent {
            Log.debug(label: "\(name):\(#function)", "An opt-out request will not be sent as the  Audience Manager extension has successfully sent it.")
            return
        }
        // Identity Extension will send the opt out request because the Audience Extension did not
        sendOptOutRequest(event: event)
    }

    /// Handles `EventType.genericIdentity` request reset events.
    /// - Parameter event: the identity request reset event
    private func handleRequestReset(event: Event) {
        state?.resetIdentifiers(event: event,
                                createSharedState: createSharedState(data:event:))
    }

    // MARK: Event Handlers

    private func processAppendToUrl(baseUrl: String, event: Event) {
        guard let properties = state?.identityProperties else { return }
        guard let configurationSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, resolution: .lastSet)?.value else { return }

        let analyticsSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.ANALYTICS, event: event)?.value ?? [:]
        let updatedUrl = URLAppender.appendVisitorInfo(baseUrl: baseUrl, configSharedState: configurationSharedState, analyticsSharedState: analyticsSharedState, identityProperties: properties)

        // dispatch identity response event with updated url
        let responseEvent = event.createResponseEvent(name: IdentityConstants.EventNames.IDENTITY_APPENDED_URL,
                                                      type: EventType.identity,
                                                      source: EventSource.responseIdentity,
                                                      data: [IdentityConstants.EventDataKeys.UPDATED_URL: updatedUrl])
        dispatch(event: responseEvent)
    }

    private func processGetUrlVariables(event: Event) {
        guard let properties = state?.identityProperties else { return }
        guard let configurationSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, resolution: .lastSet)?.value else { return }
        let analyticsSharedState = getSharedState(extensionName: "com.adobe.module.analytics", event: event)?.value ?? [:]
        let urlVariables = URLAppender.generateVisitorIdPayload(configSharedState: configurationSharedState, analyticsSharedState: analyticsSharedState, identityProperties: properties)

        // dispatch identity response event with url variables
        let responseEvent = event.createResponseEvent(name: IdentityConstants.EventNames.IDENTITY_URL_VARIABLES,
                                                      type: EventType.identity,
                                                      source: EventSource.responseIdentity,
                                                      data: [IdentityConstants.EventDataKeys.URL_VARIABLES: urlVariables])
        dispatch(event: responseEvent)
    }

    private func processIdentifiersRequest(event: Event) {
        Log.trace(label: "\(name):\(#function)", "Getting  ECID and other synced custom identifiers.")
        let eventData = state?.identityProperties.toEventData()
        let responseEvent = event.createResponseEvent(name: IdentityConstants.EventNames.IDENTITY_RESPONSE_CONTENT_ONE_TIME,
                                                      type: EventType.identity,
                                                      source: EventSource.responseIdentity,
                                                      data: eventData)

        // dispatch identity response event with shared state data
        dispatch(event: responseEvent)
    }

    // MARK: Network Response Handler

    /// Invoked by the `IdentityHitProcessor` each time we receive a network response
    /// - Parameters:
    ///   - entity: The `IdentityHit` that was processed by the hit processor
    ///   - responseData: the network response data if any
    private func handleNetworkResponse(hit: IdentityHit, responseData: Data?) {
        state?.handleHitResponse(hit: hit, response: responseData, eventDispatcher: dispatch(event:), createSharedState: createSharedState(data:event:))
    }

    /// Determines if an opt-out network request should be sent
    /// - Parameter event: the event responsible for sending this opt-out hit
    private func handleOptOut(event: Event) {
        guard let configSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, resolution: .lastSet)?.value else { return }
        // If the AAM server is configured let AAM handle opt out, else we send the opt out hit
        if configSharedState[IdentityConstants.Configuration.AAM_CONFIG_SERVER] != nil { return }
        sendOptOutRequest(event: event)
    }

    /// Sends an opt-out network request if the current privacy status is opt-out
    /// - Parameter event: the event responsible for sending this opt-out hit
    private func sendOptOutRequest(event: Event) {
        guard let configSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, resolution: .lastSet)?.value else { return }
        let privacyStatusStr = configSharedState[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? String ?? ""
        let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown

        if privacyStatus == .optedOut {
            guard let orgId = configSharedState[IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String else { return }
            guard let ecid = state?.identityProperties.ecid else { return }

            var server = configSharedState[IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER] as? String ?? ""
            if server.isEmpty {
                server = IdentityConstants.Default.SERVER
            }

            Log.debug(label: "\(name):\(#function)", "Sending an opt-out request to (\(server)).")
            ServiceProvider.shared.networkService.sendOptOutRequest(orgId: orgId, ecid: ecid, experienceCloudServer: server)
        }
    }

    /// Determines if we should ignore an event
    /// - Parameter event: the event
    /// - Returns: Returns true if we should ignore this event (if user is opted-out)
    private func shouldIgnore(event: Event) -> Bool {
        let configSharedState = getSharedState(extensionName: IdentityConstants.SharedStateKeys.CONFIGURATION, event: event, resolution: .lastSet)?.value
        let privacyStatusStr = configSharedState?[IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? String ?? ""
        let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? PrivacyStatus.unknown

        return privacyStatus == .optedOut
    }
}
