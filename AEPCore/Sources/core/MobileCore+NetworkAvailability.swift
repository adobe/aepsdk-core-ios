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

/// Public Mobile Core API for network availability checks used by apps and extensions.
///
/// There is no dedicated configuration API. If you need custom availability logic (for example, pinging your
/// own backend's health endpoint instead of relying on device connectivity alone), implement your own
/// `Networking` conformer, override `isNetworkAvailable()`, and register it via
/// `ServiceProvider.shared.networkService = MyCustomNetworkOverride()` — the same, already-documented override
/// point used for customizing HTTP transport (e.g. certificate pinning, corporate proxies).
@objc
public extension MobileCore {
    /// Returns whether network-bound SDK work should proceed right now. Delegates to
    /// `ServiceProvider.shared.networkService.isNetworkAvailable()`, so overriding `networkService` overrides
    /// this too.
    @objc(isNetworkAvailable)
    static func isNetworkAvailable() -> Bool {
        return ServiceProvider.shared.networkService.isNetworkAvailable()
    }
}
