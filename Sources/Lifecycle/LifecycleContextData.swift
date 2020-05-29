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

/// Represents context data collected from the Lifecycle extension
struct LifecycleContextData: Codable {
    var lifecycleMetrics: LifecycleMetrics = LifecycleMetrics()
    var sessionContextData: [String: String] = [String: String]()
    var additionalContextData: [String: String] = [String: String]()
    var advertisingIdentifier: String?
    
    init() {}
    
    /// Merges the other `LifecycleContextData` with the `conflictResolver`
    /// - Parameters:
    ///   - with: The other `LifecycleContextData` to be merged with
    ///   - conflictResolver: A closure that takes the current and new values for any duplicate keys. The closure returns the desired value for the final `LifecycleContextData`.
    func merging(with: LifecycleContextData?, uniquingKeysWith conflictResolver: (Any, Any) throws -> Any) -> LifecycleContextData {
        guard let selfDict = toDictionary(), let otherDict = with?.toDictionary() else { return self }
        
        let mergedDict = try? selfDict.merging(otherDict, uniquingKeysWith: conflictResolver)
        guard let mergedDictData = try? JSONSerialization.data(withJSONObject: mergedDict as Any, options: []) else { return self }
        let mergedContextData = try? JSONDecoder().decode(LifecycleContextData.self, from: mergedDictData)
        return mergedContextData ?? self
    }
    
    /// Converts this `LifecycleContextData` into a `[String: String]?` dictionary
    /// - Returns: A dictionary representation of the `LifecycleContextData`
    private func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}
