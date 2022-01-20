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

/// Implements the `Configuration` public APIs
@objc
public extension MobileCore {
    /// Configure the SDK by downloading the remote configuration file hosted on Adobe servers
    /// specified by the given application ID. The configuration file is cached once downloaded
    /// and used in subsequent calls to this API. If the remote file is updated after the first
    /// download, the updated file is downloaded and replaces the cached file.
    /// - Parameter appId: A unique identifier assigned to the app instance by Adobe Launch
    static func configureWith(appId: String) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURE_WITH_APP_ID, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.JSON_APP_ID: appId])
        MobileCore.dispatch(event: event)
    }

    /// Configure the SDK by reading a local file containing the JSON configuration. On application relaunch,
    /// the configuration from the file at `filePath` is not preserved and this method must be called again if desired.
    /// - Parameter filePath: Absolute path to a local configuration file.
    static func configureWith(filePath: String) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURE_WITH_FILE_PATH, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.JSON_FILE_PATH: filePath])
        MobileCore.dispatch(event: event)
    }

    /// Update the current SDK configuration with specific key/value pairs. Keys not found in the current
    /// configuration are added. Configuration updates are preserved and applied over existing or new
    /// configuration even across application restarts.
    ///
    /// Using `nil` values is allowed and effectively removes the configuration parameter from the current configuration.
    /// - Parameter configDict: configuration key/value pairs to be updated or added.
    @objc(updateConfiguration:)
    static func updateConfigurationWith(configDict: [String: Any]) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURATION_UPDATE, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.UPDATE_CONFIG: configDict])
        MobileCore.dispatch(event: event)
    }

    /// Clears the changes made by ``updateConfigurationWith(configDict:)`` and ``setPrivacyStatus(_:)`` to the initial configuration
    /// provided by either ``configureWith(appId:)`` or ``configureWith(filePath:)``
    static func clearUpdatedConfiguration() {
        let event = Event(name: CoreConstants.EventNames.CLEAR_UPDATED_CONFIGURATION, type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.CLEAR_UPDATED_CONFIG: true])
        MobileCore.dispatch(event: event)
    }

    /// Sets the `PrivacyStatus` for this SDK. The set privacy status is preserved and applied over any new
    /// configuration changes from calls to configureWithAppId or configureWithFileInPath,
    /// even across application restarts.
    /// - Parameter status: `PrivacyStatus` to be set for the SDK
    @objc(setPrivacyStatus:)
    static func setPrivacyStatus(_ status: PrivacyStatus) {
        updateConfigurationWith(configDict: [CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY: status.rawValue])
    }

    /// Gets the currently configured `PrivacyStatus` and returns it via `completion`
    /// - Parameter completion: Invoked with the current `PrivacyStatus`
    @objc(getPrivacyStatus:)
    static func getPrivacyStatus(completion: @escaping (PrivacyStatus) -> Void) {
        let event = Event(name: CoreConstants.EventNames.PRIVACY_STATUS_REQUEST, type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.RETRIEVE_CONFIG: true])

        EventHub.shared.registerResponseListener(triggerEvent: event, timeout: CoreConstants.API_TIMEOUT) { responseEvent in
            guard let privacyStatusString = responseEvent?.data?[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? String else {
                return completion(PrivacyStatus.unknown)
            }
            completion(PrivacyStatus(rawValue: privacyStatusString) ?? PrivacyStatus.unknown)
        }

        MobileCore.dispatch(event: event)
    }

    /// Get a JSON string containing all of the user's identities known by the SDK  and calls a handler upon completion.
    /// - Parameter completion: a closure that is invoked with a `String?` containing the SDK identities in JSON format and an `AEPError` if the request failed
    @objc(getSdkIdentities:)
    static func getSdkIdentities(completion: @escaping (String?, Error?) -> Void) {
        let event = Event(name: CoreConstants.EventNames.GET_SDK_IDENTITIES, type: EventType.configuration, source: EventSource.requestIdentity, data: nil)

        EventHub.shared.registerResponseListener(triggerEvent: event, timeout: 1) { responseEvent in
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

        MobileCore.dispatch(event: event)
    }

    /// Clears all identifiers from Edge extensions and generates a new Experience Cloud ID (ECID).
    @objc(resetIdentities)
    static func resetIdentities() {
        let event = Event(name: CoreConstants.EventNames.RESET_IDENTITIES_REQUEST,
                          type: EventType.genericIdentity,
                          source: EventSource.requestReset,
                          data: nil)

        MobileCore.dispatch(event: event)
    }
}
