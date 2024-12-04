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

import XCTest

import AEPCore
import AEPServices

/// Instrumented extension that registers a wildcard listener for intercepting events in current session. Use it along with `TestBase`
@available(*, deprecated, message: "A new class for capturing events using MobileCore.registerEventListener will be added in the next version. Please avoid using InstrumentedExtension directly in your tests.")
public class InstrumentedExtension: NSObject, Extension {
    private static let queue = DispatchQueue(label: "com.adobe.instrumentedextension.syncqueue")

    private static let logTag = "InstrumentedExtension"
    public var name = "com.adobe.InstrumentedExtension"
    public var friendlyName = "InstrumentedExtension"
    private static var _extensionVersion = "1.0.0"
    public static var extensionVersion: String {
        get {
            return queue.sync { _extensionVersion }
        }
        set {
            queue.sync { _extensionVersion = newValue }
        }
    }

    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    // Expected events Dictionary - key: EventSpec, value: the expected count
    private static var _expectedEvents = ThreadSafeDictionary<EventSpec, CountDownLatch>()
    static var expectedEvents: ThreadSafeDictionary<EventSpec, CountDownLatch> {
        get {
            return queue.sync { _expectedEvents }
        }
        set {
            queue.sync { _expectedEvents = newValue }
        }
    }

    // All the events seen by this listener that are not of type instrumentedExtension - key: EventSpec, value: received events with EventSpec type and source
    private static var _receivedEvents = ThreadSafeDictionary<EventSpec, [Event]>()
    static var receivedEvents: ThreadSafeDictionary<EventSpec, [Event]> {
        get {
            return queue.sync { _receivedEvents }
        }
        set {
            queue.sync { _receivedEvents = newValue }
        }
    }

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
        let type = event.type
        let source = event.source

        if type.lowercased() == TestConstants.EventType.INSTRUMENTED_EXTENSION.lowercased() {
            // process the shared state request event
            if source.lowercased() == TestConstants.EventSource.SHARED_STATE_REQUEST.lowercased() {
                processSharedStateRequest(event)
            }
            // process the unregister extension event
            else if source.lowercased() == TestConstants.EventSource.UNREGISTER_EXTENSION.lowercased() {
                unregisterExtension()
            }

            return
        }

        // save this event in the receivedEvents dictionary
        if InstrumentedExtension.receivedEvents[EventSpec(type: type, source: source)] != nil {
            InstrumentedExtension.receivedEvents[EventSpec(type: type, source: source)]?.append(event)
        } else {
            InstrumentedExtension.receivedEvents[EventSpec(type: type, source: source)] = [event]
        }

        // count down if this is an expected event
        if InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] != nil {
            InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)]?.countDown()
        }

        if source == EventSource.sharedState {

            let stateOwner = event.data?["stateowner"] ?? "unknown"
            Log.debug(label: InstrumentedExtension.logTag, "Received event with type \(type) and source \(source), state owner \(stateOwner)")
        } else {
            Log.debug(label: InstrumentedExtension.logTag, "Received event with type \(type) and source \(source)")
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
        queue.sync {
            _receivedEvents = ThreadSafeDictionary<EventSpec, [Event]>()
            _expectedEvents = ThreadSafeDictionary<EventSpec, CountDownLatch>()
        }
    }
}
