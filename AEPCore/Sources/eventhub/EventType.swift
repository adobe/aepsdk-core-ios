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
@objcMembers
public class EventType: NSObject {
    public static let acquisition = "com.adobe.eventType.acquisition"
    public static let analytics = "com.adobe.eventType.analytics"
    public static let audienceManager = "com.adobe.eventType.audienceManager"
    public static let campaign = "com.adobe.eventType.campaign"
    public static let configuration = "com.adobe.eventType.configuration"
    public static let custom = "com.adobe.eventType.custom"
    public static let edge = "com.adobe.eventType.edge"
    public static let edgeConsent = "com.adobe.eventType.edgeConsent"
    public static let edgeIdentity = "com.adobe.eventType.edgeIdentity"
    public static let edgeMedia = "com.adobe.eventType.edgeMedia"
    public static let genericData = "com.adobe.eventType.generic.data"
    public static let genericIdentity = "com.adobe.eventType.generic.identity"
    public static let genericLifecycle = "com.adobe.eventType.generic.lifecycle"
    public static let genericPii = "com.adobe.eventType.generic.pii"
    public static let genericTrack = "com.adobe.eventType.generic.track"
    public static let hub = "com.adobe.eventType.hub"
    public static let identity = "com.adobe.eventType.identity"
    public static let lifecycle = "com.adobe.eventType.lifecycle"
    public static let location = "com.adobe.eventType.location"
    public static let media = "com.adobe.eventType.media"
    public static let messaging = "com.adobe.eventType.messaging"
    public static let offerDecisioning = "com.adobe.eventType.offerDecisioning"
    public static let optimize = "com.adobe.eventType.optimize"
    public static let pii = "com.adobe.eventType.pii"
    public static let places = "com.adobe.eventType.places"
    public static let rulesEngine = "com.adobe.eventType.rulesEngine"
    public static let signal = "com.adobe.eventType.signal"
    public static let system = "com.adobe.eventType.system"
    public static let target = "com.adobe.eventType.target"
    public static let userProfile = "com.adobe.eventType.userProfile"
    public static let wildcard = "com.adobe.eventType._wildcard_"
}
