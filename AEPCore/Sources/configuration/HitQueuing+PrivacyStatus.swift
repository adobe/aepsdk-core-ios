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

import AEPServices
import Foundation

public extension HitQueuing {
    /// Based on `status` determines if we should continue processing hits or if we should suspend processing and clear hits
    /// - Parameter status: the current privacy status
    func handlePrivacyChange(status: PrivacyStatus) {
        switch status {
        case .optedIn:
            beginProcessing()
        case .optedOut:
            suspend()
            clear()
        case .unknown:
            suspend()
        @unknown default:
            suspend()
        }
    }
}
