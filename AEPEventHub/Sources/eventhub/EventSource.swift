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
public enum EventSource: String, Codable {
    case none = "com.adobe.eventSource.none"
    case os = "com.adobe.eventSource.os"
    case requestContent = "com.adobe.eventSource.requestContent"
    case requestIdentity = "com.adobe.eventSource.requestIdentity"
    case requestProfile = "com.adobe.eventSource.requestProfile"
    case requestReset = "com.adobe.eventSource.requestReset"
    case responseContent = "com.adobe.eventSource.responseContent"
    case responseIdentity = "com.adobe.eventSource.responseIdentity"
    case responseProfile = "com.adobe.eventSource.responseProfile"
    case sharedState = "com.adobe.eventSource.sharedState"
    case wildcard = "com.adobe.eventSource._wildcard_"
}
