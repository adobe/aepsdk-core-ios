//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPServices
@testable import AEPCore
import XCTest

class ClassFinderTests: XCTestCase {
    
    func testClassFinderBasic() {
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 10
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()], options: measureOptions) {
                let foundExtensions = ClassFinder.classes(conformToProtocol: Extension.self)
                XCTAssertEqual(foundExtensions.count, 3)
            }
        }
    }
}


class SampleExtensionOne: NSObject, Extension {
    var name: String = "com.adobe.sampleExtensionOne"
    
    var friendlyName: String = "SampleExtensionOne"
    
    static var extensionVersion: String = "1.0.0"
    
    var metadata: [String : String]?
    
    var runtime: AEPCore.ExtensionRuntime
    
    func onRegistered() {
        
    }
    
    func onUnregistered() {
        
    }
    
    required init?(runtime: AEPCore.ExtensionRuntime) {
        self.runtime = runtime
    }
    
    func readyForEvent(_ event: Event) -> Bool {
        return true
    }
    
    
}

class SampleExtensionTwo: NSObject, Extension {
    var name: String = "com.adobe.sampleExtensionTwo"
    
    var friendlyName: String = "SampleExtensionTwo"
    
    static var extensionVersion: String = "1.0.0"
    
    var metadata: [String : String]?
    
    var runtime: AEPCore.ExtensionRuntime
    
    func onRegistered() {
        
    }
    
    func onUnregistered() {
        
    }
    
    required init?(runtime: AEPCore.ExtensionRuntime) {
        self.runtime = runtime
    }
    
    func readyForEvent(_ event: Event) -> Bool {
        return true
    }
}

class SampleExtensionThree: NSObject, Extension {
    var name: String = "com.adobe.SampleExtensionThree"
    
    var friendlyName: String = "SampleExtensionThree"
    
    static var extensionVersion: String = "1.0.0"
    
    var metadata: [String : String]?
    
    var runtime: AEPCore.ExtensionRuntime
    
    func onRegistered() {
        
    }
    
    func onUnregistered() {
        
    }
    
    required init?(runtime: AEPCore.ExtensionRuntime) {
        self.runtime = runtime
    }
    
    func readyForEvent(_ event: Event) -> Bool {
        return true
    }
}
