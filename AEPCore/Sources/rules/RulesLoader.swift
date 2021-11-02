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

/// Defines a type which can load rules from cache, or download the rules remotely
protocol RulesLoader {
    /// Loads the cached rules for `appId`.
    /// - Parameter rulesUrl: rulesUrl, if provided the `RulesDownloader` will attempt to load a rules with `appId`
    /// - Returns: The cached rules for `appId` in `DiskCache`, nil if not found
    func loadRulesFromCache(rulesUrl: URL) -> Data?

    /// Loads the remote rules for `appId` and caches the result.
    /// - Parameters:
    ///   - appId: Optional app id, if provided the `RulesDownloader` will attempt to download rules with `appId`
    ///   - completion: Invoked with the loaded rules, nil if loading the rules failed. NOTE: Fails if 304 not-modified is returned from the server
    func loadRulesFromUrl(rulesUrl: URL, completion: @escaping (Result<Data, RulesDownloaderError>) -> Void)
}
