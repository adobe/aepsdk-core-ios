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

///  Responsible to retrieve the configuration for each extension of the SDK, update the shared state and output an event to the `EventHub that will contain these settings.
class AEPConfiguration: Extension {
    var name: String = ConfigurationConstants.EXTENSION_NAME
    var version: String = ConfigurationConstants.EXTENSION_VERSION

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
    private func receiveConfigurationRequest(event: Event) {
        eventQueue.add((event, handleConfigurationRequest(event:)))
    }

    private func receiveLifecycleResponse(event: Event) {
        eventQueue.add((event, handleLifecycle(event:)))
    }

    // MARK: Event Handlers
    func handleConfigurationRequest(event: Event) -> Bool {
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

    func handleLifecycle(event: Event) -> Bool {
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
            } else {
                // If downloading config failed, resolve shared state with current config and try again later
                sharedStateResolver(self?.configState.currentConfiguration)
            }
            
            self?.eventQueue.start()
        }
        
        // always return false to pause the queue while the configuration is being downloaded
        return false
    }
    
    /// Processes the configWithFilePath event
    /// - Parameters:
    ///   - filePath: The file path at which the configuration should be loaded from
    ///   - event: The 
    ///   - sharedStateResolver: Shared state resolver that should be invoked with the new configuration
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

    // MARK: Helpers
    private func bootup() {
        let pendingResolver = createPendingSharedState(event: nil)
        // TODO kick off app id download if app id present
        configState.loadInitialConfig()
        pendingResolver(configState.currentConfiguration)
        if !configState.currentConfiguration.isEmpty {
            let responseEvent = Event(name: "Configuration Response Event", type: .configuration, source: .responseContent, data: configState.currentConfiguration)
            dispatch(event: responseEvent)
        }
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
