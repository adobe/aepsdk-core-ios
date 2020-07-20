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
    let version = IdentityConstants.EXTENSION_VERSION
    var state: IdentityState?
    
    // MARK: Extension
    required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        
        guard let dataQueue = AEPServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: "\(name):\(#function)", "Failed to create Data Queue, Identity could not be initialized")
            return
        }

        let hitQueue = PersistentHitQueue(dataQueue: dataQueue, processor: IdentityHitProcessor(responseHandler: handleNetworkResponse(entity:responseData:)))
        state = IdentityState(identityProperties: IdentityProperties(), hitQueue: hitQueue)
    }
    
    func onRegistered() {
        registerListener(type: .identity, source: .requestIdentity, listener: handleIdentityRequest)
        registerListener(type: .configuration, source: .requestIdentity, listener: receiveConfigurationIdentity(event:))
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
    
    /// Handles the getSdkIdentities API by collecting all the identities then dispatching a response event with the given identities
    /// - Parameter event: The event coming from the getSdkIdentities API
    private func receiveConfigurationIdentity(event: Event) {
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
}
