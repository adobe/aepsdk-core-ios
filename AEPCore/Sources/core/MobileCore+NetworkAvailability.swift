/*
 Copyright 2026 Adobe. All rights reserved.
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

public extension MobileCore {
    /// Returns whether network-bound SDK work should proceed right now.
    /// Backed by `NWPathMonitor` via the registered `Networking` service.
    @objc static func isNetworkAvailable() -> Bool {
        ServiceProvider.shared.networkService.isNetworkAvailable()
    }

}
