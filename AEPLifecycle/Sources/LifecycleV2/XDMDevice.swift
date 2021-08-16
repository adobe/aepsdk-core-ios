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

/// Represents an XDM Device schema
struct XDMDevice: Encodable {
    init() {}

    /// Manufacturer of the device
    var manufacturer: String?

    /// Model of the device
    var model: String?

    /// Model number of the device
    var modelNumber: String?

    /// Screen height of the device
    var screenHeight: Int64?

    /// Screen width of the device
    var screenWidth: Int64?

    /// Device type as represented as a `XDMDeviceType`
    var type: XDMDeviceType?
}
