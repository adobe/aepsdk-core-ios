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
public enum EventType: String, Codable {
    case acquisition = "com.adobe.eventType.acquisition"
    case analytics = "com.adobe.eventType.analytics"
    case audienceManager = "com.adobe.eventType.audienceManager"
    case campaign = "com.adobe.eventType.campaign"
    case configuration = "com.adobe.eventType.configuration"
    case custom = "com.adobe.eventType.custom"
    case hub = "com.adobe.eventType.hub"
    case identity = "com.adobe.eventType.identity"
    case lifecycle = "com.adobe.eventType.lifecycle"
    case location = "com.adobe.eventType.location"
    case pii = "com.adobe.eventType.pii"
    case rulesEngine = "com.adobe.eventType.rulesEngine"
    case signal = "com.adobe.eventType.signal"
    case system = "com.adobe.eventType.system"
    case target = "com.adobe.eventType.target"
    case userProfile = "com.adobe.eventType.userProfile"
    case places = "com.adobe.eventType.places"
    case genericTrack = "com.adobe.eventType.generic.track"
    case genericLifecycle = "com.adobe.eventType.generic.lifecycle"
    case genericIdentity = "com.adobe.eventType.generic.identity"
    case genericPii = "com.adobe.eventType.generic.pii"
    case genericData = "com.adobe.eventType.generic.data"
    case wildcard = "com.adobe.eventType._wildcard_"
}
