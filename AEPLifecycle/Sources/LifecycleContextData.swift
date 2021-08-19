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

/// Represents context data collected from the Lifecycle extension
struct LifecycleContextData {
    var lifecycleMetrics: LifecycleMetrics = LifecycleMetrics()
    var sessionContextData: [String: Any] = [String: Any]()
    var additionalContextData: [String: Any] = [String: Any]()
    var advertisingIdentifier: String?

    init() {}

    /// Merges the other `LifecycleContextData` into this, any duplicate keys will resolve the value that is contained within the other `LifecycleContextData`
    /// - Parameters:
    ///   - with: The other `LifecycleContextData` to be merged with
    func merging(with: LifecycleContextData?) -> LifecycleContextData {
        guard let selfDict = toDictionary(), let otherDict = with?.toDictionary() else { return self }

        let mergedDict = selfDict.merging(otherDict) { (selfValue, otherValue) -> Any in
            // properly merge sub dictionaries
            if let selfSubDict = selfValue as? [String: Any], let otherSubDict = otherValue as? [String: Any] {
                return selfSubDict.merging(otherSubDict, uniquingKeysWith: { _, new in new })
            }

            return otherValue
        }

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

    /// Flattens the context data into a dictionary to be used in event data
    /// - Returns: The context data flattened into the event data format
    func toEventData() -> [String: Any] {
        let selfDict = toDictionary()
        var eventData = [String: Any]()

        if let advertisingIdentifier = advertisingIdentifier {
            eventData[CodingKeys.advertisingIdentifier.rawValue] = advertisingIdentifier
        }

        if let metricsDict = selfDict?[CodingKeys.lifecycleMetrics.stringValue] as? [String: Any] {
            eventData = eventData.merging(metricsDict, uniquingKeysWith: { _, new in new })
        }

        if let additionalContextDataDict = selfDict?[CodingKeys.additionalContextData.stringValue] as? [String: Any] {
            eventData = eventData.merging(additionalContextDataDict, uniquingKeysWith: { _, new in new })
        }

        if let sessionContextDataDict = selfDict?[CodingKeys.sessionContextData.stringValue] as? [String: Any] {
            eventData = eventData.merging(sessionContextDataDict, uniquingKeysWith: { _, new in new })
        }

        return eventData
    }
}

extension LifecycleContextData: Equatable {
    static func == (lhs: LifecycleContextData, rhs: LifecycleContextData) -> Bool {
        return lhs.lifecycleMetrics == rhs.lifecycleMetrics
            && NSDictionary(dictionary: lhs.sessionContextData).isEqual(to: rhs.sessionContextData)
            && NSDictionary(dictionary: lhs.additionalContextData).isEqual(to: rhs.additionalContextData)
            && lhs.advertisingIdentifier == rhs.advertisingIdentifier
    }
}

extension LifecycleContextData: Codable {
    enum CodingKeys: String, CodingKey {
        case lifecycleMetrics
        case sessionContextData
        case additionalContextData = "additionalcontextdata"
        case advertisingIdentifier = "advertisingidentifier"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        lifecycleMetrics = try values.decode(LifecycleMetrics.self, forKey: .lifecycleMetrics)
        let anyCodableSessionData = try? values.decode([String: AnyCodable].self, forKey: .sessionContextData)
        sessionContextData = AnyCodable.toAnyDictionary(dictionary: anyCodableSessionData) ?? [:]
        let anyCodableAdditionalData = try? values.decode([String: AnyCodable].self, forKey: .additionalContextData)
        additionalContextData = AnyCodable.toAnyDictionary(dictionary: anyCodableAdditionalData) ?? [:]
        advertisingIdentifier = try? values.decode(String.self, forKey: .advertisingIdentifier)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(lifecycleMetrics, forKey: .lifecycleMetrics)
        try container.encode(AnyCodable.from(dictionary: sessionContextData), forKey: .sessionContextData)
        try container.encode(AnyCodable.from(dictionary: additionalContextData), forKey: .additionalContextData)
        try container.encode(advertisingIdentifier, forKey: .advertisingIdentifier)
    }
}
