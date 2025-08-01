/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import AEPServices

/// Provides CRUD support for storing `Event` objects in a local database.
class EventHistory: EventHistoryProvider {
    let LOG_TAG = "EventHistory"
    let storage: EventHistoryStore

    /// Initializes a new `EventHistory` instance with the provided storage or a default implementation.
    ///
    /// If a custom `EventHistoryStore` is provided, it will be used for event history operations.
    /// If `nil` is provided, the initializer attempts to create a default `EventHistoryDatabase`
    /// backed by a new serial `DispatchQueue`.
    ///
    /// - Parameter storage: An optional `EventHistoryStore` to use. If `nil`, a default `EventHistoryDatabase` is created.
    /// - Returns: `nil` if no storage is provided and the default `EventHistoryDatabase` fails to initialize.
    init?(storage: EventHistoryStore? = nil) {
        // Use the provided storage if available.
        // Otherwise, attempt to initialize a default `EventHistoryDatabase`.
        guard let storage = storage ?? EventHistoryDatabase(dispatchQueue: DispatchQueue(label: "EventHistory")) else {
            return nil
        }
        self.storage = storage
    }

    /// Records an `Event` based on its calculated hash.
    ///
    /// The hash is generated based on the provided `event`'s data.
    /// The `event`'s `mask` value, if provided, will filter what values in the event data are used for hash generation.
    /// If the hash value for the provided `event` is `0`, no record will be created in event history.
    ///
    /// - Parameters:
    ///   - event: the `Event` to be recorded in event history.
    ///   - handler: called with `true` if the event was successfully recorded, `false` otherwise.
    func recordEvent(_ event: Event, handler: ((Bool) -> Void)? = nil) {
        guard event.eventHash != 0 else {
            Log.debug(label: LOG_TAG, "Failed to record event in history - event hash is 0")
            handler?(false)
            return
        }

        storage.insert(hash: event.eventHash, timestamp: event.timestamp, handler: handler)
    }

    /// Retrieves a count of historical events matching the provided requests.
    ///
    /// - Parameters:
    ///   - requests: an array of `EventHistoryRequest`s used to generate the hash and timeframe for the event lookup.
    ///   - enforceOrder: if `true`, consecutive lookups will use the oldest timestamp from the previous event as their
    ///                   from date.
    ///   - handler: contains an `EventHistoryResult` for each provided request.
    func getEvents(_ requests: [EventHistoryRequest], enforceOrder: Bool, handler: @escaping ([EventHistoryResult]) -> Void) {
        var results: [EventHistoryResult] = []

        if enforceOrder {
            var previousEventOldestOccurrence: Date?
            for event in requests {
                let eventHash = event.mask.fnv1a32()
                let from = previousEventOldestOccurrence ?? event.fromDate
                let semaphore = DispatchSemaphore(value: 0)
                storage.select(hash: eventHash, from: from, to: event.toDate) { result in
                    Log.trace(label: "EventHistory", "EventHistoryRequest[\(event.hashValue)] - request for events with hash (\(eventHash)) between (\(from?.millisecondsSince1970 ?? 0)) and (\(event.toDate?.millisecondsSince1970 ?? 0)) with enforceOrder enabled returned \(result.count) record(s).")
                    previousEventOldestOccurrence = result.oldestOccurrence
                    results.append(result)
                    semaphore.signal()
                }
                semaphore.wait()
            }
        } else {
            for event in requests {
                let semaphore = DispatchSemaphore(value: 0)
                let eventHash = event.mask.fnv1a32()
                storage.select(hash: eventHash, from: event.fromDate, to: event.toDate) { result in
                    Log.trace(label: "EventHistory", "EventHistoryRequest[\(event.hashValue)] - request for events with hash (\(eventHash)) between (\(event.fromDate?.millisecondsSince1970 ?? 0)) and (\(event.toDate?.millisecondsSince1970 ?? 0)) with enforceOrder disabled returned \(result.count) record(s).")
                    results.append(result)
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }

        handler(results)
    }

    /// Deletes events with matching hashes to those provided in `requests`.
    ///
    /// - Parameters:
    ///   - requests: an array of `EventHistoryRequest`s used to generate the hash and timeframe for the event lookup.
    ///   - handler: called with the number of records deleted.
    func deleteEvents(_ requests: [EventHistoryRequest], handler: ((Int) -> Void)? = nil) {
        var rowsDeleted = 0
        for request in requests {
            let semaphore = DispatchSemaphore(value: 0)
            storage.delete(hash: request.mask.fnv1a32(), from: request.fromDate, to: request.toDate) { count in
                rowsDeleted += count
                semaphore.signal()
            }
            semaphore.wait()
        }

        handler?(rowsDeleted)
    }
}
