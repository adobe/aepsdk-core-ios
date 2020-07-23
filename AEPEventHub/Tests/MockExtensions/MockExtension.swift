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

@testable import AEPCore

/// Protocol  defines consistent interface for testable extensions.
protocol TestableExtension: Extension {
    static var unregistrationClosure: (() -> Void)? { get set }
    static var registrationClosure: (() -> Void)? { get set }
    static var eventReceivedClosure: ((Event) -> Void)? { get set }
}

/// Provides implementaitons of common functions for a TestableExtension
extension TestableExtension {
    static func reset() {
        self.registrationClosure = nil
        self.unregistrationClosure = nil
        self.eventReceivedClosure = nil
    }
    
    func onRegistered() {
        registerListener(type: .wildcard, source: .wildcard) { (event) in
            if let closure = type(of: self).eventReceivedClosure {
                closure(event)
            }
        }
        
        if let closure = type(of: self).registrationClosure {
            closure()
        }
    }
    
    func onUnregistered() {
        if let closure = type(of: self).unregistrationClosure {
            closure()
        }
    }
}

class MockExtension: TestableExtension {
    var name = "mockExtension"
    var friendlyName = "mockExtension"
    var metadata: [String : String]? = nil
    var version = "0.0.1"

    static var registrationClosure: (() -> Void)? = nil
    static var unregistrationClosure: (() -> Void)? = nil
    static var eventReceivedClosure: ((Event) -> Void)? = nil
    
    let runtime: ExtensionRuntime
    
    required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }
}
