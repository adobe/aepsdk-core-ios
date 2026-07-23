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

/// Describes why network availability was granted or denied.
@objc(AEPNetworkAvailabilityStatus)
public enum NetworkAvailabilityStatus: Int {
    /// Device path is satisfied and optional health check passed (or was not configured).
    case available
    /// Device has no usable network path (airplane mode, no interface, etc.).
    case deviceOffline
    /// Device path is satisfied but the configured health endpoint did not respond successfully.
    case healthCheckFailed
    /// Health check is not configured; availability is based on device path only.
    case pathOnly
}

/// Result returned by asynchronous network availability checks.
@objc(AEPNetworkAvailabilityResult)
@objcMembers
public class NetworkAvailabilityResult: NSObject {
    public let status: NetworkAvailabilityStatus
    public let isAvailable: Bool

    public init(status: NetworkAvailabilityStatus) {
        self.status = status
        self.isAvailable = status == .available || status == .pathOnly
    }
}
