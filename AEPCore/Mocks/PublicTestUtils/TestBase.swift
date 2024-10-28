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

import AEPServices

@testable import AEPCore

open class TestBase: XCTestCase {
    /// Use this setting to enable logging in `TestBase`.
    public var loggingEnabled = false

    // Runs once per test suite
    open class override func setUp() {
        super.setUp()
        NamedCollectionDataStore.clear()
        MobileCore.setLogLevel(LogLevel.trace)
    }

    // Runs before each test case
    open override func setUp() {
        super.setUp()
        continueAfterFailure = false
        MobileCore.registerExtension(InstrumentedExtension.self)
    }

    open override func tearDown() {
        super.tearDown()
        // Wait .2 seconds in case there are unexpected events that were in the dispatch process during cleanup
        usleep(200000)
        resetTestExpectations()
        MobileCore.resetSDK()
        NamedCollectionDataStore.clear()
    }

    /// Reset event expectations and drop the items received until this point
    public func resetTestExpectations() {
        log("Resetting test expectations for events")
        InstrumentedExtension.reset()
    }

    /// Unregisters the `InstrumentedExtension` from the Event Hub. This method executes asynchronous.
    public func unregisterInstrumentedExtension() {
        let event = Event(name: "Unregister Instrumented Extension",
                          type: TestConstants.EventType.INSTRUMENTED_EXTENSION,
                          source: TestConstants.EventSource.UNREGISTER_EXTENSION,
                          data: nil)

        MobileCore.dispatch(event: event)
    }

    // MARK: Expected/Unexpected events assertions

    /// Sets an expectation for a specific event type and source and how many times the event should be dispatched
    /// - Parameters:
    ///   - type: the event type as a `String`, should not be empty
    ///   - source: the event source as a `String`, should not be empty
    ///   - count: the number of times this event should be dispatched, but default it is set to 1
    /// - See also:
    ///   - assertExpectedEvents(ignoreUnexpectedEvents:)
    public func setExpectationEvent(type: String, source: String, expectedCount: Int32 = 1) {
        guard expectedCount > 0 else {
            assertionFailure("Expected event count should be greater than 0")
            return
        }
        guard !type.isEmpty, !source.isEmpty else {
            assertionFailure("Expected event type and source should be non-empty strings")
            return
        }

        InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] = CountDownLatch(expectedCount)
    }

    /// Asserts if all the expected events were received and fails if an unexpected event was seen
    /// - Parameters:
    ///   - ignoreUnexpectedEvents: if set on false, an assertion is made on unexpected events, otherwise the unexpected events are ignored
    /// - See also:
    ///   - setExpectationEvent(type: source: count:)
    ///   - assertUnexpectedEvents()
    public func assertExpectedEvents(ignoreUnexpectedEvents: Bool = false, timeout: TimeInterval = TestConstants.Defaults.WAIT_EVENT_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        guard InstrumentedExtension.expectedEvents.count > 0 else { // swiftlint:disable:this empty_count
            assertionFailure("There are no event expectations set, use this API after calling setExpectationEvent", file: file, line: line)
            return
        }

        let currentExpectedEvents = InstrumentedExtension.expectedEvents.shallowCopy
        for expectedEvent in currentExpectedEvents {
            let waitResult = expectedEvent.value.await(timeout: timeout)
            let expectedCount: Int32 = expectedEvent.value.getInitialCount()
            let receivedCount: Int32 = expectedEvent.value.getInitialCount() - expectedEvent.value.getCurrentCount()
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut,
                           """
                           Timed out waiting for event type \(expectedEvent.key.type) and source \(expectedEvent.key.source),
                           expected \(expectedCount), but received \(receivedCount)
                           """,
                           file: (file),
                           line: line)
            XCTAssertEqual(expectedCount,
                           receivedCount,
                           """
                           Expected \(expectedCount) event(s) of type \(expectedEvent.key.type) and source \(expectedEvent.key.source),
                           but received \(receivedCount)
                           """,
                           file: (file),
                           line: line)
        }

        guard ignoreUnexpectedEvents == false else { return }
        assertUnexpectedEvents(file: file, line: line)
    }

    /// Asserts if any unexpected event was received. Use this method to verify the received events are correct when setting event expectations.
    /// - See also: setExpectationEvent(type: source: count:)
    public func assertUnexpectedEvents(file: StaticString = #file, line: UInt = #line) {
        wait()
        var unexpectedEventsReceivedCount = 0
        var unexpectedEventsAsString = ""

        let currentReceivedEvents = InstrumentedExtension.receivedEvents.shallowCopy
        for receivedEvent in currentReceivedEvents {

            // check if event is expected and it is over the expected count
            if let expectedEvent = InstrumentedExtension.expectedEvents[EventSpec(type: receivedEvent.key.type, source: receivedEvent.key.source)] {
                _ = expectedEvent.await(timeout: TestConstants.Defaults.WAIT_EVENT_TIMEOUT)
                let expectedCount: Int32 = expectedEvent.getInitialCount()
                let receivedCount: Int32 = expectedEvent.getInitialCount() - expectedEvent.getCurrentCount()
                XCTAssertEqual(expectedCount,
                               receivedCount,
                               """
                               Expected \(expectedCount) events of type \(receivedEvent.key.type) and source \(receivedEvent.key.source),
                               but received \(receivedCount)
                               """,
                               file: (file),
                               line: line)
            }
            // check for events that don't have expectations set
            else {
                unexpectedEventsReceivedCount += receivedEvent.value.count
                unexpectedEventsAsString.append("(\(receivedEvent.key.type), \(receivedEvent.key.source), \(receivedEvent.value.count)),")
                log("Received unexpected event with type: \(receivedEvent.key.type) source: \(receivedEvent.key.source)")
            }
        }

        XCTAssertEqual(0, unexpectedEventsReceivedCount, "Received \(unexpectedEventsReceivedCount) unexpected event(s): \(unexpectedEventsAsString)", file: (file), line: line)
    }

    /// To be revisited once AMSDK-10169 is implemented
    /// - Parameters:
    ///   - timeout:how long should this method wait, in seconds; by default it waits up to 1 second
    public func wait(_ timeout: UInt32? = TestConstants.Defaults.WAIT_TIMEOUT) {
        if let timeout = timeout {
            sleep(timeout)
        }
    }

    /// Returns the `ACPExtensionEvent`(s) dispatched through the Event Hub, or empty if none was found.
    /// Use this API after calling `setExpectationEvent(type:source:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - type: the event type as in the expectation
    ///   - source: the event source as in the expectation
    ///   - timeout: how long should this method wait for the expected event, in seconds; by default it waits up to 1 second
    /// - Returns: list of events with the provided `type` and `source`, or empty if none was dispatched
    public func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = TestConstants.Defaults.WAIT_EVENT_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [Event] {
        if InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] != nil {
            let waitResult = InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)]?.await(timeout: timeout)
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(type) and source \(source)", file: file, line: line)
        } else {
            wait(TestConstants.Defaults.WAIT_TIMEOUT)
        }
        return InstrumentedExtension.receivedEvents[EventSpec(type: type, source: source)] ?? []
    }

    /// Retrieves the standard `SharedState` for a specific extension (as opposed to XDM).
    /// This method fetches the shared state for a given extension name, optionally based on a specific event.
    /// The shared state can be resolved according to the specified resolution and shared state type.
    /// - Parameters:
    ///   - extensionName: The name of the extension whose `SharedState` will be returned.
    ///   - event: If provided, retrieves the `SharedState` that corresponds with this event's version, or the latest if not yet versioned.
    ///            If `event` is nil, the method returns the latest `SharedState`. Defaults to `nil`.
    ///   - barrier: If true, the `EventHub` will only return `.set` if the extension has moved past the given event.
    ///              Defaults to `true`.
    ///   - resolution: The `SharedStateResolution` used to determine how to resolve the shared state.
    ///                 Defaults to `.any`.
    /// - Returns: A `SharedStateResult` containing the shared state data and status for the specified extension,
    ///            or `nil` if no shared state is available.
    public func getSharedStateFor(extensionName: String, event: Event? = nil, barrier: Bool = true, resolution: SharedStateResolution = .any) -> SharedStateResult? {
        log("Getting shared state for: \(extensionName)")
        return EventHub.shared.getSharedState(extensionName: extensionName, event: event, barrier: barrier, resolution: resolution, sharedStateType: .standard)
    }

    /// Print message to console if ``loggingEnabled`` is true.
    /// - Parameter message: message to log to console
    public func log(_ message: String) {
        guard !message.isEmpty && loggingEnabled else { return }
        print("TestBase - \(message)")
    }
}
