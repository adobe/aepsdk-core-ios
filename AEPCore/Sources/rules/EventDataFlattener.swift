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

class EventDataFlattener {
    static func getFlattenedDataDict(eventData: [String: Any]) -> [String: Any] {
        var flattenedDict = [String: Any]()
        for (key, value) in eventData {
            if let subDict = value as? [String: Any] {
                flattenedDict.merge(dict: flatten(key: key, eventData: subDict))
            } else {
                flattenedDict[key] = value
            }
        }
        return flattenedDict
    }

    private static func flatten(key: String, eventData: [String: Any]) -> [String: Any] {
        var flattenedDict = [String: Any]()
        for (subKey, value) in eventData {
            let newKey = key + "." + subKey
            if let subDict = value as? [String: Any] {
                flattenedDict.merge(dict: flatten(key: newKey, eventData: subDict))
            } else {
                flattenedDict[newKey] = value
            }
        }
        return flattenedDict
    }
}

extension Dictionary {
    mutating func merge<K, V>(dict: [K: V]) {
        for (k, v) in dict {
            updateValue(v as! Value, forKey: k as! Key)
        }
    }
}
