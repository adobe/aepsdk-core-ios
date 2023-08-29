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

/// Represents the source from which an event originates
@objc(AEPEventSource)
@objcMembers
public class EventSource: NSObject {
    public static let none = "com.adobe.eventSource.none"
    public static let os = "com.adobe.eventSource.os"
    public static let requestContent = "com.adobe.eventSource.requestContent"
    public static let requestIdentity = "com.adobe.eventSource.requestIdentity"
    public static let requestProfile = "com.adobe.eventSource.requestProfile"
    public static let requestReset = "com.adobe.eventSource.requestReset"
    public static let responseContent = "com.adobe.eventSource.responseContent"
    public static let responseIdentity = "com.adobe.eventSource.responseIdentity"
    public static let responseProfile = "com.adobe.eventSource.responseProfile"
    public static let sharedState = "com.adobe.eventSource.sharedState"
    public static let notification = "com.adobe.eventSource.notification"
    public static let updateConsent = "com.adobe.eventSource.updateConsent"
    public static let updateIdentity = "com.adobe.eventSource.updateIdentity"
    public static let removeIdentity = "com.adobe.eventSource.removeIdentity"
    public static let wildcard = "com.adobe.eventSource._wildcard_"
    public static let resetComplete = "com.adobe.eventSource.resetComplete"
    public static let applicationLaunch = "com.adobe.eventSource.applicationLaunch"
    public static let applicationClose = "com.adobe.eventSource.applicationClose"
    public static let personalizationDecisions = "personalization:decisions"
    public static let locationHintResult = "locationHint:result"
    public static let errorResponseContent = "com.adobe.eventSource.errorResponseContent"
    public static let createTracker = "com.adobe.eventSource.createTracker"
    public static let trackMedia = "com.adobe.eventSource.trackMedia"
    public static let contentComplete = "com.adobe.eventSource.contentComplete"
}
