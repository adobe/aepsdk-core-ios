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

/// Responsible for retrieving the configuration of the SDK and updating the shared state and dispatching configuration updates through the `EventHub`
class AEPConfiguration: Extension {
    var name = ConfigurationConstants.EXTENSION_NAME
    var version = ConfigurationConstants.EXTENSION_VERSION

    private let eventQueue = OperationOrderer<EventHandlerMapping>(ConfigurationConstants.EXTENSION_NAME)
    private let dataStore = NamedKeyValueStore(name: ConfigurationConstants.DATA_STORE_NAME)
    private var appIdManager: LaunchIDManager
    private var configState: ConfigurationState // should only be modified/used within the event queue
    
    // MARK: Extension
    required init() {
        eventQueue.setHandler({ return $0.handler($0.event) })
        appIdManager = LaunchIDManager(dataStore: dataStore)
        configState = ConfigurationState(dataStore: dataStore, configDownloader: ConfigurationDownloader())
    }

    func onRegistered() {
        registerListener(type: .configuration, source: .requestContent, listener: receiveConfigurationRequest(event:))
        registerListener(type: .lifecycle, source: .responseContent, listener: receiveLifecycleResponse(event:))
        // TODO: AMSDK-9750 - Listen for request identifier events
        bootup()
        eventQueue.start()
    }

    func onUnregistered() {}

    // MARK: Event Listeners
    
    /// Invoked by the `eventQueue` each time a new configuration request event is received
    /// - Parameter event: A configuration request event
    private func receiveConfigurationRequest(event: Event) {
        eventQueue.add((event, handleConfigurationRequest(event:)))
    }
    
    /// Invoked by the `eventQueue` each time a new lifecycle response event is received
    /// - Parameter event: A lifecycle response event
    private func receiveLifecycleResponse(event: Event) {
        eventQueue.add((event, handleLifecycle(event:)))
    }

    // MARK: Event Handlers
    
    /// Handles  the configuration request event and determines which business logic should be invoked
    /// - Parameter event: A configuration request event
    private func handleConfigurationRequest(event: Event) -> Bool {
        guard let eventData = event.data else { return true }

        if eventData[ConfigurationConstants.Keys.UPDATE_CONFIG] != nil {
            return processUpdateConfig(event: event, sharedStateResolver: createPendingSharedState(event: event))
        } else if eventData[ConfigurationConstants.Keys.RETRIEVE_CONFIG] as? Bool ?? false {
            dispatchConfigurationResponse(triggerEvent: event, data: configState.currentConfiguration)
            return true
        } else if let appId = eventData[ConfigurationConstants.Keys.JSON_APP_ID] as? String {
            return processConfigureWith(appId: appId, event: event, sharedStateResolver: createPendingSharedState(event: event))
        } else if let filePath = eventData[ConfigurationConstants.Keys.JSON_FILE_PATH] as? String {
            return processConfigureWith(filePath: filePath, event: event, sharedStateResolver: createPendingSharedState(event: event))
        }

        return true
    }
    
    /// Handles the Lifecycle response event and dispatches a configuration request event if we have an appId in persistence
    /// - Parameter event: The lifecycle response event
    private func handleLifecycle(event: Event) -> Bool {
        // Re-fetch the latest config if appId is present.
        // Lifecycle does not load bundled/manual configuration if appId is absent.
        guard let appId = appIdManager.loadAppId(), !appId.isEmpty else {
            return true
        }

        // Dispatch an event with appId to start remote download
        let data: [String: Any] = [ConfigurationConstants.Keys.JSON_APP_ID: appId,
                                   ConfigurationConstants.Keys.IS_INTERNAL_EVENT: true]
        dispatchConfigurationRequest(data: data)
        return true
    }

    // MARK: Event Processors
    
    /// Interacts with the `ConfigurationState` to update the configuration with the new configuration contained in `event`
    /// - Parameters:
    ///   - event: The `event` which contains the new configuration
    ///   - sharedStateResolver: Shared state resolver that will be invoked with the new configuration
    private func processUpdateConfig(event: Event, sharedStateResolver: SharedStateResolver) -> Bool {
        // Update the overriddenConfig with the new config from API and persist them in disk, and abort if overridden config is empty
        guard let updatedConfig = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: Any], !updatedConfig.isEmpty else {
            // error, resolve pending shared state with current config
            sharedStateResolver(configState.currentConfiguration)
            return true
        }
        
        configState.updateWith(programmaticConfig: updatedConfig)
        // Create shared state and dispatch configuration response content
        sharedStateResolver(configState.currentConfiguration)
        dispatchConfigurationResponse(triggerEvent: event, data: event.data)
        return true
    }
    
    /// Interacts with the `ConfigurationState` to download the configuration associated with `appId`
    /// - Parameters:
    ///   - appId: The appId for which a configuration should be downloaded from
    ///   - event: The event responsible for the API call
    ///   - sharedStateResolver: Shared state resolver that will be invoked with the new configuration
    private func processConfigureWith(appId: String, event: Event, sharedStateResolver: @escaping SharedStateResolver) -> Bool {
        guard let appId = event.data?[ConfigurationConstants.Keys.JSON_APP_ID] as? String, !appId.isEmpty else {
            // Error: No appId provided or its empty, resolve pending shared state with current config
            sharedStateResolver(configState.currentConfiguration)
            return true
        }

        guard validateForInternalEventAppIdChange(event: event, newAppId: appId) else {
            // error: app Id update already in-flight, resolve pending shared state with current config
            sharedStateResolver(configState.currentConfiguration)
            return true
        }
        
        // stop all other event processing while we are attempting to download the config
        eventQueue.stop()
        configState.updateWith(appId: appId) { [weak self] (config) in
            if let _ = config {
                self?.publishCurrentConfig(event: event, sharedStateResolver: sharedStateResolver)
                self?.eventQueue.removeFirst() // remove this event from the queue if downloading successful
                self?.eventQueue.start()
            } else {
                // If downloading config failed try again later
                self?.eventQueue.start(after: 0.5) // retry config after 0.5 seconds
            }
        }
        
        // always return false to pause the queue while the configuration is being downloaded
        return false
    }
    
    /// Interacts with the `ConfigurationState` to fetch the configuration associated with `filePath`
    /// - Parameters:
    ///   - filePath: The file path at which the configuration should be loaded from
    ///   - event: The event responsible for the API call
    ///   - sharedStateResolver: Shared state resolver that will be invoked with the new configuration
    private func processConfigureWith(filePath: String, event: Event, sharedStateResolver: SharedStateResolver) -> Bool {
        guard let filePath = event.data?[ConfigurationConstants.Keys.JSON_FILE_PATH] as? String, !filePath.isEmpty else {
            // Error: Shared state is updated with previous config
            sharedStateResolver(configState.currentConfiguration)
            return true
        }

        if configState.updateWith(filePath: filePath) {
            publishCurrentConfig(event: event, sharedStateResolver: sharedStateResolver)
        } else {
            // loading from bundled config failed, resolve shared state with current config without dispatching a config response event
            sharedStateResolver(configState.currentConfiguration)
        }

        return true
    }

    // MARK: Dispatchers
    
    /// Dispatches a configuration response content event with corresponding data
    /// - Parameter data: Optional data to be attached to the event
    private func dispatchConfigurationResponse(triggerEvent: Event, data: [String: Any]?) {
        let responseEvent = triggerEvent.createResponseEvent(name: "Configuration Response Event", type: .configuration, source: .responseContent, data: data)
        dispatch(event: responseEvent)
    }
    
    /// Dispatches a configuration request content event with corresponding data
    /// - Parameter data: Data to be attached to the event
    private func dispatchConfigurationRequest(data: [String: Any]) {
        let event = Event(name: "Configuration Request Event", type: .configuration, source: .requestContent, data: data)
        dispatch(event: event)
    }

    /// Shares state with the current configuration and dispatches a configuration response event with the current configuration
    /// - Parameters:
    ///   - event: The event at which this configuration should be published at
    ///   - sharedStateResolver: a closure which is resolved with the current configuration
    private func publishCurrentConfig(event: Event, sharedStateResolver: SharedStateResolver) {
        // Update the shared state with the new configuration
        sharedStateResolver(configState.currentConfiguration)
        // Dispatch a Configuration Response Content event with the new configuration.
        dispatchConfigurationResponse(triggerEvent: event, data: configState.currentConfiguration)
    }
    
    // MARK: Helpers
    
    /// Invoked when the extension is registered with the `EventHub`, this is responsible for loading the initial state of the Configuration extension
    private func bootup() {
        let pendingResolver = createPendingSharedState(event: nil)
        
        // If we have an appId stored in persistence, kick off the configureWithAppId event
        if let appId = appIdManager.loadAppId(), !appId.isEmpty {
            dispatchConfigurationRequest(data: [ConfigurationConstants.Keys.JSON_APP_ID: appId])
        }
        
        configState.loadInitialConfig()
        if !configState.currentConfiguration.isEmpty {
            let responseEvent = Event(name: "Configuration Response Event", type: .configuration, source: .responseContent, data: configState.currentConfiguration)
            dispatch(event: responseEvent)
        }
        pendingResolver(configState.currentConfiguration)
    }

    /// The purpose of the SetAppIDInternalEvent is to refresh the existing with the persisted appId
    /// This method validates the appId for the SetAppIDInternalEvent
    /// returns true, if the persisted appId is same as the internalEvent appId present in the eventData
    /// returns false, if the persisted appId is different from the internalEvent appId present in the eventData
    /// https://jira.corp.adobe.com/browse/AMSDK-6555
    /// - Parameters:
    ///   - event: event for the API call
    ///   - newAppId: appId passed into the API
    private func validateForInternalEventAppIdChange(event: Event, newAppId: String) -> Bool {
        let isInternalEvent = event.data?[ConfigurationConstants.Keys.IS_INTERNAL_EVENT] as? Bool ?? false

        if isInternalEvent && newAppId != appIdManager.loadAppId() {
            return false
        }

        return true
    }

}
