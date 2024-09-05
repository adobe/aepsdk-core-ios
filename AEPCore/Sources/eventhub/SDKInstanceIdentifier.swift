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
public enum SDKInstanceIdentifier: Hashable {
    case `default`
    case id(String)
    
    
    /// Creates an instance of `SDKInstanceIdentifier`. 
    /// If the given `id` is either too long or contains invalid characters then `nil` is returned.
    /// - Parameter id: the identifier string for an SDK instance.
    init?(id: String) {
        if id == "default-instance" {
            self = .default
        } else if !SDKInstanceIdentifier.isValidFilename(id) {
            return nil
        } else {
            self = .id(id)
        }
    }

    var id: String? {
        switch self {
        case .default:
            return nil
        case .id(let id):
            return id
        }
    }

    var description: String {
        id ?? "default-instance"
    }
    
    
    /// Validates the given `identifier` to ensure it is safe to use as a filename.
    /// - Parameter identifier: The instance identifier string to validate.
    /// - Returns: Returns true if the given `identifier` is safe to use in a filename.
    private static func isValidFilename(_ identifier: String) -> Bool {
        if identifier.isEmpty {
            return false
        }
        
        if identifier.count > 150 {
            return false
        }
        
        let invalidCharset = CharacterSet(charactersIn: ":\\/")
            .union(.illegalCharacters)
            .union(.whitespacesAndNewlines)
            .union(.controlCharacters)
            .union(.symbols)
        return identifier.rangeOfCharacter(from: invalidCharset) == nil
    }
}

public extension String {
    func instanceAwareName(for instance: SDKInstanceIdentifier) -> String {
        guard let instanceId = instance.id else {
            return self
        }
        return "\(self)-\(instanceId)"
    }
}
