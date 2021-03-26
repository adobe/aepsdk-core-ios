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

class ContractExtensionTwo: NSObject, Extension {
    var name = "com.adobe.ContractExtensionTwo"
    var friendlyName = "ContractExtensionTwo"
    static var extensionVersion = "0.0.1"
    var metadata: [String: String]?

    static var onInitClosure: (() -> Void)?
    static var registrationClosure: (() -> Void)?
    static var unregistrationClosure: (() -> Void)?
    static var eventReceivedClosure: ((Event) -> Void)?
    static var readyForEventClosure: (() -> Bool)?

    let runtime: ExtensionRuntime

    required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        if let closure = type(of: self).onInitClosure {
            closure()
        }
    }

    static func reset() {
        onInitClosure = nil
        registrationClosure = nil
        unregistrationClosure = nil
        eventReceivedClosure = nil
        readyForEventClosure = nil
    }

    func onRegistered() {
        registerListener(type: EventType.wildcard, source: EventSource.wildcard) { event in
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

    func readyForEvent(_: Event) -> Bool {

        if let closure = type(of: self).readyForEventClosure {
            return closure()
        }
        return true
    }
}
