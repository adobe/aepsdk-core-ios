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
import AEPServices

/// Represents an Object which is Cachable via the CacheService
protocol Cacheable {
    
    /// The cachable Dictionary
    var cacheableDict: [String: AnyCodable] { get }
    
    /// Date this cachable was last modified on the server, read from the Last-Modified HTTP header
    /// Format: <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
    var lastModified: String? { get }
    
    /// ETag of the cachable on the server
    var eTag: String? { get }
}

extension Cacheable {
    func notModifiedHeaders() -> [String: String] {
        return [NetworkServiceConstants.Headers.IF_MODIFIED_SINCE_HEADER: lastModified ?? "",
                NetworkServiceConstants.Headers.IF_NONE_MATCH: eTag ?? ""]
    }
}
