//
/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import Foundation
import AEPServices

/// Core APIs for interacting with specific instances of the Adobe Experience Platform SDK.
@objc(AEPMobileCoreAPI)
public class MobileCoreAPI: NSObject {

    let instanceIdentifier: String
    let sdkInstanceIdentifier: SDKInstanceIdentifier?
    let eventHubProvider: EventHubProvider
    let logTag: String

    internal init(instanceIdentifier: String, eventHubProvider: EventHubProvider) {
        self.instanceIdentifier = instanceIdentifier
        sdkInstanceIdentifier = SDKInstanceIdentifier(id: instanceIdentifier)
        self.eventHubProvider = eventHubProvider
        logTag = "MobileCoreAPI-\(sdkInstanceIdentifier?.id ?? instanceIdentifier)"
        
    }
    
    private func getEventHub(_ debugInfo: String) -> EventHub? {
        guard let sdkInstanceIdentifier = sdkInstanceIdentifier else {
            Log.warning(label: logTag, "MobileCoreAPI::\(debugInfo) - SDK instance name \(instanceIdentifier) is invalid.")
            return nil
        }
        
        guard let eventHub = eventHubProvider.getEventHub(for: sdkInstanceIdentifier) else {
            Log.warning(label: logTag, "MobileCoreAPI::\(debugInfo) - SDK instance \(instanceIdentifier) has not been initialized.")
            return nil
        }
        
        return eventHub
    }
    
    /// Registers the specified extensions with Core and begins event processing.
    ///
    /// For the default SDK instance:
    /// - Migration from SDK v4 and v5 is performed before starting event processing.
    ///
    /// For named SDK instances:
    /// - Only `MultiInstanceCapable` extensions will be registered; non-conforming extensions will be skipped, and a warning will be logged.
    ///
    /// - Parameter extensions: The extensions to be registered
    /// - Parameter completion: Closure to run when extensions have been registered
    @objc(registerExtensions:completion:)
    public func registerExtensions(_ extensions: [NSObject.Type], _ completion: (() -> Void)?) {
        guard let eventHub = getEventHub(#function) else {
            completion?()
            return
        }
        
        // Migration is only supported for default instance.
        if sdkInstanceIdentifier == .default {
            let idParser = IDParser()
            V4Migrator(idParser: idParser).migrate() // before starting SDK, migrate from v4 if needed
            V5Migrator(idParser: idParser).migrate() // before starting SDK, migrate from v5 if needed
#if os(iOS)
            UserDefaultsMigrator().migrate() // before starting SDK, migrate from UserDefaults if needed
#endif
        }
        
        // Invoke registerExtension on legacy extensions
        let legacyExtensions = extensions.filter {!($0.self is Extension.Type)} // All extensions that do not conform to `Extension`
        let registerSelector = Selector(("registerExtension"))

        if NSClassFromString("ACPBridgeExtension") == nil && !legacyExtensions.isEmpty {
            Log.error(label: logTag, "Attempting to register ACP extensions: \(legacyExtensions), without the compatibility layer present. Can be included via github.com/adobe/aepsdk-compatibility-ios")
        } else {
            for legacyExtension in legacyExtensions {
                if legacyExtension.responds(to: registerSelector) {
                    legacyExtension.perform(registerSelector)
                } else {
                    Log.error(label: logTag, "Attempting to register non extension type: \(legacyExtension). If this is due to a naming collision, please use full module name when registering. E.g: AEPAnalytics.Analytics.self")
                }
            }
        }
                
        let allExtensions = [Configuration.self] + extensions + legacyExtensions
        
        var validExtensions = allExtensions.filter({$0.self is Extension.Type}) as? [Extension.Type] ?? []
        // Named instances only allow the registration of MultiInstanceCapable extensions.
        if sdkInstanceIdentifier != .default {
            validExtensions = validExtensions.filter {
                let ret = $0.self is MultiInstanceCapable.Type
                if !ret {
                    Log.warning(label: logTag, "Not registering extension \($0) as it is not MultiInstanceCapable.")
                }
                return ret
            }
        }
        
        let registeredCounter = AtomicCounter()
        validExtensions.forEach {
            eventHub.registerExtension($0) { _ in
                if registeredCounter.incrementAndGet() == validExtensions.count {
                    eventHub.start()
                    completion?()
                    return
                }
            }
        }
    }
    
    /// Registers the extension from MobileCore
    /// - Parameter exten: The extension to be registered
    @objc(registerExtension:completion:)
    public func registerExtension(_ exten: Extension.Type, _ completion: (() -> Void)?) {
        guard let eventHub = getEventHub(#function) else {
            completion?()
            return
        }
        
        eventHub.registerExtension(exten) { _ in
            eventHub.shareEventHubSharedState()
            completion?()
        }
    }

    /// Unregisters the extension from MobileCore
    /// - Parameter exten: The extension to be unregistered
    @objc(unregisterExtension:completion:)
    public func unregisterExtension(_ exten: Extension.Type, _ completion: (() -> Void)?) {
        guard let eventHub = getEventHub(#function) else {
            completion?()
            return
        }
        
        eventHub.unregisterExtension(exten) { _ in
            completion?()
        }
    }

    /// Fetches a list of registered extensions along with their respective versions
    /// - Returns: list of registered extensions along with their respective versions
    @objc
    public func getRegisteredExtensions() -> String {
        guard let eventHub = getEventHub(#function) else { return "{}" }
        
        if let registeredExtensions = eventHub.getSharedState(extensionName: EventHubConstants.NAME, event: nil)?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: registeredExtensions, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
            
        return "{}"
    }

    /// Dispatches an `Event` through the `EventHub`
    /// - Parameter event: The `Event` to be dispatched
    @objc(dispatch:)
    public func dispatch(event: Event) {
        guard let eventHub = getEventHub(#function) else { return }
        eventHub.dispatch(event: event)
    }

    /// Dispatches an `Event` through the `EventHub` and invokes a closure with the response `Event`.
    /// - Parameters:
    ///   - event: The trigger `Event` to be dispatched through the `EventHub`
    ///   - timeout: A timeout in seconds, if the response listener is not invoked within the timeout, then the `EventHub` invokes the response listener with a nil `Event`
    ///   - responseCallback: Callback to be invoked with `event`'s response `Event`
    @objc(dispatch:timeout:responseCallback:)
    public func dispatch(event: Event, timeout: TimeInterval = 1, responseCallback: @escaping (Event?) -> Void) {
        guard let eventHub = getEventHub(#function) else {
            responseCallback(nil)
            return
        }
        
        eventHub.registerResponseListener(triggerEvent: event, timeout: timeout) { event in
            responseCallback(event)
        }
        eventHub.dispatch(event: event)
    }

    /// Registers an `EventListener` to perform on the global system queue (Qos = .default) which will be invoked whenever an event with matched type and source is dispatched.
    /// - Parameters:
    ///   - type: A `String` indicating the event type the current listener is listening for
    ///   - source: A `String` indicating the event source the current listener is listening for
    ///   - listener: An `EventResponseListener` which will be invoked whenever the `EventHub` receives an event with matched type and source.
    @objc(registerEventListenerWithType:source:listener:)
    public func registerEventListener(type: String, source: String, listener: @escaping EventListener) {
        guard let eventHub = getEventHub(#function) else { return }
                
        eventHub.registerEventListener(type: type, source: source) { event in
            DispatchQueue.global(qos: .default).async {
                listener(event)
            }
        }
    }

    /// Submits a generic event containing the provided IDFA with event type `generic.identity`.
    /// - Parameter identifier: the advertising identifier string.
    @objc(setAdvertisingIdentifier:)
    public func setAdvertisingIdentifier(_ identifier: String?) {
        let data = [CoreConstants.Keys.ADVERTISING_IDENTIFIER: identifier ?? ""]
        let event = Event(name: CoreConstants.EventNames.SET_ADVERTISING_IDENTIFIER, type: EventType.genericIdentity, source: EventSource.requestContent, data: data)
        dispatch(event: event)
    }

    /// Submits a generic event containing the provided push token with event type `generic.identity`.
    /// - Parameter deviceToken: the device token for push notifications
    @objc(setPushIdentifier:)
    public func setPushIdentifier(_ deviceToken: Data?) {
        let data = [CoreConstants.Keys.PUSH_IDENTIFIER: deviceToken?.hexDescription ?? ""]
        let event = Event(name: CoreConstants.EventNames.SET_PUSH_IDENTIFIER, type: EventType.genericIdentity, source: EventSource.requestContent, data: data)
        dispatch(event: event)
    }

    /// For scenarios where the app is launched as a result of notification tap
    /// - Parameter messageInfo: Dictionary of data relevant to the expected use case
    @objc(collectMessageInfo:)
    public func collectMessageInfo(_ messageInfo: [String: Any]) {
        guard !messageInfo.isEmpty else {
            Log.trace(label: logTag, "collectMessageInfo - data was empty, no event was dispatched")
            return
        }

        let event = Event(name: CoreConstants.EventNames.COLLECT_DATA, type: EventType.genericData, source: EventSource.os, data: messageInfo)
        dispatch(event: event)
    }

    /// For scenarios where the app is launched as a result of push message or deep link click-throughs
    /// - Parameter userInfo: Dictionary of data relevant to the expected use case
    @objc(collectLaunchInfo:)
    public func collectLaunchInfo(_ userInfo: [String: Any]) {
        guard !userInfo.isEmpty else {
            Log.trace(label: logTag, "collectLaunchInfo - data was empty, no event was dispatched")
            return
        }
        let event = Event(name: CoreConstants.EventNames.COLLECT_DATA, type: EventType.genericData, source: EventSource.os,
                          data: DataMarshaller.marshalLaunchInfo(userInfo))
        dispatch(event: event)
    }

    /// Submits a generic PII collection request event with type `generic.pii`.
    /// - Parameter data: a dictionary containing PII data
    @objc(collectPii:)
    public func collectPii(_ data: [String: Any]) {
        guard !data.isEmpty else {
            Log.trace(label: logTag, "collectPii - data was empty, no event was dispatched")
            return
        }

        let eventData = [CoreConstants.Signal.EventDataKeys.CONTEXT_DATA: data]
        let event = Event(name: CoreConstants.EventNames.COLLECT_PII, type: EventType.genericPii, source: EventSource.requestContent, data: eventData)
        dispatch(event: event)
    }

    // MARK: - Configuration Methods

    /// Configure the SDK by downloading the remote configuration file hosted on Adobe servers
    /// specified by the given application ID. The configuration file is cached once downloaded
    /// and used in subsequent calls to this API. If the remote file is updated after the first
    /// download, the updated file is downloaded and replaces the cached file.
    /// - Parameter appId: A unique identifier assigned to the app instance by Adobe Launch
    @objc(configureWithAppId:)
    public func configureWith(appId: String) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURE_WITH_APP_ID, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.JSON_APP_ID: appId])
        dispatch(event: event)
    }

    /// Configure the SDK by reading a local file containing the JSON configuration. On application relaunch,
    /// the configuration from the file at `filePath` is not preserved and this method must be called again if desired.
    /// - Parameter filePath: Absolute path to a local configuration file.
    @objc(configureWithFilePath:)
    public func configureWith(filePath: String) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURE_WITH_FILE_PATH, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.JSON_FILE_PATH: filePath])
        dispatch(event: event)
    }

    /// Update the current SDK configuration with specific key/value pairs. Keys not found in the current
    /// configuration are added. Configuration updates are preserved and applied over existing or new
    /// configuration even across application restarts.
    ///
    /// Using `nil` values is allowed and effectively removes the configuration parameter from the current configuration.
    /// - Parameter configDict: configuration key/value pairs to be updated or added.
    @objc(updateConfigurationWith:)
    public func updateConfigurationWith(configDict: [String: Any]) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURATION_UPDATE, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.UPDATE_CONFIG: configDict])
        dispatch(event: event)
    }

    /// Clears the changes made by `updateConfigurationWith(configDict:)` and `setPrivacyStatus(_:)` to the initial configuration
    /// provided by either `configureWith(appId:)` or `configureWith(filePath:)`
    @objc
    public func clearUpdatedConfiguration() {
        let event = Event(name: CoreConstants.EventNames.CLEAR_UPDATED_CONFIGURATION, type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.CLEAR_UPDATED_CONFIG: true])
        dispatch(event: event)
    }

    /// Sets the `PrivacyStatus` for this SDK. The set privacy status is preserved and applied over any new
    /// configuration changes from calls to `configureWithAppId` or `configureWithFileInPath`,
    /// even across application restarts.
    /// - Parameter status: `PrivacyStatus` to be set for the SDK
    @objc(setPrivacyStatus:)
    public func setPrivacyStatus(_ status: PrivacyStatus) {
        updateConfigurationWith(configDict: [CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY: status.rawValue])
    }

    /// Gets the currently configured `PrivacyStatus` and returns it via `completion`
    /// - Parameter completion: Invoked with the current `PrivacyStatus`
    @objc(getPrivacyStatus:)
    public func getPrivacyStatus(completion: @escaping (PrivacyStatus) -> Void) {
        let event = Event(name: CoreConstants.EventNames.PRIVACY_STATUS_REQUEST, type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.RETRIEVE_CONFIG: true])

        dispatch(event: event, timeout: CoreConstants.API_TIMEOUT) { responseEvent in
            guard let privacyStatusString = responseEvent?.data?[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? String else {
                return completion(PrivacyStatus.unknown)
            }
            completion(PrivacyStatus(rawValue: privacyStatusString) ?? PrivacyStatus.unknown)
        }
    }

    /// Get a JSON string containing all of the user's identities known by the SDK and calls a handler upon completion.
    /// - Parameter completion: a closure that is invoked with a `String?` containing the SDK identities in JSON format and an `AEPError` if the request failed
    @objc(getSdkIdentities:)
    public func getSdkIdentities(completion: @escaping (String?, Error?) -> Void) {
        let event = Event(name: CoreConstants.EventNames.GET_SDK_IDENTITIES, type: EventType.configuration, source: EventSource.requestIdentity, data: nil)

        dispatch(event: event, timeout: CoreConstants.API_TIMEOUT) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            guard let identities = responseEvent.data?[CoreConstants.Keys.ALL_IDENTIFIERS] as? String else {
                completion(nil, AEPError.unexpected)
                return
            }

            completion(identities, .none)
        }
    }

    /// Clears all identifiers from Edge extensions and generates a new Experience Cloud ID (ECID).
    @objc(resetIdentities)
    public func resetIdentities() {
        let event = Event(name: CoreConstants.EventNames.RESET_IDENTITIES_REQUEST,
                          type: EventType.genericIdentity,
                          source: EventSource.requestReset,
                          data: nil)

        dispatch(event: event)
    }

    // MARK: - Tracking Methods

    /// Generates and dispatches a track action `Event`
    /// - Parameters:
    ///   - action: `String` representing the name of the action to be tracked
    ///   - data: Dictionary of data to attach to the dispatched `Event`
    @objc(trackAction:data:)
    public func track(action: String?, data: [String: Any]?) {
        var eventData: [String: Any] = [:]
        eventData[CoreConstants.Keys.CONTEXT_DATA] = data
        eventData[CoreConstants.Keys.ACTION] = action
        trackWithEventData(eventData)
    }

    /// Generates and dispatches a track state `Event`
    /// - Parameters:
    ///   - state: `String` representing the name of the state to be tracked
    ///   - data: Dictionary of data to attach to the dispatched `Event`
    @objc(trackState:data:)
    public func track(state: String?, data: [String: Any]?) {
        var eventData: [String: Any] = [:]
        eventData[CoreConstants.Keys.CONTEXT_DATA] = data
        eventData[CoreConstants.Keys.STATE] = state
        trackWithEventData(eventData)
    }
    
    /// Dispatches an Analytics Track event with the provided `eventData`
    /// - Parameter eventData: Optional dictionary containing data for the outgoing `Event`
    private func trackWithEventData(_ eventData: [String: Any]?) {
        let event = Event(name: CoreConstants.EventNames.ANALYTICS_TRACK,
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: eventData)
        dispatch(event: event)
    }

    // MARK: - Lifecycle Methods

    /// Start a new lifecycle session or resume a previously paused lifecycle session. If a previously paused
    /// session timed out, then a new session is created. If a current session is running, then calling this
    /// method does nothing.
    /// - Parameter additionalContextData: Optional additional context for this session.
    @objc(lifecycleStart:)
    public func lifecycleStart(additionalContextData: [String: Any]?) {
        let data: [String: Any] = [CoreConstants.Keys.ACTION: CoreConstants.Lifecycle.START,
                                   CoreConstants.Keys.ADDITIONAL_CONTEXT_DATA: additionalContextData ?? [:]]
        let event = Event(name: CoreConstants.EventNames.LIFECYCLE_RESUME, type: EventType.genericLifecycle, source: EventSource.requestContent, data: data)
        dispatch(event: event)
    }

    /// Pauses the current lifecycle session. Calling pause on an already paused session updates the paused timestamp,
    /// having the effect of resetting the session timeout timer. If no lifecycle session is running,
    /// then calling this method does nothing.
    @objc(lifecyclePause)
    public func lifecyclePause() {
        let data = [CoreConstants.Keys.ACTION: CoreConstants.Lifecycle.PAUSE]
        let event = Event(name: CoreConstants.EventNames.LIFECYCLE_PAUSE, type: EventType.genericLifecycle, source: EventSource.requestContent, data: data)
        dispatch(event: event)
    }
}
