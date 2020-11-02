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

// MARK: - Extension protocol
/// An object which can be registered with the `EventHub`
@objc(AEPExtension)
public protocol Extension {
    /// Name of the extension
    var name: String { get }

    /// A friendly, human-readable name of the extension
    var friendlyName: String { get }

    /// Version of the extension
    /// This variable is `static` so that it may be accessed from a `static` public API.
    static var extensionVersion: String { get }

    /// Optional metadata to be provided to the `EventHub`
    var metadata: [String: String]? { get }

    /// Provides access to `ExtensionRuntime` methods that can be used by extension
    var runtime: ExtensionRuntime { get }

    /// Invoked when the extension has been registered by the `EventHub`
    func onRegistered()

    /// Invoked when the extension has been unregistered by the `EventHub`
    func onUnregistered()

    /// Called before each `Event` is processed by any `ExtensionListener` owned by this `Extension`
    /// Should be overridden by any extension that wants to control its own `Event` flow on a per `Event` basis.
    /// - Parameter event: event that will be processed next
    /// - Returns: *true* if event processing should continue for this `Extension`
    func readyForEvent(_ event: Event) -> Bool

    /// An `Extension` must support parameterless initialization
    init?(runtime: ExtensionRuntime)
}

// MARK: - Extension extension

/// Contains methods for interacting with extensions
public extension Extension {

    /// Unregisters this extension from the `EventHub`
    func unregisterExtension() {
        runtime.unregisterExtension()
    }

    /// Registers a `EventListener` with the `EventHub`
    /// - Parameters:
    ///   - type: `EventType` to be listened for
    ///   - source: `EventSource` to be listened for
    ///   - listener: The `EventListener` to be invoked when `EventHub` dispatches an `Event` with matching `type` and `source`
    func registerListener(type: String, source: String, listener: @escaping EventListener) {
        runtime.registerListener(type: type, source: source, listener: listener)
    }

    /// Dispatches an `Event` to the `EventHub`
    /// - Parameter event: An `Event` to be dispatched to the `EventHub`
    func dispatch(event: Event) {
        runtime.dispatch(event: event)
    }

    // MARK: - Shared State

    /// Creates a new `SharedState` for this extension
    /// If `event` is nil, one of two behaviors will be observed:
    /// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
    /// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
    /// - Parameters:
    ///   - data: Data for the `SharedState`
    ///   - xdmData: XDM data for the `SharedState`
    ///   - event: `Event` for which the `SharedState` should be versioned
    func createSharedState(data: [String: Any], xdmData: [String: Any]?, event: Event?) {
        runtime.createSharedState(data: data, xdmData: xdmData, event: event)
    }

    /// Creates a pending `SharedState` versioned at `event`
    /// If `event` is nil, one of two behaviors will be observed:
    /// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
    /// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
    /// - Parameter event: `Event` for which the `SharedState` should be versioned
    /// - Returns: a `SharedStateResolver` that should be called with the `SharedState` data when it is ready
    func createPendingSharedState(event: Event?) -> SharedStateResolver {
        return runtime.createPendingSharedState(event: event)
    }

    /// Gets the `SharedState` data for a specified extension
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
    ///   - barrier: If true, the `EventHub` will only return `.set` if `extensionName` has moved past `event`
    /// - Returns: A `SharedStateResult?` for the requested `extensionName` and `event`
    func getSharedState(extensionName: String, event: Event?, barrier: Bool = true) -> SharedStateResult? {
        return runtime.getSharedState(extensionName: extensionName, event: event, barrier: barrier)
    }

    /// Gets the `SharedState` data for a specified extension
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
    /// - Returns: A `SharedStateResult?` for the requested `extensionName` and `event`
    func getSharedState(extensionName: String, event: Event?) -> SharedStateResult? {
        return runtime.getSharedState(extensionName: extensionName, event: event, barrier: true)
    }

    /// Called before each `Event` is processed by any `ExtensionListener` owned by this `Extension`
    /// Should be overridden by any extension that wants to control it's own event flow on a per event basis.
    /// - Parameter event: `Event` that will be processed next
    /// - Returns: *true* if event processing should continue for this `Extension`
    func readyForEvent(_: Event) -> Bool {
        return true
    }

    /// Starts the `Event` queue for this extension
    func startEvents() {
        runtime.startEvents()
    }

    /// Stops the `Event` queue for this extension
    func stopEvents() {
        runtime.stopEvents()
    }

    /// Register a event preprocessor
    /// - Parameter preprocessor: The `EventPreprocessor`
    internal func registerPreprocessor(_ preprocessor: @escaping EventPreprocessor) {
        EventHub.shared.registerPreprocessor(preprocessor)
    }
}
