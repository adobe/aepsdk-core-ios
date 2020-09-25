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
import AEPCore


@objc(PerfExtension)
public class MyExtension:NSObject, Extension{
    public var name: String = "MyExtension"
    
    public var friendlyName: String = "MyExtension"
    
    public static var extensionVersion: String = "0.0.1"
    
    public var metadata: [String : String]?
    
    public var runtime: ExtensionRuntime
    
    public static var LIFECYCLE_START_RESPONSE_EVENT_RECEIVED = false
    
    public static var EVENT_HUB_BOOTED = false
    
    public static var RULES_CONSEQUENCE_EVENTS = 0
    
    public static var RULES_CONSEQUENCE_FOR_INSTALL_EVENT = false
    
    public static var TRACK_ACTION_EVENT_WITH_ATTACHED_DATA = false
    
    public static var TRACK_ACTION_EVENT_WITH_MODIFIED_DATA = false
    
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }
    
    public func onRegistered() {
        registerListener(type: EventType.lifecycle, source: EventSource.responseContent) { (event) in
            if event.name == "LifecycleStart" {
                MyExtension.LIFECYCLE_START_RESPONSE_EVENT_RECEIVED = true
            }
        }
        registerListener(type: EventType.hub, source: EventSource.sharedState) { (event) in
            if event.name == "STATE_CHANGE_EVENT", let owner = event.data?["stateowner"] as? String, owner == "com.adobe.module.eventhub" {
                MyExtension.EVENT_HUB_BOOTED = true
            }
        }
        registerListener(type: EventType.rulesEngine, source: EventSource.responseContent) { (event) in
            if event.name == "Rules Consequence Event", let triggeredconsequence = event.data?["triggeredconsequence"] as? [String:Any], let detail = triggeredconsequence["detail"] as? [String: Any], let url = detail["templateurl"] as? String, url == "http://www.reprocess-events.com" {
                MyExtension.RULES_CONSEQUENCE_FOR_INSTALL_EVENT = true
            }
        }
        registerListener(type: EventType.genericTrack, source: EventSource.requestContent) { (event) in
            if event.name == "track action event for attach data rule", let action = event.data?["action"] as? String , action == "action", let launches = event.data?["attached_launches"] as? String, let launchesInt = Int(launches), launchesInt >= 0{
                MyExtension.TRACK_ACTION_EVENT_WITH_ATTACHED_DATA = true
            }
            if event.name == "track action event for modify data rule",let action = event.data?["action"] as? String, action == "action", let contextdata = event.data?["contextdata"] as? [String:Any], let key1 = contextdata["key1"] as? String, key1 == "newValue", contextdata["key2"] == nil,let launches = contextdata["launches"] as? String, let launchesInt = Int(launches), launchesInt >= 0{
                MyExtension.TRACK_ACTION_EVENT_WITH_MODIFIED_DATA = true
            }
        }
    }
    
    public func onUnregistered() {
        
    }
    public func readyForEvent(_ event: Event) -> Bool{
        return true
    }
    
}
