//
/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import Foundation


public extension Event {
    
    static let DEBUG_EVENT_TYPE_KEY = "eventType"
    static let DEBUG_EVENT_SOURCE_KEY = "eventSource"
    
    var debugEventType: String? {
        if let debugDictionary = data?[CoreConstants.Keys.DEBUG] as? [String: Any], let debugType = debugDictionary[Event.DEBUG_EVENT_TYPE_KEY] as? String {
            return debugType
        }
        return nil
    }
    
    var debugEventSource: String? {
        if let debugDictionary = data?[CoreConstants.Keys.DEBUG] as? [String: Any], let debugSource = debugDictionary[Event.DEBUG_EVENT_SOURCE_KEY] as? String {
            return debugSource
        }
        return nil
    }
    
    var debugEventData: [String: Any]? {
        if type != EventType.system || source != EventSource.debug {
            return nil
        }
        
        return data
    }
}
