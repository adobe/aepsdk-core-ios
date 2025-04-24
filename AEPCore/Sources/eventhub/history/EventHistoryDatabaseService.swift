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

protocol EventHistoryDatabaseService {
    /// Inserts a record in the EventHistory database.
    ///
    /// Fails if a connection to the database cannot be established, and calls the `handler` with a value of `false`.
    ///
    /// - Parameters:
    ///   - hash: the hashed value representing an event.
    ///   - timestamp: the event timestamp
    ///   - handler: called with the `Bool` result of the insert statement.
    func insert(hash: UInt32, timestamp: Date, handler: ((Bool) -> Void)?)

    /// Queries the event history database to search for existence of an event.
    ///
    /// This method will count all records in the event history database that match the provided `hash` and are within
    /// the bounds of the provided `from` and `to` date.
    ///
    /// If no `from` date is provided, the search will use the beginning of event history
    /// as the lower bounds of the date range.
    ///
    /// If no `to` date is provided, the search will use `now` as the upper bounds
    /// of the date range.
    ///
    /// The `handler` will be called with an `EventHistoryResult`.
    ///
    /// If no database connection is available, the handler will be called with a count of 0.
    /// If there are no matching records, the handler will be called with count of 0.
    ///
    /// - Parameters:
    ///   - hash: the 32-bit FNV-1a hashed representation of an Event's data.
    ///   - from: represents the lower bounds of the date range to use when searching for the hash
    ///   - to: represents the upper bounds of the date range to use when searching for the hash
    ///   - handler: a callback which will contain `EventHistoryResult` representing matching events
    func select(hash: UInt32, from: Date?, to: Date?, handler: @escaping (EventHistoryResult) -> Void)

    /// Deletes records with a matching `hash` between the `from` and `to` values provided.
    ///
    /// If no `from` date is provided, the search will use the beginning of event history
    /// as the lower bounds of the date range.
    ///
    /// If no `to` date is provided, the search will use `now` as the upper bounds
    /// of the date range.
    ///
    /// - Parameters:
    ///   - hash: the 32-bit FNV-1a hashed representation of an Event's data.
    ///   - from: represents the lower bounds of the date range to use when searching for the hash
    ///   - to: represents the upper bounds of the date range to use when searching for the hash
    ///   - handler: a callback which will contain the number of records deleted
    func delete(hash: UInt32, from: Date?, to: Date?, handler: ((Int) -> Void)?)
}
