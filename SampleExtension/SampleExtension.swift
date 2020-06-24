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

public struct SampleExtension:Extension{
    public init() {
        
    }
    
    public let name: String = "SampleExtension"
    
    public var version: String = "0.0.1"
    
    public func onRegistered() {
        let event = Event(name: "sample", type: .acquisition, source: .none, data: [:])
        let dict = ThreadSafeDictionary<String, String>()
        dict["abc"] = "abc"
        let namedKeyValueStore = NamedKeyValueStore(name: "test")
        
        
        
    }
    
    public func onUnregistered() {
        
    }
    
    
}
