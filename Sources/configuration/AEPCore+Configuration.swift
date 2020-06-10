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
extension AEPCore: Configuration {
    public static func configureWith(appId: String) {
        let event = Event(name: "Configure with AppId", type: .configuration, source: .requestContent,
                          data: [ConfigurationConstants.Keys.JSON_APP_ID: appId])
        AEPCore.dispatch(event: event)
    }

    public static func configureWith(filePath: String) {
        let event = Event(name: "Configure with file path", type: .configuration, source: .requestContent,
                          data: [ConfigurationConstants.Keys.JSON_FILE_PATH: filePath])
        AEPCore.dispatch(event: event)
    }

    public static func updateConfigurationWith(configDict: [String: Any]) {
        let event = Event(name: "Configuration Update", type: .configuration, source: .requestContent,
                          data: [ConfigurationConstants.Keys.UPDATE_CONFIG: configDict])
        AEPCore.dispatch(event: event)
    }

    public static func setPrivacy(status: PrivacyStatus) {
        updateConfigurationWith(configDict: [ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: status.rawValue])
    }

    public static func getPrivacyStatus(completion: @escaping (PrivacyStatus) -> ()) {
        let event = Event(name: "Privacy Status Request", type: .configuration, source: .requestContent, data: [ConfigurationConstants.Keys.RETRIEVE_CONFIG: true])

        EventHub.shared.registerResponseListener(parentExtension: AEPConfiguration.self, triggerEvent: event, timeout: ConfigurationConstants.API_TIMEOUT) { (responseEvent) in
            self.handleGetPrivacyListener(responseEvent: responseEvent, completion: completion)
        }

        AEPCore.dispatch(event: event)
    }
    
    // MARK: Helper
    private static func handleGetPrivacyListener(responseEvent: Event?, completion: @escaping (PrivacyStatus) -> ()) {
        guard let privacyStatusString = responseEvent?.data?[ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? String else {
            return completion(PrivacyStatus.unknown)
        }

        completion(PrivacyStatus(rawValue: privacyStatusString) ?? PrivacyStatus.unknown)
    }

}
