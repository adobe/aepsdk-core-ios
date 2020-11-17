//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//
import Foundation

enum XDMAuthenticationState: String, Codable {
    case ambiguous
    case authenticated
    case loggedOut

    static func authStateFromMobileAuthState(authState: MobileVisitorAuthenticationState?) -> XDMAuthenticationState {
        switch authState {
        case .authenticated:
            return .authenticated
        case .loggedOut:
            return .loggedOut
        default:
            return .ambiguous
        }
    }
}

/// Defines a map containing a set of end user identities, keyed on either namespace integration code or the namespace ID of the identity.
/// Within each namespace, the identity is unique. The values of the map are an array, meaning that more than one identity of each namespace may be carried.
struct IdentityMap: Equatable {
    private var items: [String: [IdentityItem]] = [:]

    /// Adds an `IdentityItem` to this map. If an item is added which shares the same `namespace` and `id` as an item
    /// already in the map, then the new item replaces the existing item.
    /// - Parameters:
    ///   - namespace: The namespace for this identity
    ///   - id: Identity of the consumer in the related namespace.
    ///   - authenticationState: The state this identity is authenticated as for this observed ExperienceEvent.
    ///   - primary: Indicates if this identity is the preferred identity. It is used as a hint to help systems better organize how identities are queried.
    mutating func addItem(namespace: String,
                          id: String,
                          authenticationState: XDMAuthenticationState? = nil,
                          primary: Bool? = nil) {
        let item = IdentityItem(id: id,
                                authenticationState: authenticationState, primary: primary)

        if var namespaceItems = items[namespace] {
            if let index = namespaceItems.firstIndex(of: item) {
                namespaceItems[index] = item
            } else {
                namespaceItems.append(item)
            }
            items[namespace] = namespaceItems
        } else {
            items[namespace] = [item]
        }
    }

    /// Get the array of `IdentityItem`(s) for the given namespace.
    /// - Parameter namespace: the namespace of items to retrieve
    /// - Returns: An array of `IdentityItem` for the given `namespace` or nil if this `IdentityMap` does not contain the `namespace`.
    func getItemsFor(namespace: String) -> [IdentityItem]? {
        return items[namespace]
    }
}

extension IdentityMap: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(items)
    }
}

extension IdentityMap: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let identityItems = try? container.decode([String: [IdentityItem]].self) {
            items = identityItems
        }
    }
}

/// Identity is used to clearly distinguish people that are interacting with digital experiences.
struct IdentityItem: Codable {
    let id: String?
    let authenticationState: XDMAuthenticationState?
    let primary: Bool?
}

/// Defines two `IdentityItem` objects are equal if they have the same `id`.
extension IdentityItem: Equatable {
    static func == (lhs: IdentityItem, rhs: IdentityItem) -> Bool {
        return lhs.id == rhs.id
    }
}
