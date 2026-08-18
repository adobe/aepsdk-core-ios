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

public protocol Networking {
    /// Initiates an asynchronous network connection to the specified NetworkRequest.url. This API uses `URLRequest.CachePolicy.reloadIgnoringLocalCache`.
    /// - Parameters:
    ///   - networkRequest: the `NetworkRequest` used for this connection
    ///   - completionHandler:Optional completion handler which is called once the `HttpConnection` is available; it can be called from an `HttpConnectionPerformer` if `NetworkServiceOverrider` is enabled.
    ///   In case of a network error, timeout or an unexpected error, the `HttpConnection` is nil
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?)

    /// Returns whether network-bound SDK work should proceed right now. The default implementation checks
    /// device-level path status only (`NWPathMonitor`). Override this in a custom `Networking` conformer
    /// (see: overriding `NetworkService`, `ServiceProvider.shared.networkService`) to implement custom logic —
    /// for example, pinging your own backend's health endpoint instead of relying on device connectivity alone.
    func isInternetAvailable() -> Bool
}

public extension Networking {
    func isInternetAvailable() -> Bool {
        return NetworkPathMonitorProvider.shared.isPathAvailable()
    }
}
