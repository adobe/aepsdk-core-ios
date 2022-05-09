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

/// Testable implementation for `ExtensionRuntime`
///
/// Enable easy setup for the input and verification of the output of an extension
public class TestableExtensionRuntime: ExtensionRuntime {
    public var listeners: [String: EventListener] = [:]
    public var dispatchedEvents: [Event] = []
    public var createdSharedStates: [[String: Any]?] = []
    public var createdXdmSharedStates: [[String: Any]?] = []
    public var mockedSharedStates: [String: SharedStateResult] = [:]
    public var mockedXdmSharedStates: [String: SharedStateResult] = [:]
    public var receivedEventHistoryRequests: [EventHistoryRequest] = []
    public var receivedEnforceOrder: Bool = false
    public var mockEventHistoryResults: [EventHistoryResult] = []
    public var ignoredEvents = Set<String>()

    public init() {}

    // MARK: - ExtensionRuntime methods implementation
    public func unregisterExtension() {
        // no-op
    }

    public func registerListener(type: String, source: String, listener: @escaping EventListener) {
        listeners["\(type)-\(source)"] = listener
    }

    public func dispatch(event: Event) {
        if(shouldIgnore(event)) {
            return
        }
        dispatchedEvents += [event]
    }

    public func createSharedState(data: [String: Any], event _: Event?) {
        createdSharedStates += [data]
    }

    public func createPendingSharedState(event _: Event?) -> SharedStateResolver {
        return { data in
            self.createdSharedStates += [data]
        }
    }

    public func getSharedState(extensionName: String, event: Event?, barrier: Bool) -> SharedStateResult? {
        getSharedState(extensionName: extensionName, event: event, barrier: barrier, resolution: .any)
    }

    public func getSharedState(extensionName: String, event: Event?, barrier: Bool, resolution: SharedStateResolution = .any) -> SharedStateResult? {
        // if there is an shared state setup for the specific (extension, event id) pair, return it. Otherwise, return the shared state that is setup for the extension.
        if let id = event?.id {
            return mockedSharedStates["\(extensionName)-\(id)"] ?? mockedSharedStates["\(extensionName)"]
        }
        return mockedSharedStates["\(extensionName)"]
    }

    public func createXDMSharedState(data: [String : Any], event: Event?) {
        createdXdmSharedStates += [data]
    }

    public func createPendingXDMSharedState(event: Event?) -> SharedStateResolver {
        return { data in
            self.createdXdmSharedStates += [data]
        }
    }

    public func getXDMSharedState(extensionName: String, event: Event?, barrier: Bool = false) -> SharedStateResult? {
        getXDMSharedState(extensionName: extensionName, event: event, barrier: barrier, resolution: .any)
    }

    public func getXDMSharedState(extensionName: String, event: Event?, barrier: Bool, resolution: SharedStateResolution = .any) -> SharedStateResult? {
        // if there is an shared state setup for the specific (extension, event id) pair, return it. Otherwise, return the shared state that is setup for the extension.
        if let id = event?.id {
            return mockedXdmSharedStates["\(extensionName)-\(id)"] ?? mockedXdmSharedStates["\(extensionName)"]
        }
        return mockedXdmSharedStates["\(extensionName)"]
    }

    public func startEvents() {}

    public func stopEvents() {}

    // MARK: - Helper methods
    /// Ignores the events from being dispatched by event hub.
    /// - Parameters:
    ///  - type: `EventType` of the event to be ignored
    ///  - source: `EventSource` of the event to be ignored
    public func ignoreEvent(type: String, source: String) {
        ignoredEvents.insert("\(type)-\(source)")
    }

    /// Removes all the ignored events.
    public func resetIgnoredEvents() {
        ignoredEvents.removeAll()
    }

    /// Determines if the event is to be ignored and not dispatched by event hub
    /// - Parameter event: An `Event`
    private func shouldIgnore(_ event: Event) -> Bool {
        return ignoredEvents.contains("\(event.type)-\(event.source)")
    }

    /// Simulate the events that are being sent to event hub, if there is a listener registered for that type of event, that listener will receive the event
    /// - Parameters:
    ///   - events: the sequence of the events
    public func simulateComingEvents(_ events: Event...) {
        for event in events {
            listeners["\(event.type)-\(event.source)"]?(event)
            listeners["\(EventType.wildcard)-\(EventSource.wildcard)"]?(event)
        }
    }

    /// Get the listener that is registered for the specific event source and type
    /// - Parameters:
    ///   - type: event type
    ///   - source: event source
    public func getListener(type: String, source: String) -> EventListener? {
        return listeners["\(type)-\(source)"]
    }

    /// Simulate the shared state of an extension for a matching event
    /// - Parameters:
    ///   - pair: the (extension, event) pair
    ///   - data: the shared state tuple (value, status)
    public func simulateSharedState(for pair: (extensionName: String, event: Event), data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedSharedStates["\(pair.extensionName)-\(pair.event.id)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// Simulate the shared state of an certain extension ignoring the event id
    /// - Parameters:
    ///   - extensionName: extension name
    ///   - data: the shared state tuple (value, status)
    public func simulateSharedState(for extensionName: String, data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedSharedStates["\(extensionName)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// Simulate the XDM shared state of an extension for a matching event
    /// - Parameters:
    ///   - pair: the (extension, event) pair
    ///   - data: the shared state tuple (value, status)
    public func simulateXDMSharedState(for pair: (extensionName: String, event: Event), data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedXdmSharedStates["\(pair.extensionName)-\(pair.event.id)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// Simulate the XDM shared state of an certain extension ignoring the event id
    /// - Parameters:
    ///   - extensionName: extension name
    ///   - data: the shared state tuple (value, status)
    public func simulateXDMSharedState(for extensionName: String, data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedXdmSharedStates["\(extensionName)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// clear the events and shared states that have been created by the current extension
    public func resetDispatchedEventAndCreatedSharedStates() {
        dispatchedEvents = []
        createdSharedStates = []
        createdXdmSharedStates = []
    }

    public func getHistoricalEvents(_ events: [EventHistoryRequest], enforceOrder: Bool, handler: @escaping ([EventHistoryResult]) -> Void) {
        receivedEventHistoryRequests = events
        receivedEnforceOrder = enforceOrder
        handler(mockEventHistoryResults)
    }
}

extension TestableExtensionRuntime {
    public var firstEvent: Event? {
        dispatchedEvents[0]
    }

    public var secondEvent: Event? {
        dispatchedEvents[1]
    }

    public var thirdEvent: Event? {
        dispatchedEvents[2]
    }

    public var firstSharedState: [String: Any]? {
        createdSharedStates[0]
    }

    public var secondSharedState: [String: Any]? {
        createdSharedStates[1]
    }

    public var thirdSharedState: [String: Any]? {
        createdSharedStates[2]
    }
}
