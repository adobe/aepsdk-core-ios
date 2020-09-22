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
public class PerfExtension:NSObject, Extension{
    public var name: String = "PerfExtension"
    
    public var friendlyName: String = "Perf"
    
    public static var extensionVersion: String = "0.0.1"
    
    public var metadata: [String : String]?
    
    public var runtime: ExtensionRuntime
    
    public static var LIFECYCLE_START_RESPONSE_EVENT_RECEIVED = false
    
    public static var RULES_CONSEQUENCE_EVENTS = 0
    
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }
    
    public func onRegistered() {
        registerListener(type: EventType.lifecycle, source: EventSource.responseContent) { (event) in
            if event.name == "LifecycleStart" {
                PerfExtension.LIFECYCLE_START_RESPONSE_EVENT_RECEIVED = true
            }
        }
        registerListener(type: EventType.rulesEngine, source: EventSource.responseContent) { (event) in
            if event.name == "Rules Consequence Event" {
                PerfExtension.RULES_CONSEQUENCE_EVENTS += 1
            }
        }
    }
    
    public func onUnregistered() {
        
    }
    public func readyForEvent(_ event: Event) -> Bool{
        return true
    }
    
}
