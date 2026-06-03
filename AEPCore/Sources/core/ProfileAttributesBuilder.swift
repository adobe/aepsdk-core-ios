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
///
/// ```swift
/// MobileCore.updateProfileAttributes().setTimezone("America/New_York")
/// ```
public final class ProfileAttributesBuilder {

    public init() {}

    /// Syncs the given IANA timezone identifier to the Edge Network immediately.
    /// - Parameter timezone: An IANA timezone identifier string (e.g. `"America/New_York"`).
    /// - Returns: `self` for chaining.
    @discardableResult
    public func setTimezone(_ timezone: String) -> Self {
        guard !timezone.isEmpty else {
            return self
        }
        let event = Event(name: CoreConstants.EventNames.UPDATE_PROFILE_ATTRIBUTES,
                          type: EventType.genericProfileAttributes,
                          source: EventSource.requestContent,
                          data: [CoreConstants.ProfileAttributeKeys.TIMEZONE: timezone])
        MobileCore.dispatch(event: event)
        return self
    }
}
