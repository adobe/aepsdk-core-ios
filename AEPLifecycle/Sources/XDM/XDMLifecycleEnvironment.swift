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

/// Represents the Lifecycle Environment schema
struct XDMLifecycleEnvironment: Encodable {
    init() {}

    var carrier: String?
    var language: XDMLifecycleLanguage?
    var operatingSystemVendor: String?
    var operatingSystem: String?
    var operatingSystemVersion: String?
    var type: XDMEnvironmentType?

    enum CodingKeys: String, CodingKey {
        case carrier
        case language = "_dc"
        case operatingSystemVendor
        case operatingSystem
        case operatingSystemVersion
        case type
    }

}

/// Helper struct to encode the language properly in the `XDMLifecycleEnvironment`
struct XDMLifecycleLanguage: Encodable {
    let language: String?
}
