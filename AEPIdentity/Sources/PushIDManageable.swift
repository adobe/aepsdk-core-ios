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

import AEPCore
import AEPServices
import Foundation

/// Defines instances that can manage a push identifier
protocol PushIDManageable {
    /// Creates a new `PushIDManageable`
    /// - Parameters:
    ///   - dataStore: the datastore to store push data in
    ///   - eventDispatcher: a function which can dispatch an `Event` to the `EventHub`
    init(dataStore: NamedCollectionDataStore, eventDispatcher: @escaping (Event) -> Void)

    /// Updates the push identifier
    /// - Parameter pushId: the new push identifier
    mutating func updatePushId(pushId: String?)

    /// Resets persisted push flags to false
    mutating func resetPersistedFlags()
}
