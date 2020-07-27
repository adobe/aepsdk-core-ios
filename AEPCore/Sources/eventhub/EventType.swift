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

/// Represents the type of an event
@objc public enum EventType: Int, RawRepresentable, Codable {
    public typealias RawValue = String
    
    case acquisition
    case analytics
    case audienceManager
    case campaign
    case configuration
    case custom
    case hub
    case identity
    case lifecycle
    case location
    case pii
    case rulesEngine
    case signal
    case system
    case target
    case userProfile
    case places
    case genericTrack
    case genericLifecycle
    case genericIdentity
    case genericPii
    case genericData
    case wildcard
    
    public var rawValue: RawValue {
        switch self {
        case .acquisition:
            return Constants.acquisition
        case .analytics:
            return Constants.analytics
        case .audienceManager:
            return Constants.audienceManager
        case .campaign:
            return Constants.campaign
        case .configuration:
            return Constants.configuration
        case .custom:
            return Constants.custom
        case .hub:
            return Constants.hub
        case .identity:
            return Constants.identity
        case .lifecycle:
            return Constants.lifecycle
        case .location:
            return Constants.location
        case .pii:
            return Constants.pii
        case .rulesEngine:
            return Constants.rulesEngine
        case .signal:
            return Constants.signal
        case .system:
            return Constants.system
        case .target:
            return Constants.target
        case .userProfile:
            return Constants.userProfile
        case .places:
            return Constants.places
        case .genericTrack:
            return Constants.genericTrack
        case .genericLifecycle:
            return Constants.genericLifecycle
        case .genericIdentity:
            return Constants.genericIdentity
        case .genericPii:
            return Constants.genericPii
        case .genericData:
            return Constants.genericData
        case .wildcard:
            return Constants.wildcard
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
            case Constants.acquisition:
                self = .acquisition
            case Constants.analytics:
                self = .analytics
            case Constants.audienceManager:
                self = .audienceManager
            case Constants.campaign:
                self = .campaign
            case Constants.configuration:
                self = .configuration
            case Constants.custom:
                self = .custom
            case Constants.hub:
                self = .hub
            case Constants.identity:
                self = .identity
            case Constants.lifecycle:
                self = .lifecycle
            case Constants.location:
                self = .location
            case Constants.pii:
                self = .pii
            case Constants.rulesEngine:
                self = .rulesEngine
            case Constants.signal:
                self = .signal
            case Constants.system:
                self = .system
            case Constants.target:
                self = .target
            case Constants.userProfile:
                self = .userProfile
            case Constants.places:
                self = .places
            case Constants.genericTrack:
                self = .genericTrack
            case Constants.genericLifecycle:
                self = .genericLifecycle
            case Constants.genericIdentity:
                self = .genericIdentity
            case Constants.genericPii:
                self = .genericPii
            case Constants.genericData:
                self = .genericData
            case Constants.wildcard:
                self = .wildcard
        default:
            self = .custom
        }
    }
    
    private struct Constants {
        static let acquisition = "com.adobe.eventType.acquisition"
        static let analytics = "com.adobe.eventType.analytics"
        static let audienceManager = "com.adobe.eventType.audienceManager"
        static let campaign = "com.adobe.eventType.campaign"
        static let configuration = "com.adobe.eventType.configuration"
        static let custom = "com.adobe.eventType.custom"
        static let hub = "com.adobe.eventType.hub"
        static let identity = "com.adobe.eventType.identity"
        static let lifecycle = "com.adobe.eventType.lifecycle"
        static let location = "com.adobe.eventType.location"
        static let pii = "com.adobe.eventType.pii"
        static let rulesEngine = "com.adobe.eventType.rulesEngine"
        static let signal = "com.adobe.eventType.signal"
        static let system = "com.adobe.eventType.system"
        static let target = "com.adobe.eventType.target"
        static let userProfile = "com.adobe.eventType.userProfile"
        static let places = "com.adobe.eventType.places"
        static let genericTrack = "com.adobe.eventType.generic.track"
        static let genericLifecycle = "com.adobe.eventType.generic.lifecycle"
        static let genericIdentity = "com.adobe.eventType.generic.identity"
        static let genericPii = "com.adobe.eventType.generic.pii"
        static let genericData = "com.adobe.eventType.generic.data"
        static let wildcard = "com.adobe.eventType._wildcard_"
    }
}
