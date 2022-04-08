/*
 Copyright 2021 Adobe. All rights reserved.
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

/// XDM Mobile Lifecycle Details schema representation
struct XDMMobileLifecycleDetails {
    init() {}

    /// Application for the Lifecycle details
    var application: XDMApplication?

    /// Device for the Lifecycle details
    var device: XDMDevice?

    /// Environment for the Lifecycle details
    var environment: XDMEnvironment?

    /// Event type for the Lifecycle details
    var eventType: String?

    /// Timestamp of the Lifecycle details
    var timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case application
        case device
        case environment
        case eventType
        case timestamp
    }
}

extension XDMMobileLifecycleDetails: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = application { try container.encode(unwrapped, forKey: .application) }
        if let unwrapped = device { try container.encode(unwrapped, forKey: .device) }
        if let unwrapped = environment { try container.encode(unwrapped, forKey: .environment) }
        if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
        if let unwrapped = timestamp?.getISO8601UTCDateWithMilliseconds() { try container.encode(unwrapped, forKey: .timestamp) }
    }
}
