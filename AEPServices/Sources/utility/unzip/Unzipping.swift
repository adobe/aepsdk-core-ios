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

///
/// File Unzipping protocol
///
public protocol Unzipping {
    ///
    /// Unzips a file at a given source url to a destination url
    /// - Paramaters:
    ///     - sourceURL: The URL pointing to the file to be unzipped
    ///     - destinationURL: The URL pointing to the destination where the unzipped contents will go
    /// - Returns: A list of names of each of the unzipped files
    func unzipItem(at sourceURL: URL, to destinationURL: URL) -> [String]
}
