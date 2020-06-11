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

/// A type which represents a Experience Cloud ID (MID)
struct MID:  Equatable, Codable, Hashable, CustomStringConvertible {
    var description: String {
        return midString
    }
    
    /// Representation of the MID as a `String`
    let midString: String
    
    /// Generates a new MID
    init() {
        let uuid = UUID()
        let uuidBytes = uuid.uuid
        
        var msb: Int64 = 0
        var lsb: Int64 = 0
        
        msb = (msb << 8) | Int64((uuidBytes.0 & 0xff))
        msb = (msb << 8) | Int64((uuidBytes.1 & 0xff))
        msb = (msb << 8) | Int64((uuidBytes.2 & 0xff))
        msb = (msb << 8) | Int64((uuidBytes.3 & 0xff))
        msb = (msb << 8) | Int64((uuidBytes.4 & 0xff))
        msb = (msb << 8) | Int64((uuidBytes.5 & 0xff))
        msb = (msb << 8) | Int64((uuidBytes.6 & 0xff))
        msb = (msb << 8) | Int64((uuidBytes.7 & 0xff))
        
        lsb = (lsb << 8) | Int64((uuidBytes.8 & 0xff))
        lsb = (lsb << 8) | Int64((uuidBytes.9 & 0xff))
        lsb = (lsb << 8) | Int64((uuidBytes.10 & 0xff))
        lsb = (lsb << 8) | Int64((uuidBytes.11 & 0xff))
        lsb = (lsb << 8) | Int64((uuidBytes.12 & 0xff))
        lsb = (lsb << 8) | Int64((uuidBytes.13 & 0xff))
        lsb = (lsb << 8) | Int64((uuidBytes.14 & 0xff))
        lsb = (lsb << 8) | Int64((uuidBytes.15 & 0xff))
        
        var correctedMsb = String(msb < 0 ? -msb : msb)
        while correctedMsb.count < 19 {
            correctedMsb = "0" + correctedMsb
        }
        
        var correctedLsb = String(lsb < 0 ? -lsb : lsb)
        while correctedLsb.count < 19 {
            correctedLsb = "0" + correctedLsb
        }
        
        midString = "\(correctedMsb)\(correctedLsb)"
    }
    
}
