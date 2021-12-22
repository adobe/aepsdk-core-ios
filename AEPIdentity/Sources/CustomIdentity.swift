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

/// CustomIdentity contains identifier origin, identifier type, identifier value and authentication state.
class CustomIdentity: Identifiable, Codable {
    public var origin: String?
    public var type: String?
    public var identifier: String?
    public var authenticationState: MobileVisitorAuthenticationState

    /// Creates a new `CustomIdentity` with the given parameters
    /// - Parameters:
    ///   - origin: Origin of the identifier
    ///   - type: Type of the identifier
    ///   - identifier: The identifier
    ///   - authenticationState: Authentication state for the identifier
    init(origin: String?, type: String?, identifier: String?, authenticationState: MobileVisitorAuthenticationState) {
        self.origin = origin
        self.type = type
        self.identifier = identifier
        self.authenticationState = authenticationState
    }

    init(dict: [String: Any]) {
        self.type = dict[CodingKeys.type.rawValue] as? String
        self.origin = dict[CodingKeys.origin.rawValue] as? String
        self.identifier = dict[CodingKeys.identifier.rawValue] as? String
        let rawState = dict[CodingKeys.authenticationState.rawValue] as? Int
        self.authenticationState = MobileVisitorAuthenticationState(rawValue: rawState ?? MobileVisitorAuthenticationState.unknown.rawValue) ?? .unknown
    }

    enum CodingKeys: String, CodingKey {
        case origin = "id_origin"
        case type = "id_type"
        case identifier = "id"
        case authenticationState = "authentication_state"
    }
}

extension CustomIdentity: Equatable {
    public static func == (lhs: CustomIdentity, rhs: CustomIdentity) -> Bool {
        return lhs.type == rhs.type
    }
}
