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

/// Defines the public interface for the Configuration extension
protocol Configuration {

    /// Configure the SDK by downloading the remote configuration file hosted on Adobe servers
    /// specified by the given application ID. The configuration file is cached once downloaded
    /// and used in subsequent calls to this API. If the remote file is updated after the first
    /// download, the updated file is downloaded and replaces the cached file.
    /// - Parameter appId: A unique identifier assigned to the app instance by Adobe Launch
    static func configureWith(appId: String)

    /// Configure the SDK by reading a local file containing the JSON configuration. On application relaunch,
    /// the configuration from the file at `filePath` is not preserved and this method must be called again if desired.
    /// - Parameter filePath: Absolute path to a local configuration file.
    static func configureWith(filePath: String)

    /// Update the current SDK configuration with specific key/value pairs. Keys not found in the current
    /// configuration are added. Configuration updates are preserved and applied over existing or new
    /// configuration even across application restarts.
    ///
    /// Using `nil` values is allowed and effectively removes the configuration parameter from the current configuration.
    /// - Parameter configDict: configuration key/value pairs to be updated or added.
    static func updateConfigurationWith(configDict: [String: Any])

    /// Sets the `PrivacyStatus` for this SDK. The set privacy status is preserved and applied over any new
    /// configuration changes from calls to configureWithAppId or configureWithFileInPath,
    /// even across application restarts.
    /// - Parameter status: `PrivacyStatus` to be set for the SDK
    static func setPrivacy(status: PrivacyStatus)

    /// Gets the currently configured `PrivacyStatus` and returns it via `completion`
    /// - Parameter completion: Invoked with the current `PrivacyStatus`
    static func getPrivacyStatus(completion: @escaping (PrivacyStatus) -> ())
    
    /// Get a JSON string containing all of the user's identities known by the SDK  and calls a handler upon completion.
    /// - Parameter completion: a closure that is invoked with a `String?` containing the SDK identities in JSON format a and `AEPError` if the request failed
    static func getSdkIdentities(completion: @escaping (String?, AEPError?) -> ())
}
