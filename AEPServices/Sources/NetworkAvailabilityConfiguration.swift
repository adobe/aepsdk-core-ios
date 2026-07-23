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

/// Configuration for optional remote health checks layered on top of device path monitoring.
@objc(AEPNetworkHealthCheckConfiguration)
@objcMembers
public class NetworkHealthCheckConfiguration: NSObject {
    /// HTTPS endpoint used to verify backend reachability (for example `https://10.0.0.42/health`).
    public let endpoint: URL
    /// Request timeout in seconds.
    public let timeout: TimeInterval
    /// How long a successful health check result is reused before re-validating.
    public let cacheTTL: TimeInterval
    /// HTTP status codes treated as healthy. Defaults to 2xx.
    public let expectedStatusCodes: Set<Int>

    @nonobjc
    public init(endpoint: URL,
                timeout: TimeInterval = 3,
                cacheTTL: TimeInterval = 30,
                expectedStatusCodes: Set<Int> = Set(200...299)) {
        self.endpoint = endpoint
        self.timeout = timeout
        self.cacheTTL = cacheTTL
        self.expectedStatusCodes = expectedStatusCodes
    }

    /// Objective-C initializer. `expectedStatusCodes` is an array of HTTP status codes considered healthy (e.g. `@[@200, @204]`).
    @objc(initWithEndpoint:timeout:cacheTTL:expectedStatusCodes:)
    public convenience init(endpoint: URL, timeout: TimeInterval, cacheTTL: TimeInterval, expectedStatusCodes: [Int]) {
        self.init(endpoint: endpoint, timeout: timeout, cacheTTL: cacheTTL, expectedStatusCodes: Set(expectedStatusCodes))
    }
}

/// Top-level configuration for the network availability layer.
@objc(AEPNetworkAvailabilityConfiguration)
@objcMembers
public class NetworkAvailabilityConfiguration: NSObject {
    /// Optional remote health check. When nil, only device path monitoring is used.
    public var healthCheck: NetworkHealthCheckConfiguration?
    /// When `true` and a health check is configured, synchronous availability requires a cached passing health result.
    /// When `false`, synchronous checks use device path only; health checks run asynchronously via `checkNetworkAvailability`.
    public var requireHealthCheckWhenConfigured: Bool

    public init(healthCheck: NetworkHealthCheckConfiguration? = nil,
                requireHealthCheckWhenConfigured: Bool = false) {
        self.healthCheck = healthCheck
        self.requireHealthCheckWhenConfigured = requireHealthCheckWhenConfigured
    }

    /// Objective-C convenience initializer for the "no health check" default configuration.
    @objc
    public convenience override init() {
        self.init(healthCheck: nil, requireHealthCheckWhenConfigured: false)
    }
}
