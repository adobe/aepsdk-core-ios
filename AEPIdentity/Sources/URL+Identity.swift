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
import AEPServices

extension URL {

    private static let LOG_TAG = "URL+Identity"

    /// Creates a new Identity hit URL
    /// - Parameters:
    ///   - experienceCloudServer: the experience cloud server
    ///   - orgId: the org id from Configuration
    ///   - identityProperties: the current `IdentityProperties` in the Identity extension
    ///   - dpids: a dictionary of dpids
    ///   - addConsentFlag: true if the adId changed, false otherwise
    static func buildIdentityHitURL(experienceCloudServer: String, orgId: String, identityProperties: IdentityProperties, dpids: [String: String], addConsentFlag: Bool) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = experienceCloudServer
        components.path = "/id"

        var queryItems = [
            URLQueryItem(name: "d_rtbd", value: "json"),
            URLQueryItem(name: "d_ver", value: "2"),
            URLQueryItem(name: IdentityConstants.URLKeys.ORGID, value: orgId),
        ]

        if let ecid = identityProperties.ecid {
            queryItems += [URLQueryItem(name: IdentityConstants.URLKeys.ECID, value: ecid.ecidString)]
        }

        if let blob = identityProperties.blob {
            queryItems += [URLQueryItem(name: IdentityConstants.URLKeys.BLOB, value: blob)]
        }

        if let locationHint = identityProperties.locationHint {
            queryItems += [URLQueryItem(name: IdentityConstants.URLKeys.HINT, value: locationHint)]
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

        // Add IDFA consent
        if addConsentFlag {
            let idEmpty = (identityProperties.advertisingIdentifier?.isEmpty ?? true) ? "0" : "1"
            queryItems += [URLQueryItem(name: IdentityConstants.URLKeys.DEVICE_CONSENT, value: idEmpty)]

            if idEmpty == "0" {
                queryItems += [URLQueryItem(name: IdentityConstants.URLKeys.CONSENT_INTEGRATION_CODE, value: IdentityConstants.ADID_DSID)]
            }
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            Log.error(label: LOG_TAG, "Building Identity hit URL failed, returning nil.")
            return nil
        }
        return url
    }

    /// Builds the `URL` responsible for sending an opt-out hit
    /// - Parameters:
    ///   - orgId: the org id from Configuration
    ///   - ecid: the experience cloud id
    ///   - experienceCloudServer: the experience cloud server
    /// - Returns: A network request configured to send the opt-out request, nil if failed
    static func buildOptOutURL(orgId: String, ecid: ECID, experienceCloudServer: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = experienceCloudServer
        components.path = IdentityConstants.KEY_PATH_OPTOUT
        components.queryItems = [
            URLQueryItem(name: IdentityConstants.URLKeys.ORGID, value: orgId),
            URLQueryItem(name: IdentityConstants.URLKeys.ECID, value: ecid.ecidString),
        ]

        guard let url = components.url else {
            Log.error(label: LOG_TAG, "Building Identity opt-out hit URL failed, returning nil.")
            return nil
        }
        return url
    }
}
