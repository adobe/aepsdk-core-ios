//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices
import Foundation

/// Represents an XDM Application schema
struct XDMApplication {
    init() {}

    var closeType: XDMCloseType?
    var id: String?
    var installDate: Date?
    var isClose: Bool?
    var isInstall: Bool?
    var isLaunch: Bool?
    var isUpgrade: Bool?
    var name: String?
    var sessionLength: Int64?
    var version: String?

    enum CodingKeys: String, CodingKey {
        case closeType
        case id
        case installDate
        case isClose
        case isInstall
        case isLaunch
        case isUpgrade
        case name
        case sessionLength
        case version
    }
}

extension XDMApplication: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = closeType { try container.encode(unwrapped, forKey: .closeType) }
        if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
        if let unwrapped = XDMFormatters.dateToFullDateString(from: installDate) { try container.encode(unwrapped, forKey: .installDate) }
        if let unwrapped = isClose { try container.encode(unwrapped, forKey: .isClose) }
        if let unwrapped = isInstall { try container.encode(unwrapped, forKey: .isInstall) }
        if let unwrapped = isLaunch { try container.encode(unwrapped, forKey: .isLaunch) }
        if let unwrapped = isUpgrade { try container.encode(unwrapped, forKey: .isUpgrade) }
        if let unwrapped = name { try container.encode(unwrapped, forKey: .name) }
        if let unwrapped = sessionLength { try container.encode(unwrapped, forKey: .sessionLength) }
        if let unwrapped = version { try container.encode(unwrapped, forKey: .version) }
    }
}
