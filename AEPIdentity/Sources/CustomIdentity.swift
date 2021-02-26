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
public class CustomIdentity: Identifiable, Codable {
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
    public init(origin: String?, type: String?, identifier: String?, authenticationState: MobileVisitorAuthenticationState) {
        self.origin = origin
        self.type = type
        self.identifier = identifier
        self.authenticationState = authenticationState
    }

    enum CodingKeys: String, CodingKey {
        case origin = "id_origin"
        case type = "id_type"
        case identifier = "id"
        case authenticationState = "authentication_state"
    }

    /// These only exist to support the case where a `CustomIdentity` may have been saved with incorrect keys in a previous SDK version
    /// https://github.com/adobe/aepsdk-core-ios/issues/433
    private enum MigrationCodingKeys: String, CodingKey {
        case origin = "id.origin"
        case type = "id.type"
        case identifier = "id"
        case authenticationState = "authentication.state"
    }

    public required init(from decoder: Decoder) throws {
        do {
            // Attempt to decode using the correct keys
            let values = try decoder.container(keyedBy: CodingKeys.self)
            origin = try? values.decode(String.self, forKey: .origin)
            type = try? values.decode(String.self, forKey: .type)
            identifier = try? values.decode(String.self, forKey: .identifier)
            authenticationState = try values.decode(MobileVisitorAuthenticationState.self, forKey: .authenticationState)
        } catch _ {
            // Decoding failed using correct keys, attempt to decode using migration keys
            let values = try decoder.container(keyedBy: MigrationCodingKeys.self)
            origin = try? values.decode(String.self, forKey: .origin)
            type = try? values.decode(String.self, forKey: .type)
            identifier = try? values.decode(String.self, forKey: .identifier)
            authenticationState = try values.decode(MobileVisitorAuthenticationState.self, forKey: .authenticationState)
        }
    }
}

extension CustomIdentity: Equatable {
    public static func == (lhs: CustomIdentity, rhs: CustomIdentity) -> Bool {
        return lhs.type == rhs.type
    }
}
