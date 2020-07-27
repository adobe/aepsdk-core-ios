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
@objc public enum EventType: Int, RawRepresentable, Codable, CustomStringConvertible {
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
    
    private static let stringMapping: [RawValue: EventType] = [
        Constants.acquisition: .acquisition,
        Constants.analytics: .analytics,
        Constants.audienceManager: .audienceManager,
        Constants.campaign: .campaign,
        Constants.configuration: .configuration,
        Constants.custom: .custom,
        Constants.hub: .hub,
        Constants.identity: .identity,
        Constants.lifecycle: .lifecycle,
        Constants.location: .location,
        Constants.pii: .pii,
        Constants.rulesEngine: .rulesEngine,
        Constants.signal: .signal,
        Constants.system: .system,
        Constants.target: .target,
        Constants.userProfile: .userProfile,
        Constants.places: .places,
        Constants.genericTrack: .genericTrack,
        Constants.genericLifecycle: .genericLifecycle,
        Constants.genericIdentity: .genericIdentity,
        Constants.genericPii: .genericPii,
        Constants.genericData: .genericData,
        Constants.wildcard: .wildcard,
    ]
    
    public var description: String {
        return self.rawValue
    }
    
    public var rawValue: RawValue {
        return EventType.stringMapping.first(where: {$0.value == self})?.key ?? Constants.custom
    }
    
    public init?(rawValue: RawValue) {
        if let value = EventType.stringMapping[rawValue] {
            self = value
        }
        
        return nil
    }
}
