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

/// Represents an entity type which can be stored in `DataQueue`
@objc(AEPDataEntity)
public class DataEntity: NSObject {
    public let uniqueIdentifier: String
    public let timestamp: Date
    public let data: Data?

    /// Generates a new `DataEntity`
    ///
    /// This init method automatically assigns a random `UUID` to `uniqueIdentifier` and sets `timestamp` to `Date()`
    ///
    /// - Parameters:
    ///   - data: a JSON-encoded representation for `DataEntity`
    public init(data: Data?) {
        uniqueIdentifier = UUID().uuidString
        timestamp = Date()
        self.data = data
    }

    /// Generates a new `DataEntity`
    /// - Parameters:
    ///   - uniqueIdentifier: a string identifier for `DataEntity`
    ///   - timestamp: a timestamp for `DataEntity`
    ///   - data: a JSON-encoded representation for `DataEntity`
    public init(uniqueIdentifier: String, timestamp: Date, data: Data?) {
        self.uniqueIdentifier = uniqueIdentifier
        self.timestamp = timestamp
        self.data = data
    }
}
