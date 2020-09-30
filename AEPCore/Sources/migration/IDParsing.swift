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

/// Defines types who can parse visitor id strings into dictionary representations
protocol IDParsing {

    /// Converts a `String` of visitor ids to an array of dictionary representations of each id in the `String`
    /// - Parameter idString: The `String` containing the ids
    /// - Returns: A list of dictionaries, where each dictionary represents a single id
    func convertStringToIds(idString: String?) -> [[String: Any]]
}
