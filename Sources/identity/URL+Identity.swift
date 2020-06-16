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

extension URL {
    
    /// Creates a new Identity hit URL
    /// - Parameters:
    ///   - experienceCloudServer: the experience cloud server
    ///   - orgId: the org id from Configuration
    ///   - identityProperties: the current `IdentityProperties` in the Identity extension
    ///   - dpids: a dictionary of dpids
    init?(experienceCloudServer: String, orgId: String, identityProperties: IdentityProperties, dpids: [String: String]) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = experienceCloudServer
        components.path = "/id"
        
        var queryItems = [
            URLQueryItem(name: "d_rtbd", value: "json"),
            URLQueryItem(name: "d_ver", value: "2"),
            URLQueryItem(name: IdentityConstants.RESPONSE_KEY_ORGID, value: orgId),
        ]
        
        if let mid = identityProperties.mid {
            queryItems += [URLQueryItem(name: IdentityConstants.RESPONSE_KEY_MID, value: mid.midString)]
        }
        
        if let blob = identityProperties.blob {
            queryItems += [URLQueryItem(name: IdentityConstants.RESPONSE_KEY_BLOB, value: blob)]
        }
        
        if let locationHint = identityProperties.locationHint {
            queryItems += [URLQueryItem(name: IdentityConstants.RESPONSE_KEY_HINT, value: locationHint)]
        }
        
        // Add customer ids
        if let customerIds = identityProperties.customerIds {
            for customIdQueryItem in customerIds {
                queryItems += [URLQueryItem(identifier: customIdQueryItem)]
            }
        }
        
        // Add dpids
        for (key, value) in dpids {
            queryItems += [URLQueryItem(dpidKey: key, dpidValue: value)]
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else { return nil }
        self = url
    }
    
    /// Builds the `URL` responsible for sending an opt-out hit
    /// - Parameters:
    ///   - orgId: the org id from Configuration
    ///   - mid: the mid
    ///   - experienceCloudServer: the experience cloud server
    /// - Returns: A network request configured to send the opt-out request, nil if failed
    init?(orgId: String, mid: MID, experienceCloudServer: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = experienceCloudServer
        components.path = IdentityConstants.KEY_PATH_OPTOUT
        components.queryItems = [
            URLQueryItem(name: IdentityConstants.RESPONSE_KEY_ORGID, value: orgId),
            URLQueryItem(name: IdentityConstants.RESPONSE_KEY_MID, value: mid.midString)
        ]

        guard let url = components.url else { return nil }
        self = url
    }
}
