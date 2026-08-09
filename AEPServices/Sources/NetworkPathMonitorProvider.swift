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
import Network

/// Default device path check backed by `NWPathMonitor`, used by `Networking`'s default
/// `isNetworkAvailable()` implementation. A single shared, long-lived monitor is used (rather than
/// creating a new one per call) so `currentPath` stays continuously up to date.
final class NetworkPathMonitorProvider {
    static let shared = NetworkPathMonitorProvider()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.adobe.networkPathMonitor.queue")

    private init() {
        monitor.start(queue: queue)
    }

    func isPathAvailable() -> Bool {
        // Test seam: when injected, overrides the real NWPathMonitor result so unit tests
        // can exercise satisfied/unsatisfied/concurrent paths deterministically without a
        // live network. Must be nil in all production code paths.
        if let provider = pathStatusProvider {
            return provider()
        }
        return queue.sync {
            monitor.currentPath.status == .satisfied
        }
    }

    func connectionInfo() -> NetworkConnectionInfo {
        if let provider = connectionInfoProvider {
            return provider()
        }
        return queue.sync {
            let path = monitor.currentPath
            let available = path.status == .satisfied

            let interfaceType: NetworkConnectionInfo.InterfaceType
            if !available {
                interfaceType = .unknown
            } else if path.usesInterfaceType(.wifi) {
                interfaceType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                interfaceType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                interfaceType = .wiredEthernet
            } else {
                interfaceType = .other
            }

            let isConstrained: Bool
            if #available(iOS 13.0, *) {
                isConstrained = path.isConstrained
            } else {
                isConstrained = false
            }
            return NetworkConnectionInfo(
                isAvailable: available,
                interfaceType: interfaceType,
                isConstrained: isConstrained,
                isExpensive: path.isExpensive
            )
        }
    }

    // MARK: - Test support

    /// Closure injected by unit tests to supply a deterministic path status.
    /// Always `nil` in production; tests set and reset this in `setUp`/`tearDown`.
    var pathStatusProvider: (() -> Bool)? = nil

    /// Closure injected by unit tests to supply a deterministic `NetworkConnectionInfo`.
    /// Always `nil` in production; tests set and reset this in `setUp`/`tearDown`.
    var connectionInfoProvider: (() -> NetworkConnectionInfo)? = nil
}
