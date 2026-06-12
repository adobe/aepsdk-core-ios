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

/// An immutable set of profile attributes to sync to the Adobe Edge Network via
/// `MobileCore.updateProfileAttributes(_:)`.
///
/// Use `ProfileAttributes.Builder` to construct an instance:
/// ```swift
/// let attributes = ProfileAttributes.Builder()
///     .setTimezone(TimeZone(identifier: "America/New_York"))
///     .build()
/// MobileCore.updateProfileAttributes(attributes)
/// ```
@available(iOS 12.0, tvOS 12.0, *)
public struct ProfileAttributes {

    public let timeZone: TimeZone?

    private init(builder: Builder) {
        self.timeZone = builder.timeZone
    }

    /// Fluent builder for `ProfileAttributes`.
    public final class Builder {

        private var timeZone: TimeZone?

        public init() {}

        /// Sets the timezone to sync. The IANA identifier (e.g. `"America/New_York"`) is sent to
        /// the Edge Network. Pass `nil` to leave the attribute unset.
        @discardableResult
        public func setTimezone(_ timeZone: TimeZone?) -> Builder {
            self.timeZone = timeZone
            return self
        }

        /// Builds an immutable `ProfileAttributes` from the values set on this builder.
        public func build() -> ProfileAttributes {
            return ProfileAttributes(builder: self)
        }
    }
}
