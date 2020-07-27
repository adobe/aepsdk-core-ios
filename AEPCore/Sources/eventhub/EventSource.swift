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

/// Represents the source of which an event originates from
@objc public enum EventSource: Int, RawRepresentable, Codable, CustomStringConvertible {
    public typealias RawValue = String
    
    case none
    case os
    case requestContent
    case requestIdentity
    case requestProfile
    case requestReset
    case responseContent
    case responseIdentity
    case responseProfile
    case sharedState
    case wildcard
    
    private struct Constants {
        static let none = "com.adobe.eventSource.none"
        static let os = "com.adobe.eventSource.os"
        static let requestContent = "com.adobe.eventSource.requestContent"
        static let requestIdentity = "com.adobe.eventSource.requestIdentity"
        static let requestProfile = "com.adobe.eventSource.requestProfile"
        static let requestReset = "com.adobe.eventSource.requestReset"
        static let responseContent = "com.adobe.eventSource.responseContent"
        static let responseIdentity = "com.adobe.eventSource.responseIdentity"
        static let responseProfile = "com.adobe.eventSource.responseProfile"
        static let sharedState = "com.adobe.eventSource.sharedState"
        static let wildcard = "com.adobe.eventSource._wildcard_"
    }
    
    private static let stringMapping: [RawValue: EventSource] = [
        Constants.none: .none,
        Constants.os: .os,
        Constants.requestContent: .requestContent,
        Constants.requestIdentity: .requestIdentity,
        Constants.requestProfile: .requestProfile,
        Constants.requestReset: .requestReset,
        Constants.responseContent: .responseContent,
        Constants.responseIdentity: .responseIdentity,
        Constants.responseProfile: .responseProfile,
        Constants.sharedState: .sharedState,
        Constants.wildcard: .wildcard,
    ]
    
    public var description: String {
        return self.rawValue
    }
    
    public var rawValue: RawValue {
        return EventSource.stringMapping.first(where: {$0.value == self})?.key ?? Constants.none
    }
    
    public init?(rawValue: RawValue) {
        if let value = EventSource.stringMapping[rawValue] {
            self = value
        }
        
        return nil
    }
}
