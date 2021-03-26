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

class MockExtensionTwo: NSObject, Extension {
    var name = "com.adobe.mockExtensionTwo"
    var friendlyName = "mockExtensionTwo"
    static var extensionVersion = "0.0.1"
    var metadata: [String: String]? = ["testMetaKey": "testMetaVal"]

    let runtime: ExtensionRuntime

    static var unregistrationClosure: (() -> Void)?
    static var registrationClosure: (() -> Void)?
    static var eventReceivedClosure: ((Event) -> Void)?

    required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    static func reset() {
        registrationClosure = nil
        unregistrationClosure = nil
        eventReceivedClosure = nil
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
        return true
    }
}
