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

/// An `Error` produced by the `EventHub`
public enum EventHubError: Error {
    case invalidExtensionName
    case duplicateExtensionName
    case extensionInitializationFailure
    case extensionNotRegistered
    case unknown
}

extension EventHubError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidExtensionName:
            return "Extension names must be non-empty."
        case .duplicateExtensionName:
            return "An extension with this name has already been registered."
        case .extensionInitializationFailure:
            return "An extension has failed to initialize."
        case .extensionNotRegistered:
            return "No extension with this type has been registered."
        case .unknown:
            return "An unknown error has occurred."
        }
    }
}
