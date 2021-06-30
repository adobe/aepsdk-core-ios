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

extension URLQueryItem {
    /// Creates a `URLQueryItem` configured with a `Identifiable`
    /// - Parameter identifier: The `Identifiable` to be encoded into the `URLQueryItem`
    init(identifier: Identifiable) {
        let cidDelimiter: String = (IdentityConstants.CID_DELIMITER.removingPercentEncoding ?? IdentityConstants.CID_DELIMITER)

        var queryString = identifier.type ?? ""
        if let identifier = identifier.identifier, !identifier.isEmpty {
            queryString += cidDelimiter + identifier
        }

        queryString += "\(cidDelimiter)\(identifier.authenticationState.rawValue)"
        self = URLQueryItem(name: IdentityConstants.VISITOR_ID_PARAMETER_KEY_CUSTOMER, value: queryString)
    }

    /// Creates a `QueryItem` for the dpid
    /// - Parameters:
    ///   - dpidKey: dpid key
    ///   - dpidValue: dpid value
    init(dpidKey: String, dpidValue: String) {
        let cidDelimiter: String = (IdentityConstants.CID_DELIMITER.removingPercentEncoding ?? IdentityConstants.CID_DELIMITER)
        let queryString = "\(dpidKey)\(cidDelimiter)\(dpidValue)"

        self = URLQueryItem(name: "d_cid", value: queryString)
    }
}
