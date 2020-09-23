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

@testable import AEPCore
import Foundation

class TestableExtensionRuntime: ExtensionRuntime {
    var listeners: [String: EventListener] = [:]
    var dispatchedEvents: [Event] = []
    var createdSharedStates: [[String: Any]?] = []
    var otherSharedStates: [String: SharedStateResult] = [:]

    func getListener(type: String, source: String) -> EventListener? {
        return listeners["\(type)-\(source)"]
    }

    func simulateComingEvent(event: Event) {
        listeners["\(event.type)-\(event.source)"]?(event)
        listeners["\(EventType.wildcard)-\(EventSource.wildcard)"]?(event)
    }

    func unregisterExtension() {
        // no-op
    }

    func registerListener(type: String, source: String, listener: @escaping EventListener) {
        listeners["\(type)-\(source)"] = listener
    }

    func dispatch(event: Event) {
        dispatchedEvents += [event]
    }

    func createSharedState(data: [String: Any], event _: Event?) {
        createdSharedStates += [data]
    }

    func createPendingSharedState(event _: Event?) -> SharedStateResolver {
        return { data in
            self.createdSharedStates += [data]
        }
    }

    func getSharedState(extensionName: String, event: Event?, barrier: Bool) -> SharedStateResult? {
        return otherSharedStates["\(extensionName)-\(String(describing: event?.id))"] ?? nil
    }

    func simulateSharedState(extensionName: String, event: Event?, data: (value: [String: Any]?, status: SharedStateStatus)) {
        otherSharedStates["\(extensionName)-\(String(describing: event?.id))"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// clear the events and shared states that have been created by the current extension
    public func resetDispatchedEventAndCreatedSharedStates() {
        dispatchedEvents = []
        createdSharedStates = []
    }

    func startEvents() {}

    func stopEvents() {}
}
