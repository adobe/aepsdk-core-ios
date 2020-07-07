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


public protocol ExtensionRuntime {
    /// Registers an `EventListener` for the specified `EventType` and `EventSource`
    /// - Parameters:
    ///   - type: `EventType` to listen for
    ///   - source: `EventSource` to listen for
    ///   - listener: Function or closure which will be invoked whenever the `EventHub` receives an `Event` matching `type` and `source`
    func registerListener(type: EventType, source: EventSource, listener: @escaping EventListener)

    /// Registers an `EventListener` with the `EventHub` that is invoked when `triggerEvent`'s response event is dispatched
    /// - Parameters:
    ///   - triggerEvent: An event which will trigger a response event
    ///   - timeout A timeout in seconds, if the response listener is not invoked within the timeout, then the `EventHub` invokes the response listener with a nil `Event`
    ///   - listener: The `EventListener` to be invoked when `EventHub` dispatches the response event to `triggerEvent`
    func registerResponseListener(triggerEvent: Event, timeout: TimeInterval, listener: @escaping EventResponseListener)
    
    /// Dispatches an `Event` to the `EventHub`
    /// - Parameter event: An `Event` to be dispatched to the `EventHub`
    func dispatch(event: Event)

    // MARK: Shared State

    /// Creates a new `SharedState for this extension
    /// - Parameters:
    ///   - data: Data for the `SharedState`
    ///   - event: An event for the `SharedState` to be versioned at, if nil the shared state is versioned at the latest
    func createSharedState(data: [String: Any], event: Event?)


    /// Creates a pending `SharedState` versioned at `event`
    /// - Parameter event: The event for the pending `SharedState` to be created at
    func createPendingSharedState(event: Event?) -> SharedStateResolver

    /// Gets the `SharedState` data for a specified extension
    /// - Parameters:
    ///   - extensionName: An extension name whose `SharedState` will be returned
    ///   - event: If not nil, will retrieve the `SharedState` that corresponds with the event's version, if nil will return the latest `SharedState`
    func getSharedState(extensionName: String, event: Event?) -> (value: [String: Any]?, status: SharedStateStatus)?
}
