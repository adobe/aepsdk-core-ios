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

import AEPServices
import Foundation

/// Represents an XDM Application schema
struct XDMApplication {
    init() {}

    /// Close type of the application
    var closeType: XDMCloseType?

    /// Identifier of the application
    var id: String?

    /// Indicates of this is a close event
    var isClose: Bool?

    /// Indicates of this is a install event
    var isInstall: Bool?

    /// Indicates of this is a launch event
    var isLaunch: Bool?

    /// Indicates of this is a update event
    var isUpgrade: Bool?

    /// Name of the application
    var name: String?

    /// Session length of this launch
    var sessionLength: Int64?

    /// Version of the application
    var version: String?

    /// The language being used by the application to represent the user's linguistic, geographical, or cultural preferences for data presentation.
    var language: XDMLanguage?

    enum CodingKeys: String, CodingKey {
        case closeType
        case id
        case isClose
        case isInstall
        case isLaunch
        case isUpgrade
        case name
        case sessionLength
        case version
        case language = "_dc"
    }
}

extension XDMApplication: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = closeType { try container.encode(unwrapped, forKey: .closeType) }
        if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
        if let unwrapped = isClose { try container.encode(unwrapped, forKey: .isClose) }
        if let unwrapped = isInstall { try container.encode(unwrapped, forKey: .isInstall) }
        if let unwrapped = isLaunch { try container.encode(unwrapped, forKey: .isLaunch) }
        if let unwrapped = isUpgrade { try container.encode(unwrapped, forKey: .isUpgrade) }
        if let unwrapped = name { try container.encode(unwrapped, forKey: .name) }
        if let unwrapped = sessionLength { try container.encode(unwrapped, forKey: .sessionLength) }
        if let unwrapped = version { try container.encode(unwrapped, forKey: .version) }
        if let unwrapped = language { try container.encode(unwrapped, forKey: .language) }
    }
}
