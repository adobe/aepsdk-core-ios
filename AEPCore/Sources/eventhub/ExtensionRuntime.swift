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

/// provides all the methods needed by an `Extension`
@objc(AEPExtensionRuntime)
public protocol ExtensionRuntime {

    // MARK: - Registration

    /// Unregisters this extension from the `EventHub`
    func unregisterExtension()

    /// Registers an `EventListener` for the specified `EventType` and `EventSource`
    /// - Parameters:
    ///   - type: `EventType` to listen for
    ///   - source: `EventSource` to listen for
    ///   - listener: Function or closure which will be invoked whenever the `EventHub` receives an `Event` matching `type` and `source`
    func registerListener(type: String, source: String, listener: @escaping EventListener)

    // MARK: - Event control

    /// Starts the `Event` queue for this extension
    func startEvents()

    /// Stops the `Event` queue for this extension
    func stopEvents()

    /// Dispatches an `Event` to the `EventHub`
    /// - Parameter event: An `Event` to be dispatched to the `EventHub`
    func dispatch(event: Event)

    // MARK: - Shared State

    /// Creates a new `SharedState` for this extension
    /// If `event` is nil, one of two behaviors will be observed:
    /// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
    /// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
    /// - Parameters:
    ///   - data: Data for the `SharedState`
    ///   - event: `Event` for which the `SharedState` should be versioned
    func createSharedState(data: [String: Any], event: Event?)

    /// Creates a pending `SharedState` versioned at `event`
    /// If `event` is nil, one of two behaviors will be observed:
    /// 1. If this extension has not previously published a shared state, shared state will be versioned at 0
    /// 2. If this extension has previously published a shared state, shared state will be versioned at the latest
    /// - Parameter event: `Event` for which the `SharedState` should be versioned
    /// - Returns: a `SharedStateResolver` that should be called with the `SharedState` data when it is ready
    func createPendingSharedState(event: Event?) -> SharedStateResolver

    /// Gets the `SharedState` data for a specified extension    
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
    ///   - barrier: If true, the `EventHub` will only return `.set` if `extensionName` has moved past `event`
    /// - Returns: A `SharedStateResult?` for the requested `extensionName` and `event`
    func getSharedState(extensionName: String, event: Event?, barrier: Bool) -> SharedStateResult?
}
