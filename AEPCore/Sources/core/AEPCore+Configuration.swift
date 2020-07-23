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
extension MobileCore: Configuration {
    public static func configureWith(appId: String) {
        let event = Event(name: "Configure with AppId", type: .configuration, source: .requestContent,
                          data: [CoreConstants.Keys.JSON_APP_ID: appId])
        MobileCore.dispatch(event: event)
    }

    public static func configureWith(filePath: String) {
        let event = Event(name: "Configure with file path", type: .configuration, source: .requestContent,
                          data: [CoreConstants.Keys.JSON_FILE_PATH: filePath])
        MobileCore.dispatch(event: event)
    }

    public static func updateConfigurationWith(configDict: [String: Any]) {
        let event = Event(name: "Configuration Update", type: .configuration, source: .requestContent,
                          data: [CoreConstants.Keys.UPDATE_CONFIG: configDict])
        MobileCore.dispatch(event: event)
    }

    public static func setPrivacy(status: PrivacyStatus) {
        updateConfigurationWith(configDict: [CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY: status.rawValue])
    }

    public static func getPrivacyStatus(completion: @escaping (PrivacyStatus) -> ()) {
        let event = Event(name: "Privacy Status Request", type: .configuration, source: .requestContent, data: [CoreConstants.Keys.RETRIEVE_CONFIG: true])

        EventHub.shared.registerResponseListener(triggerEvent: event, timeout: CoreConstants.API_TIMEOUT) { (responseEvent) in
            self.handleGetPrivacyListener(responseEvent: responseEvent, completion: completion)
        }

        MobileCore.dispatch(event: event)
    }
    
    public static func getSdkIdentities(completion: @escaping (String?, AEPError?) -> ()) {
        let event = Event(name: "GetSdkIdentities", type: .configuration, source: .requestIdentity, data: nil)
        
        EventHub.shared.registerResponseListener(triggerEvent: event, timeout: 1) { (responseEvent) in
            guard let responseEvent = responseEvent else {
                completion(nil, .callbackTimeout)
                return
            }
            
            guard let identities = responseEvent.data?[CoreConstants.Keys.ALL_IDENTIFIERS] as? String else {
                completion(nil, .unexpected)
                return
            }
            
            completion(identities, nil)
        }
        
        MobileCore.dispatch(event: event)
    }
    
    // MARK: Helper
    private static func handleGetPrivacyListener(responseEvent: Event?, completion: @escaping (PrivacyStatus) -> ()) {
        guard let privacyStatusString = responseEvent?.data?[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? String else {
            return completion(PrivacyStatus.unknown)
        }

        completion(PrivacyStatus(rawValue: privacyStatusString) ?? PrivacyStatus.unknown)
    }

}
