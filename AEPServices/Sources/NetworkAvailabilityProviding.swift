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

/// Pluggable device-level path check (for example `NWPathMonitor`).
@objc(AEPNetworkPathAvailabilityProviding)
public protocol NetworkPathAvailabilityProviding: AnyObject {
    @objc(isPathAvailable)
    func isPathAvailable() -> Bool
}

/// Pluggable remote health endpoint check.
@objc(AEPNetworkHealthCheckProviding)
public protocol NetworkHealthCheckProviding: AnyObject {
    @objc(performHealthCheckWithCompletion:)
    func performHealthCheck(completion: @escaping (Bool) -> Void)
}

/// Full network availability surface used by Mobile Core, extensions, and app code.
@objc(AEPNetworkAvailabilityProviding)
public protocol NetworkAvailabilityProviding: AnyObject {
    var configuration: NetworkAvailabilityConfiguration { get set }

    /// Fast synchronous snapshot used to gate network-bound SDK work (for example Edge dispatch).
    @objc(isNetworkAvailable)
    func isNetworkAvailable() -> Bool

    /// Performs a fresh availability evaluation, including an optional health check.
    @objc(checkNetworkAvailabilityWithCompletion:)
    func checkNetworkAvailability(completion: @escaping (NetworkAvailabilityResult) -> Void)

    /// Replace the built-in device path provider.
    @objc(setPathProvider:)
    func setPathProvider(_ provider: NetworkPathAvailabilityProviding)

    /// Replace or remove the remote health check provider. Pass `nil` to use the default HTTP provider from configuration.
    @objc(setHealthCheckProvider:)
    func setHealthCheckProvider(_ provider: NetworkHealthCheckProviding?)

    /// Restore default providers and clear cached health results.
    @objc(resetToDefaults)
    func resetToDefaults()
}
