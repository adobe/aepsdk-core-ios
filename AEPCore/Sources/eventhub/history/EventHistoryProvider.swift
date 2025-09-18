/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

protocol EventHistoryProvider {
    /// Provides direct access to the underlying `EventHistoryStore`.
    ///
    /// This property exposes the lower-level storage operations (insert, select, delete) used by the event history system.
    ///
    /// - Note: Use caution when interacting directly with `storage` to avoid bypassing important event history logic
    ///         enforced at the `EventHistoryProvider` level.
    var storage: EventHistoryStore { get }

    /// Records an `Event` based on its calculated hash.
    ///
    /// The hash is generated based on the provided `event`'s data.
    /// The `event`'s `mask` value, if provided, will filter what values in the event data are used for hash generation.
    /// If the hash value for the provided `event` is `0`, no record will be created in event history.
    ///
    /// - Parameters:
    ///   - event: the `Event` to be recorded in event history.
    ///   - handler: called with `true` if the event was successfully recorded, `false` otherwise.
    func recordEvent(_ event: Event, handler: ((Bool) -> Void)?)

    /// Retrieves a count of historical events matching the provided requests.
    ///
    /// - Parameters:
    ///   - requests: an array of `EventHistoryRequest`s used for the event lookup.
    ///   - enforceOrder: if `true`, consecutive lookups will use the oldest timestamp from the previous event as their
    ///                   from date.
    ///   - handler: contains an `EventHistoryResult` for each provided request.
    func getEvents(_ requests: [EventHistoryRequest],
                   enforceOrder: Bool,
                   handler: @escaping ([EventHistoryResult]) -> Void)

    /// Deletes events with matching hashes to those provided in `requests`.
    ///
    /// - Parameters:
    ///   - requests: an array of `EventHistoryRequest`s used to generate the hash and timeframe for the event lookup.
    ///   - handler: called with the number of records deleted.
    func deleteEvents(_ requests: [EventHistoryRequest], handler: ((Int) -> Void)?)
}
