/// *
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
// */
//
import Foundation

/// Represents the service for performing namespaced read/writes of AnyCodable values
public protocol NamedCollectionProcessing {
    /// Set the name of the app group that will be used to store the data
    /// - Parameter appGroup: The app group name
    func setAppGroup(_ appGroup: String?)

    /// Gets the app group
    /// - Returns: The app group if set
    func getAppGroup() -> String?

    /// Sets the value for key in the collection with the given name
    /// - Parameter collectionName: The collection name used for namespacing
    /// - Parameter key: The key to be used to set the value
    /// - Parameter value: The AnyCodable? to be set in the collection
    func set(collectionName: String, key: String, value: Any?)

    /// Gets the value for key in the collection with the given name
    /// - Parameter collectionName: The collection name used for namespacing
    /// - Parameter key: The key to be used to get the value
    /// - Return: `AnyCodable` the value returned from the collection
    func get(collectionName: String, key: String) -> Any?

    /// Removes the value for key in the collection with the given name
    /// - Parameter collectionName: The collection name used for namespacing
    /// - Parameter key: The key to be used to remove the value
    func remove(collectionName: String, key: String)
}
