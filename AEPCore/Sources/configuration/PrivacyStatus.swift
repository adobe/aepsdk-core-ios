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

/// An enum type representing the possible opt-out and privacy settings.
@objc(AEPPrivacyStatus)
public enum PrivacyStatus: Int, RawRepresentable, Codable {
    case optedIn = 0
    case optedOut = 1
    case unknown = 2

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .optedIn:
            return ConfigurationConstants.Privacy.OPT_IN
        case .optedOut:
            return ConfigurationConstants.Privacy.OPT_OUT
        case .unknown:
            return ConfigurationConstants.Privacy.UNKNOWN
        }
    }

    /// Initializes the appropriate `PrivacyStatus` enum for the given `rawValue`
    /// - Parameter rawValue: a `RawValue` representation of a `PrivacyStatus` enum
    public init?(rawValue: RawValue) {
        switch rawValue {
        case ConfigurationConstants.Privacy.OPT_IN:
            self = .optedIn
        case ConfigurationConstants.Privacy.OPT_OUT:
            self = .optedOut
        default:
            self = .unknown
        }
    }
}
