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

/// An `Extension` for `EventHub`. This serves no purpose other than to allow `EventHub` to share state.
class EventHubPlaceholderExtension: NSObject, Extension {
    let name = EventHubConstants.NAME
    let friendlyName = EventHubConstants.FRIENDLY_NAME
    static let extensionVersion = EventHubConstants.VERSION_NUMBER
    let metadata: [String: String]? = nil
    let runtime: ExtensionRuntime

    required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    func onRegistered() {}
    func onUnregistered() {}
    func readyForEvent(_: Event) -> Bool {
        return true
    }
}
