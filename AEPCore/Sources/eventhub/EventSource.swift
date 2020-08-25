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
@objc(AEPEventSource)
public class EventSource: NSObject {
    @objc public static let none = "com.adobe.eventSource.none"
    @objc public static let os = "com.adobe.eventSource.os"
    @objc public static let requestContent = "com.adobe.eventSource.requestContent"
    @objc public static let requestIdentity = "com.adobe.eventSource.requestIdentity"
    @objc public static let requestProfile = "com.adobe.eventSource.requestProfile"
    @objc public static let requestReset = "com.adobe.eventSource.requestReset"
    @objc public static let responseContent = "com.adobe.eventSource.responseContent"
    @objc public static let responseIdentity = "com.adobe.eventSource.responseIdentity"
    @objc public static let responseProfile = "com.adobe.eventSource.responseProfile"
    @objc public static let sharedState = "com.adobe.eventSource.sharedState"
    @objc public static let wildcard = "com.adobe.eventSource._wildcard_"
}
