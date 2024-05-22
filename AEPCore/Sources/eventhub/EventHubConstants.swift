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

/// Constant values used throughout `EventHub`
enum EventHubConstants {
    static let STATE_CHANGE = "Shared state change"
    static let XDM_STATE_CHANGE = "Shared state change (XDM)"
    static let NAME = "com.adobe.module.eventhub"
    static let FRIENDLY_NAME = "EventHub"
    static let VERSION_NUMBER = "5.1.0"

    enum EventDataKeys {
        static let VERSION = "version"
        static let EXTENSIONS = "extensions"
        static let WRAPPER = "wrapper"
        static let TYPE = "type"
        static let METADATA = "metadata"
        static let FRIENDLY_NAME = "friendlyName"

        enum Configuration {
            static let EVENT_STATE_OWNER = "stateowner"
        }
    }
}
