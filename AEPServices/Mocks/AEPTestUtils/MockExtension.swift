//
// Copyright 2024 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

@testable import AEPCore

public class MockExtension: NSObject, Extension {
    public var name = "com.adobe.mockExtension"
    public var friendlyName = "mockExtension"
    public static var extensionVersion = "0.0.1"
    public var metadata: [String: String]?

    public static var registrationClosure: (() -> Void)?
    public static var unregistrationClosure: (() -> Void)?
    public static var eventReceivedClosure: ((Event) -> Void)?

    public let runtime: ExtensionRuntime

    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    public static func reset() {
        registrationClosure = nil
        unregistrationClosure = nil
        eventReceivedClosure = nil
    }

    public func onRegistered() {
        registerListener(type: EventType.wildcard, source: EventSource.wildcard) { event in
            if let closure = type(of: self).eventReceivedClosure {
                closure(event)
            }
        }

        if let closure = type(of: self).registrationClosure {
            closure()
        }
    }

    public func onUnregistered() {
        if let closure = type(of: self).unregistrationClosure {
            closure()
        }
    }

    public func readyForEvent(_: Event) -> Bool {
        return true
    }
}
