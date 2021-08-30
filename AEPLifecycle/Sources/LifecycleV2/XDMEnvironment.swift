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

/// Represents the Environment schema
struct XDMEnvironment: Encodable {
    init() {}

    /// A mobile network carrier or MNO, also known as a wireless service provider.
    var carrier: String?

    /// The language of the environment to represent the user's linguistic, geographical, or cultural preferences for data presentation.
    var language: XDMLanguage?

    /// The name of the operating system used when the observation was made.
    var operatingSystem: String?

    /// The full version identifier for the operating system used when the observation was made.
    var operatingSystemVersion: String?

    /// The type of the application environment.
    var type: XDMEnvironmentType?

    enum CodingKeys: String, CodingKey {
        case carrier
        case language = "_dc"
        case operatingSystem
        case operatingSystemVersion
        case type
    }
}
