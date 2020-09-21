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

extension Networking {
    /// Sends the `NetworkRequest` responsible for sending an opt-out hit
    /// - Parameters:
    ///   - orgId: the org id from Configuration
    ///   - ecid: the experience cloud id
    ///   - experienceCloudServer: the experience cloud server
    func sendOptOutRequest(orgId: String, ecid: ECID, experienceCloudServer: String) {
        guard let url = URL.buildOptOutURL(orgId: orgId, ecid: ecid, experienceCloudServer: experienceCloudServer) else { return }
        ServiceProvider.shared.networkService.connectAsync(networkRequest: NetworkRequest(url: url), completionHandler: nil) // fire and forget
    }
}
