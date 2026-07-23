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

/// Public Mobile Core APIs for network availability checks used by apps and extensions.
@objc
public extension MobileCore {
    /// Configures optional remote health checks layered on top of device path monitoring.
    /// - Parameter configuration: Health endpoint and gating behavior.
    @objc(setNetworkAvailabilityConfiguration:)
    static func setNetworkAvailabilityConfiguration(_ configuration: NetworkAvailabilityConfiguration) {
        networkAvailabilityService.configuration = configuration
    }

    /// Performs a fresh availability evaluation, including an optional remote health check.
    /// - Parameter completion: Called on an arbitrary queue with the availability result.
    @objc(checkNetworkAvailabilityWithCompletion:)
    static func checkNetworkAvailability(completion: @escaping (NetworkAvailabilityResult) -> Void) {
        networkAvailabilityService.checkNetworkAvailability(completion: completion)
    }

    /// Replaces the entire availability implementation. Use for advanced customer integrations.
    /// - Parameter provider: Custom `NetworkAvailabilityProviding` implementation.
    @objc(setNetworkAvailabilityProvider:)
    static func setNetworkAvailabilityProvider(_ provider: NetworkAvailabilityProviding) {
        ServiceProvider.shared.networkAvailabilityService = provider
    }

    /// Restores the default network availability service and clears cached health results.
    @objc(resetNetworkAvailabilityProvider)
    static func resetNetworkAvailabilityProvider() {
        ServiceProvider.shared.resetNetworkAvailabilityService()
    }

    /// Returns a fast synchronous snapshot of whether network-bound SDK work should proceed.
    /// Uses device path monitoring and, when configured with `requireHealthCheckWhenConfigured`, a cached health result.
    @objc(isNetworkAvailable)
    static func isNetworkAvailable() -> Bool {
        return ServiceProvider.shared.networkAvailabilityService.isNetworkAvailable()
    }

    private static var networkAvailabilityService: NetworkAvailabilityProviding {
        return ServiceProvider.shared.networkAvailabilityService
    }
}
