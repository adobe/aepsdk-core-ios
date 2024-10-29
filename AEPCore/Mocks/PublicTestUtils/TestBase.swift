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

    /// Unregisters the `InstrumentedExtension` from the Event Hub. This method executes asynchronously.
    public func unregisterInstrumentedExtension() {
        let event = Event(name: "Unregister Instrumented Extension",
                          type: TestConstants.EventType.INSTRUMENTED_EXTENSION,
                          source: TestConstants.EventSource.UNREGISTER_EXTENSION,
                          data: nil)

        MobileCore.dispatch(event: event)
    }

    // MARK: Expected/Unexpected events assertions
    /// Sets an expectation for an event to occur a specified number of times.
    ///
    /// - Parameters:
    ///   - type: A `String` representing the type of the expected event. Must be non-empty.
    ///   - source: A `String` representing the source of the expected event. Must be non-empty.
    ///   - expectedCount: An `Int32` representing the number of times the event is expected to occur.
    ///     The value must be greater than 0. Default is `1`.
    ///
    /// - Important:
    ///   Both `type` and `source` must be non-empty strings, and `expectedCount` must be greater than 0.
    ///   If these conditions are not met, the method triggers an assertion failure.
    ///
    /// - SeeAlso: ``assertExpectedEvents(ignoreUnexpectedEvents:timeout:file:line:)``
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

    /// Asserts that all expected events have occurred within the specified timeout and validates their counts.
    ///
    /// - Parameters:
    ///   - ignoreUnexpectedEvents: A `Bool` flag indicating whether to ignore unexpected events.
    ///     If set to `true`, unexpected events are not checked. Default is `false`.
    ///   - timeout: The maximum time (in seconds) to wait for the expected events. Default value
    ///     is `TestConstants.Defaults.WAIT_EVENT_TIMEOUT`.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Important:
    ///   Ensure that expected events are set using the ``setExpectationEvent(type:source:expectedCount:)`` method before calling this function.
    ///   If no expected events are registered, the function will trigger an assertion failure.
    ///
    /// - SeeAlso:
    ///   - ``setExpectationEvent(type:source:expectedCount:)``
    ///   - ``assertUnexpectedEvents(timeout:file:line:)``
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
        assertUnexpectedEvents(timeout: timeout, file: file, line: line)
    }

    /// Asserts whether any unexpected events were received, including receiving more events than expected or events without any expectation.
    /// Use this method to verify that the received events align with the set event expectations.
    ///
    /// - Parameters:
    ///   - timeout: The time interval to wait for the expected events. Defaults to `TestConstants.Defaults.WAIT_EVENT_TIMEOUT`.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - See also: ``setExpectationEvent(type:source:expectedCount:)``
    public func assertUnexpectedEvents(timeout: TimeInterval = TestConstants.Defaults.WAIT_EVENT_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        var unexpectedEventsReceivedCount = 0
        var unexpectedEventsAsString = ""

        let currentReceivedEvents = InstrumentedExtension.receivedEvents.shallowCopy
        for receivedEvent in currentReceivedEvents {
            // Validate that the number of received events does not exceed the expected count.
            if let expectedEvent = InstrumentedExtension.expectedEvents[EventSpec(type: receivedEvent.key.type, source: receivedEvent.key.source)] {
                _ = expectedEvent.await(timeout: timeout)
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
            // Validate that no events were received without an expectation.
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

    /// Sleeps for the given timeout period.
    /// - Parameters:
    ///   - timeout: A `TimeInterval` (in seconds) representing the duration to wait.
    private func wait(_ timeout: TimeInterval? = TestConstants.Defaults.WAIT_EVENT_TIMEOUT) {
        guard let timeout = timeout else { return }
        let safeTimeout = min(timeout, Double(UInt32.max))
        wait(UInt32(safeTimeout))
    }

    /// Retrieves the dispatched ``Event``(s) from the Event Hub that match the provided type and source.
    ///
    /// This method behaves in two ways based on whether an expectation has been set for the specified event:
    /// 1. **If the event expectation is set:** It waits for the events to be dispatched within the provided timeout.
    /// 2. **If no event expectation is set:** It waits for the full timeout period before attempting to retrieve the event.
    ///
    /// - Parameters:
    ///   - type: A `String` representing the type of the event.
    ///   - source: A `String` representing the source of the event.
    ///   - timeout: A `TimeInterval` indicating how long (in seconds) to wait for the expected event(s).
    ///     By default, the value is `TestConstants.Defaults.WAIT_EVENT_TIMEOUT`.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: A list of `Event` objects with the specified type and source, or an empty list if no matching events were dispatched.
    ///
    /// - SeeAlso: ``setExpectationEvent(type:source:expectedCount:)``
    public func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = TestConstants.Defaults.WAIT_EVENT_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [Event] {
        if InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] != nil {
            let waitResult = InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)]?.await(timeout: timeout)
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(type) and source \(source)", file: file, line: line)
        } else {
            wait(timeout)
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
