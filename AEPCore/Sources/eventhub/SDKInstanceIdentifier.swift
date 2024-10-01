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
    static let DEFAULT_INSTANCE_NAME = "aep-default-instance"
    static let `default` = id(DEFAULT_INSTANCE_NAME)
    
    case id(String)
    
    /// Creates an instance of `SDKInstanceIdentifier`. 
    /// If the given `id` is either too long or contains invalid characters then `nil` is returned.
    /// - Parameter id: the identifier string for an SDK instance.
    init?(id: String) {
        guard SDKInstanceIdentifier.isValidFilename(id) else { return nil }
        
        if id == SDKInstanceIdentifier.DEFAULT_INSTANCE_NAME {
            self = .default
        } else {
            self = .id(id)
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
        id ?? SDKInstanceIdentifier.DEFAULT_INSTANCE_NAME
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
    
    /// Append the SDK instance identifer to this String for use in lables such as in logging or dispatch queues..
    /// If the given identifier is `SDKInstanceIdentifier.default`, then this String is returned unmodified.
    /// - Parameter identifier: the `SDKInstanceIdentifier` to append to this `String`.
    /// - Returns: A string with the SDK Instance identifier attached.
    func instanceAwareLabel(for identifier: SDKInstanceIdentifier) -> String {
        guard let instanceId = identifier.id else {
            return self
        }
        return "\(self)-\(instanceId)"
    }
    
    /// Adds the SDK instance identifier to this String for use in filenames.
    /// If the given identifier is `SDKInstanceIdentifier.default`, then this String is returned unmodifed.
    /// - Parameter identifier: the `SDKInstanceIdentifier` to join to this `String`.
    /// - Returns: A file safe string joined with the SDK Instance identifier.
    func instanceAwareFilename(for identifier: SDKInstanceIdentifier) -> String {
        guard let instanceId = identifier.id else {
            return self
        }
        return "aep.\(instanceId).\(self)"
    }
}

extension DispatchQueue {
    /// Initializes a new `DispatchQueue` with a label that is specific to the provided `SDKInstanceIdentifier`.
    ///
    /// - Parameters:
    ///   - identifier: The `SDKInstanceIdentifier` used to make the queue label instance-specific.
    ///   - label: A base label string, to which the identifier will be appended to create a unique queue label.
    convenience init(for identifier: SDKInstanceIdentifier, label: String) {
        let label = label.instanceAwareLabel(for: identifier)
        self.init(label: label)
    }
}
