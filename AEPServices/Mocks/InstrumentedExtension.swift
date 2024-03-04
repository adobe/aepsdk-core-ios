//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
import AEPServices
import XCTest

/// Instrumented extension that registers a wildcard listener for intercepting events in current session. Use it along with `TestBase`
public class InstrumentedExtension: NSObject, Extension {
    private static let logTag = "InstrumentedExtension"
    public var name = "com.adobe.InstrumentedExtension"
    public var friendlyName = "InstrumentedExtension"
    public static var extensionVersion = "1.0.0"
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    // Expected events Dictionary - key: EventSpec, value: the expected count
    static var expectedEvents = ThreadSafeDictionary<EventSpec, CountDownLatch>()

    // All the events seen by this listener that are not of type instrumentedExtension - key: EventSpec, value: received events with EventSpec type and source
    static var receivedEvents = ThreadSafeDictionary<EventSpec, [Event]>()

    public func onRegistered() {
        runtime.registerListener(type: EventType.wildcard, source: EventSource.wildcard, listener: wildcardListenerProcessor)
    }

    public func onUnregistered() {}

    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    required public init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    // MARK: Event Processors
    func wildcardListenerProcessor(_ event: Event) {
        if event.type.lowercased() == TestConstants.EventType.INSTRUMENTED_EXTENSION.lowercased() {
            // process the shared state request event
            if event.source.lowercased() == TestConstants.EventSource.SHARED_STATE_REQUEST.lowercased() {
                processSharedStateRequest(event)
            }
            // process the unregister extension event
            else if event.source.lowercased() == TestConstants.EventSource.UNREGISTER_EXTENSION.lowercased() {
                unregisterExtension()
            }

            return
        }

        // save this event in the receivedEvents dictionary
        if InstrumentedExtension.receivedEvents[EventSpec(type: event.type, source: event.source)] != nil {
            InstrumentedExtension.receivedEvents[EventSpec(type: event.type, source: event.source)]?.append(event)
        } else {
            InstrumentedExtension.receivedEvents[EventSpec(type: event.type, source: event.source)] = [event]
        }

        // count down if this is an expected event
        if InstrumentedExtension.expectedEvents[EventSpec(type: event.type, source: event.source)] != nil {
            InstrumentedExtension.expectedEvents[EventSpec(type: event.type, source: event.source)]?.countDown()
        }

        if event.source == EventSource.sharedState {
            Log.debug(label: InstrumentedExtension.logTag, "Received event with type \(event.type) and source \(event.source), state owner \(event.data?["stateowner"] ?? "unknown")")
        } else {
            Log.debug(label: InstrumentedExtension.logTag, "Received event with type \(event.type) and source \(event.source)")
        }
    }

    /// Process `getSharedStateFor` requests
    /// - Parameter event: event sent from `getSharedStateFor` which specifies the shared state `stateowner` to retrieve
    func processSharedStateRequest(_ event: Event) {
        guard let eventData = event.data, !eventData.isEmpty  else { return }
        guard let owner = eventData[TestConstants.EventDataKey.STATE_OWNER] as? String else { return }

        var responseData: [String: Any?] = [TestConstants.EventDataKey.STATE_OWNER: owner, TestConstants.EventDataKey.STATE: nil]
        if let state = runtime.getSharedState(extensionName: owner, event: event, barrier: false) {
            responseData[TestConstants.EventDataKey.STATE] = state
        }

        let responseEvent = event.createResponseEvent(name: "Get Shared State Response",
                                                      type: TestConstants.EventType.INSTRUMENTED_EXTENSION,
                                                      source: TestConstants.EventSource.SHARED_STATE_RESPONSE,
                                                      data: responseData as [String: Any])

        Log.debug(label: InstrumentedExtension.logTag, "ProcessSharedStateRequest Responding with shared state \(String(describing: responseData))")

        // dispatch paired response event with shared state data
        MobileCore.dispatch(event: responseEvent)
    }

    func unregisterExtension() {
        Log.debug(label: InstrumentedExtension.logTag, "Unregistering the Instrumented extension from the Event Hub")
        runtime.unregisterExtension()
    }

    public static func reset() {
        receivedEvents = ThreadSafeDictionary<EventSpec, [Event]>()
        expectedEvents = ThreadSafeDictionary<EventSpec, CountDownLatch>()
    }
}
