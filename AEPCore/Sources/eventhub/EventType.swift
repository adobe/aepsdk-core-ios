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
@objc(AEPEventType)
public class EventType: NSObject {
    @objc public static let acquisition = "com.adobe.eventType.acquisition"
    @objc public static let analytics = "com.adobe.eventType.analytics"
    @objc public static let audienceManager = "com.adobe.eventType.audienceManager"
    @objc public static let campaign = "com.adobe.eventType.campaign"
    @objc public static let configuration = "com.adobe.eventType.configuration"
    @objc public static let custom = "com.adobe.eventType.custom"
    @objc public static let hub = "com.adobe.eventType.hub"
    @objc public static let identity = "com.adobe.eventType.identity"
    @objc public static let lifecycle = "com.adobe.eventType.lifecycle"
    @objc public static let location = "com.adobe.eventType.location"
    @objc public static let pii = "com.adobe.eventType.pii"
    @objc public static let rulesEngine = "com.adobe.eventType.rulesEngine"
    @objc public static let signal = "com.adobe.eventType.signal"
    @objc public static let system = "com.adobe.eventType.system"
    @objc public static let target = "com.adobe.eventType.target"
    @objc public static let userProfile = "com.adobe.eventType.userProfile"
    @objc public static let places = "com.adobe.eventType.places"
    @objc public static let genericTrack = "com.adobe.eventType.generic.track"
    @objc public static let genericLifecycle = "com.adobe.eventType.generic.lifecycle"
    @objc public static let genericIdentity = "com.adobe.eventType.generic.identity"
    @objc public static let genericPii = "com.adobe.eventType.generic.pii"
    @objc public static let genericData = "com.adobe.eventType.generic.data"
    @objc public static let wildcard = "com.adobe.eventType._wildcard_"
}
