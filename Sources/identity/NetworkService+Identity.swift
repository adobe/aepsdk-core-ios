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

extension URLQueryItem {
    init(customId: Identifiable) {
        var queryString = ""
        if let encodedType = URLEncoder.encode(value: customId.type ?? "") {
            queryString = encodedType + IdentityConstants.CID_DELIMITER
        }
        
        if let encodedId = URLEncoder.encode(value: customId.identifier ?? "") {
            queryString += encodedId
        }
        
        queryString += "\(IdentityConstants.CID_DELIMITER)\(customId.authenticationState.rawValue)"
        self = URLQueryItem(name: IdentityConstants.VISITOR_ID_PARAMETER_KEY_CUSTOMER, value: queryString)
    }
    
    init?(dpidKey: String, dpidValue: String) {
        guard let encodedKey = URLEncoder.encode(value: dpidKey), let encodedValue = URLEncoder.encode(value: dpidValue) else { return nil }
        let queryString = "\(encodedKey)\(IdentityConstants.CID_DELIMITER)\(encodedValue)"
        self = URLQueryItem(name: "d_cid=", value: queryString)
    }
}

extension URL {
    
    init?(experienceCloudServer: String, orgId: String, identityProperties: IdentityProperties, dpids: [String: String]) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = experienceCloudServer
        components.path = "id/"
        
        var queryItems = [
            URLQueryItem(name: "d_ver", value: "2"),
            URLQueryItem(name: "d_rtbd", value: "json"),
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
            for encodedCustomId in customerIds {
                queryItems += [URLQueryItem(customId: encodedCustomId)]
            }
        }
        
        // Add dpids
        for (key, val) in dpids {
            if let dpidQueryItem = URLQueryItem(dpidKey: key, dpidValue: val) {
                queryItems += [dpidQueryItem]
            }
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

extension NetworkService {

    /// Sends the `NetworkRequest` responsible for sending an opt-out hit
    /// - Parameters:
    ///   - orgId: the org id from Configuration
    ///   - mid: the mid
    ///   - experienceCloudServer: the experience cloud server
    func sendOptOutRequest(orgId: String, mid: MID, experienceCloudServer: String) {
        guard let url = URL(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer) else { return }
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: NetworkRequest(url: url), completionHandler: nil) // fire and forget
    }
}
