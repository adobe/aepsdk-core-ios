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

/// A type which represents a Experience Cloud ID (ECID)
struct ECID: Equatable, Codable, Hashable, CustomStringConvertible {
    var description: String {
        return ecidString
    }

    /// Representation of the ECID as a `String`
    let ecidString: String

    /// Generates a new ECID
    init() {
        let uuidBytes = Mirror(reflecting: UUID().uuid).children.map { $0.value }
        let msb = uuidBytes[..<8].reduce(Int64(0)) { base, next in
            (base << 8) | Int64((next as? UInt8)! & 0xFF)
        }
        let lsb = uuidBytes[8...].reduce(Int64(0)) { base, next in
            (base << 8) | Int64((next as? UInt8)! & 0xFF)
        }

        let correctedMsb = String(msb < 0 ? -msb : msb)
        let correctedLsb = String(lsb < 0 ? -lsb : lsb)

        ecidString = "\(String(repeating: "0", count: 19 - correctedMsb.count))\(correctedMsb)\(String(repeating: "0", count: 19 - correctedLsb.count))\(correctedLsb)"
    }
}
