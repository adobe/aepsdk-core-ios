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

import AEPServices
import Foundation

/// Responsible for retrieving the configuration of the SDK and updating the shared state and dispatching configuration updates through the `EventHub`
class Configuration: NSObject, Extension {
    let runtime: ExtensionRuntime
    let name = ConfigurationConstants.EXTENSION_NAME
    let friendlyName = ConfigurationConstants.FRIENDLY_NAME
    public static let extensionVersion = ConfigurationConstants.EXTENSION_VERSION
    let metadata: [String: String]? = nil

    private let dataStore = NamedCollectionDataStore(name: ConfigurationConstants.DATA_STORE_NAME)
    private var appIdManager: LaunchIDManager
    private var configState: ConfigurationState // should only be modified/used within the event queue
    private let rulesEngine: LaunchRulesEngine
    private let retryQueue = DispatchQueue(label: "com.adobe.configuration.retry")
    private let rulesEngineName = "\(ConfigurationConstants.EXTENSION_NAME).rulesengine"
    private var retryConfigurationCounter: Double = 1

    // MARK: - Extension

    /// Initializes the Configuration extension and it's dependencies
    required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        rulesEngine = LaunchRulesEngine(name: rulesEngineName, extensionRuntime: runtime)

        appIdManager = LaunchIDManager(dataStore: dataStore)
        configState = ConfigurationState(dataStore: dataStore, configDownloader: ConfigurationDownloader())
    }

    /// Invoked when the Configuration extension has been registered by the `EventHub`, this results in the Configuration extension loading the first configuration for the SDK
    func onRegistered() {
        registerPreprocessor(rulesEngine.process(event:))

        registerListener(type: EventType.configuration, source: EventSource.requestContent, listener: receiveConfigurationRequest(event:))

        // If we have an appId stored in persistence, kick off the configureWithAppId event
        if let appId = appIdManager.loadAppId(), !appId.isEmpty {
            dispatchConfigurationRequest(data: [CoreConstants.Keys.JSON_APP_ID: appId, CoreConstants.Keys.IS_INTERNAL_EVENT: true])
        }

        configState.loadInitialConfig()
        let config = configState.environmentAwareConfiguration
        if !config.isEmpty {
            let responseEvent = Event(name: CoreConstants.EventNames.CONFIGURATION_RESPONSE_EVENT, type: EventType.configuration, source: EventSource.responseContent, data: config)
            dispatch(event: responseEvent)
            createSharedState(data: config, event: nil)
            // notify rules engine to load cached rules
            if let rulesURLString = config[ConfigurationConstants.Keys.RULES_URL] as? String {
                Log.trace(label: name, "Reading rules from cache for URL: \(rulesURLString)")
                if !rulesEngine.replaceRulesWithCache(from: rulesURLString) {
                    if let url = Bundle.main.url(forResource: RulesDownloaderConstants.RULES_BUNDLED_FILE_NAME, withExtension: "zip") {
                        // Attempt to load rules from manifest if none in cache
                        rulesEngine.replaceRulesWithManifest(from: url)
                    }
                }
            }
        }
    }

    /// Invoked when the Configuration extension has been unregistered by the `EventHub`, currently a no-op.
    func onUnregistered() {}

    /// Configuration extension is always ready for an `Event`
    /// - Parameter event: an `Event`
    func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    // MARK: - Event Listeners

    /// Invoked by the `eventQueue` each time a new configuration request event is received
    /// - Parameter event: A configuration request event
    private func receiveConfigurationRequest(event: Event) {
        if event.isUpdateConfigEvent {
            processUpdateConfig(event: event, sharedStateResolver: createPendingSharedState(event: event))
        } else if event.isClearConfigEvent {
            processClearUpdatedConfig(sharedStateResolver: createPendingSharedState(event: event))
        } else if event.isGetConfigEvent {
            dispatchConfigurationResponse(requestEvent: event, data: configState.environmentAwareConfiguration)
        } else if let appId = event.appId {
            processConfigureWith(appId: appId, event: event, sharedStateResolver: createPendingSharedState(event: event))
        } else if let filePath = event.filePath {
            processConfigureWith(filePath: filePath, event: event, sharedStateResolver: createPendingSharedState(event: event))
        }
    }

    // MARK: - Event Processors

    /// Interacts with the `ConfigurationState` to update the configuration with the new configuration contained in `event`
    /// - Parameters:
    ///   - event: The `event` which contains the new configuration
    ///   - sharedStateResolver: Shared state resolver that will be invoked with the new configuration
    /// - Returns: True if processing the update configuration event succeeds, false otherwise
    private func processUpdateConfig(event: Event, sharedStateResolver: SharedStateResolver) {
        // Update the overriddenConfig with the new config from API and persist them in disk, and abort if overridden config is empty
        guard let updatedConfig = event.data?[ConfigurationConstants.Keys.UPDATE_CONFIG] as? [String: Any], !updatedConfig.isEmpty else {
            Log.warning(label: name, "Overriden config is empty, resolving pending shared state with current config")
            sharedStateResolver(configState.environmentAwareConfiguration)
            return
        }

        configState.updateWith(programmaticConfig: updatedConfig)
        // Create shared state and dispatch configuration response content
        publishCurrentConfig(sharedStateResolver: sharedStateResolver)
    }

    /// Interacts with the `ConfigurationState` to download the configuration associated with `appId`
    /// - Parameters:
    ///   - appId: The appId for which a configuration should be downloaded from
    ///   - event: The event responsible for the API call
    ///   - sharedStateResolver: Shared state resolver that will be invoked with the new configuration
    private func processConfigureWith(appId: String, event: Event, sharedStateResolver: @escaping SharedStateResolver) {
        guard !appId.isEmpty else {
            // Error: No appId provided or its empty, resolve pending shared state with current config
            Log.warning(label: name, "No AppID provided or it is empty, resolving pending shared state with current config")
            appIdManager.removeAppIdFromPersistence()
            sharedStateResolver(configState.environmentAwareConfiguration)
            return
        }

        // check if the configuration state has unexpired config associated with appId, if so early exit
        guard !configState.hasUnexpiredConfig(appId: appId) else {
            sharedStateResolver(configState.environmentAwareConfiguration)
            return
        }

        guard !isStaleAppIdUpdateRequest(newAppId: appId, isInternalEvent: event.isInternalConfigEvent) else {
            Log.debug(label: name, "An explicit configureWithAppId request has preceded this internal event.")
            return
        }

        // stop all other event processing while we are attempting to download the config
        stopEvents()
        configState.updateWith(appId: appId) { [weak self] config in
            guard let self = self else { return }
            if let _ = config {
                self.publishCurrentConfig(sharedStateResolver: sharedStateResolver)
                self.startEvents()
            } else {
                // If downloading config failed try again later
                sharedStateResolver(self.configState.environmentAwareConfiguration)
                self.startEvents()
                let retryInterval = self.retryConfigurationCounter * 5
                Log.trace(label: self.name, "Downloading config failed, trying again after \(retryInterval) secs")
                self.retryQueue.asyncAfter(deadline: .now() + retryInterval) {
                    let event = Event(name: CoreConstants.EventNames.CONFIGURE_WITH_APP_ID, type: EventType.configuration, source: EventSource.requestContent,
                                      data: [CoreConstants.Keys.JSON_APP_ID: appId, CoreConstants.Keys.IS_INTERNAL_EVENT: true])
                    self.dispatch(event: event)
                    self.retryConfigurationCounter += 1
                }
            }
        }
    }

    /// Determines if the current AppID update request is stale.
    /// A request is considered stale if it is a configuration request sent internally and there is a newer request that has been sent externally via configureWithAppId
    /// - Parameters:
    ///     - newAppId the new app ID with which the configuration update is being requested
    ///     - isInternalEvent whether the current request is an initial configuration request
    /// - Returns: True if the current request is stale, False otherwise
    private func isStaleAppIdUpdateRequest(newAppId: String, isInternalEvent: Bool) -> Bool {
        // Because events are dispatched and processed serially, external config with app id events
        // cannot be stale.
        guard isInternalEvent else {
            return false
        }

        // Cannot find persisted app id, process with this request.
        guard let persistedAppId = appIdManager.loadAppIdFromPersistence(), !persistedAppId.isEmpty else {
            return false
        }

        return newAppId != persistedAppId
    }

    /// Interacts with the `ConfigurationState` to fetch the configuration associated with `filePath`
    /// - Parameters:
    ///   - filePath: The file path at which the configuration should be loaded from
    ///   - event: The event responsible for the API call
    ///   - sharedStateResolver: Shared state resolver that will be invoked with the new configuration
    private func processConfigureWith(filePath: String, event: Event, sharedStateResolver: SharedStateResolver) {
        guard let filePath = event.data?[ConfigurationConstants.Keys.JSON_FILE_PATH] as? String, !filePath.isEmpty else {
            // Error: Shared state is updated with previous config
            Log.warning(label: name, "Loaded configuration from file path was empty, using previous config.")
            sharedStateResolver(configState.environmentAwareConfiguration)
            return
        }

        if configState.updateWith(filePath: filePath) {
            publishCurrentConfig(sharedStateResolver: sharedStateResolver)
        } else {
            // loading from bundled config failed, resolve shared state with current config without dispatching a config response event
            sharedStateResolver(configState.environmentAwareConfiguration)
        }
    }

    /// Interacts with the `ConfigurationState` to clear any updates made to configuration after the initially set configuration
    /// - Parameter sharedStateResolver: Shared state resolver that will be invoked with the initial configuration
    private func processClearUpdatedConfig(sharedStateResolver: SharedStateResolver) {
        configState.clearConfigUpdates()
        publishCurrentConfig(sharedStateResolver: sharedStateResolver)
    }

    // MARK: - Dispatchers

    /// Dispatches a configuration response content event with corresponding data
    /// - Parameters:
    ///   - requestEvent: The `Event` to which the newly dispatched `Event` is responding, null if this is a generic response
    ///   - data: Optional data to be attached to the event
    private func dispatchConfigurationResponse(requestEvent: Event?, data: [String: Any]?) {
        if let requestEvent = requestEvent {
            let pairedResponseEvent = requestEvent.createResponseEvent(name: CoreConstants.EventNames.CONFIGURATION_RESPONSE_EVENT, type: EventType.configuration, source: EventSource.responseContent, data: data)
            dispatch(event: pairedResponseEvent)
            return
        }

        // send a generic event if this is not the response to a getter
        let responseEvent = Event(name: CoreConstants.EventNames.CONFIGURATION_RESPONSE_EVENT, type: EventType.configuration, source: EventSource.responseContent, data: data)
        dispatch(event: responseEvent)
        return

    }

    /// Dispatches a configuration request content event with corresponding data
    /// - Parameter data: Data to be attached to the event
    private func dispatchConfigurationRequest(data: [String: Any]) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURATION_REQUEST_EVENT,
                          type: EventType.configuration,
                          source: EventSource.requestContent,
                          data: data)
        dispatch(event: event)
    }

    /// Shares state with the current configuration and dispatches a configuration response event with the current configuration
    /// - Parameters:
    ///   - sharedStateResolver: a closure which is resolved with the current configuration
    private func publishCurrentConfig(sharedStateResolver: SharedStateResolver) {
        let config = configState.environmentAwareConfiguration
        // Update the shared state with the new configuration
        sharedStateResolver(config)
        // Dispatch a Configuration Response Content event with the new configuration.
        dispatchConfigurationResponse(requestEvent: nil, data: config)
        // notify the rules engine about the change of config
        notifyRulesEngine(newConfiguration: config)
    }

    /// Notifies the rules engine about a change in config
    /// - Parameter newConfiguration: the current config
    private func notifyRulesEngine(newConfiguration: [String: Any]) {
        if let rulesURLString = newConfiguration[ConfigurationConstants.Keys.RULES_URL] as? String {
            rulesEngine.replaceRules(from: rulesURLString)
        }
    }
}
