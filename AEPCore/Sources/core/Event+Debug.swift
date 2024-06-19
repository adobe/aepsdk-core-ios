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

///
/// Extension on Event with helpers for handling debug events
///
public extension Event {
    
    static let DEBUG_EVENT_DEBUG_KEY = "debug"
    static let DEBUG_EVENT_TYPE_KEY = "eventType"
    static let DEBUG_EVENT_SOURCE_KEY = "eventSource"
    
    /// The debug event type (identified by debug.eventType) found in the event data if present, nil otherwise
    var debugEventType: String? {
        if let debugDictionary = debugEventData, let debugType = debugDictionary[Event.DEBUG_EVENT_TYPE_KEY] as? String {
            return debugType
        }
        return nil
    }
    
    /// The debug event source (identified by debug.eventSource) found in the event data if present, nil otherwise
    var debugEventSource: String? {
        if let debugDictionary = debugEventData, let debugSource = debugDictionary[Event.DEBUG_EVENT_SOURCE_KEY] as? String {
            return debugSource
        }
        return nil
    }
    
    /// The data found in the event if the event is a debug event, otherwise nil
    private var debugEventData: [String: Any]? {
        if type != EventType.system || source != EventSource.debug {
            return nil
        }
        
        return data?[Event.DEBUG_EVENT_DEBUG_KEY] as? [String: Any]
    }
}
