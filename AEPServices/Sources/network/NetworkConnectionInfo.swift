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

import Foundation

/// A point-in-time snapshot of the device's network connection state, returned by
/// `Networking.networkConnectionInfo()`.
///
/// All properties are read from `NWPathMonitor.currentPath` synchronously — no HTTP request
/// is made and the call returns immediately.
///
/// Usage in an AEP extension:
/// ```swift
/// let info = ServiceProvider.shared.networkService.networkConnectionInfo()
/// guard info.isAvailable else { return }
///
/// if info.isConstrained {
///     sendMinimalPayload()   // Low Data Mode: respect the user's data preference
/// } else if info.isExpensive {
///     scheduleForLater()     // Cellular / hotspot: defer non-critical work
/// } else {
///     sendFullPayload()      // Wi-Fi / wired: full payload
/// }
/// ```
public struct NetworkConnectionInfo {

    // MARK: - Nested types

    /// The dominant network interface type on the current path.
    public enum InterfaceType {
        /// Wi-Fi (802.11).
        case wifi
        /// Cellular (LTE, 5G, etc.).
        case cellular
        /// Wired Ethernet.
        case wiredEthernet
        /// Another interface type (loopback, VPN, etc.).
        case other
        /// Path is unsatisfied or the monitor has not yet delivered its first update.
        case unknown
    }

    // MARK: - Properties

    /// `true` when the device has a usable network path — equivalent to `isNetworkAvailable()`.
    public let isAvailable: Bool

    /// Dominant interface type active on the current path.
    ///
    /// When `isAvailable` is `false` this returns `.unknown`.
    public let interfaceType: InterfaceType

    /// `true` when the user has enabled **Low Data Mode** (iOS Settings → Wi-Fi or Cellular).
    ///
    /// Respect this the same way `URLSessionConfiguration.allowsConstrainedNetworkAccess` does:
    /// skip prefetch, send minimal payloads, defer analytics batches.
    public let isConstrained: Bool

    /// `true` when the path uses a metered link — cellular, a Personal Hotspot, or similar.
    ///
    /// Use this to decide whether to defer large uploads or analytics batches.
    public let isExpensive: Bool
}
