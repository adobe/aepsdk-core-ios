/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Fluent builder for syncing profile attributes to the Adobe Edge Network.
/// Chain setters then call `.send()` to dispatch all accumulated attributes as one Edge event:
/// ```swift
/// MobileCore.updateProfileAttributes().setTimezone(tz).send()
/// ```
@available(iOS 12.0, tvOS 12.0, *)
public final class ProfileAttributesBuilder {

    private var timezone: TimeZone?

    public init() {}

    /// Sets the timezone to sync. Chain with `.send()` to dispatch.
    /// - Parameter value: The `TimeZone` to sync. Must be supplied explicitly by the caller.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func setTimezone(_ value: TimeZone) -> Self {
        self.timezone = value
        return self
    }

    /// Dispatches all accumulated profile attributes to the Edge Network.
    public func send() {
        MobileCore.updateProfileAttributes(build())
    }

    func build() -> ProfileAttributes {
        ProfileAttributes(timezone: timezone)
    }
}
