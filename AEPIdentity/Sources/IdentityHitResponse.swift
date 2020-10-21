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

/// Struct to represent IdentityExtension network call json response.
struct IdentityHitResponse: Codable {
    /// Blob value as received in the visitor id service network response json
    let blob: String?

    /// Marketing cloud id value as received in the visitor id service network response json.
    let ecid: String?

    /// Location value as received in the visitor id service network response json.
    let hint: Int?

    /// Error value as received in the visitor id service network response json.
    let error: String?

    /// ttl value as received in the visitor id service network response json.
    let ttl: TimeInterval?

    /// ArrayList of global opt out as received in the visitor id service network response json.
    let optOutList: [String]?

    enum CodingKeys: String, CodingKey {
        case blob = "d_blob"
        case ecid = "d_mid"
        case hint = "dcs_region"
        case error = "error_msg"
        case ttl = "id_sync_ttl"
        case optOutList = "d_optout"
    }
}
