//
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

/// An identifier for an SDK instance.
enum SDKInstanceIdentifier: Hashable {
    private static let IDENTIFIER_MAX_LENGTH = 100
    private static let IDENTIFIER_PATTERN = "[^A-Za-z0-9._-]+"
    private static let DEFAULT_STRING = "aep-default-instance"
    
    case `default`
    case id(String)
    
    /// Creates an instance of `SDKInstanceIdentifier`. 
    /// If the given `id` is either too long or contains invalid characters then `nil` is returned.
    /// - Parameter id: the identifier string for an SDK instance.
    init?(id: String) {
        if id == SDKInstanceIdentifier.DEFAULT_STRING {
            self = .default
        } else if SDKInstanceIdentifier.isValidFilename(id) {
            self = .id(id)
        } else {
            return nil
        }
    }

    /// The SDK instance identifier string.
    /// Returns nil for the default instance.
    var id: String? {
        switch self {
        case .default:
            return nil
        case .id(let id):
            return id
        }
    }

    var description: String {
        id ?? SDKInstanceIdentifier.DEFAULT_STRING
    }
    
    /// Validates the given `identifier` to ensure it is safe to use as a filename.
    /// - Parameter identifier: The instance identifier string to validate.
    /// - Returns: Returns true if the given `identifier` is safe to use in a filename.
    private static func isValidFilename(_ identifier: String) -> Bool {
        if identifier.isEmpty {
            return false
        }
        
        if identifier.count > SDKInstanceIdentifier.IDENTIFIER_MAX_LENGTH {
            return false
        }
        
        return identifier.range(of: IDENTIFIER_PATTERN, options: .regularExpression) == nil
    }
}

extension String {
    
    /// Attaches the `instance` to this `String`.
    /// If the given `instance` is `SDKInstanceIdentifier.default`, then this String is returned unmodified.
    /// - Parameter instance: The `SDKInstanceIdentifier` to attach to this `String`.
    /// - Returns: A string with the SDK Instance identifier attached.
    func instanceAwareName(for instance: SDKInstanceIdentifier) -> String {
        guard let instanceId = instance.id else {
            return self
        }
        return "\(self)-\(instanceId)"
    }
    
    /// Joins the `instance` to this `String` delimited by a dot '.' for use in filenames.
    /// If the given `instance` is `SDKInstanceIdentifier.default`, then this String is returned unmodifed.
    /// - Parameter instance: iThe `SDKInstanceIdentifier` to join to this `String`.
    /// - Returns: A file safe string joined with the SDK Instance identifier.
    func instanceAwareFilename(for instance: SDKInstanceIdentifier) -> String {
        guard let instanceId = instance.id else {
            return self
        }
        return "aep.\(instanceId).\(self)"
    }
}
