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

import AEPCore
import Foundation

/// Struct representing a hit stored in the Signal database
struct SignalHit: Codable {
    /// URL for the postback
    let url: URL

    /// Optional POST body for the postback
    let postBody: String?

    /// Content-Type header for the postback
    let contentType: String?

    /// Timeout for the network request
    let timeout: TimeInterval?

    /// Event responsible for triggering this postback
    let event: Event
}
