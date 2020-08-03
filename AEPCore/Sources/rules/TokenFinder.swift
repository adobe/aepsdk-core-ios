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

import AEPServices
import Foundation
@_implementationOnly import SwiftRulesEngine

struct TokenFinder: Traversable {
    private static let TOKEN_KEY_EVENT_TYPE = "~type"
    private static let TOKEN_KEY_EVENT_SOURCE = "~source"
    private static let TOKEN_KEY_TIMESTAMP_UNIX = "~timestampu"
    private static let TOKEN_KEY_TIMESTAMP_ISO8601 = "~timestampz"
    private static let TOKEN_KEY_TIMESTAMP_PLATFORM = "~timestampp"
    private static let TOKEN_KEY_SDK_VERSION = "~sdkver"
    private static let TOKEN_KEY_CACHEBUST = "~cachebust"
    private static let TOKEN_KEY_ALL_URL = "~all_url"
    private static let TOKEN_KEY_ALL_JSON = "~all_json"
    private static let TOKEN_KEY_SHARED_STATE = "~state"
    
    let event: Event
    let extensionRuntime: ExtensionRuntime
    let now = Date()
    var cachedSharedStateDataItem = [String: Any]()
    subscript(traverse _: String) -> Any? {
        return nil
    }
    
    subscript(path path: [String]) -> Any? {
        mutating get {
            guard path.count != 0 else {
                return nil
            }
            if path[0].hasPrefix("~") {
                if path.count == 1 {
                    switch path[0] {
                    case TokenFinder.TOKEN_KEY_EVENT_TYPE:
                        return event.type.rawValue
                    case TokenFinder.TOKEN_KEY_EVENT_SOURCE:
                        return event.source.rawValue
                    case TokenFinder.TOKEN_KEY_TIMESTAMP_UNIX:
                        return now.getUnixTimeInSeconds()
                    case TokenFinder.TOKEN_KEY_TIMESTAMP_ISO8601:
                        return now.getRFC822Date()
                    case TokenFinder.TOKEN_KEY_TIMESTAMP_PLATFORM:
                        return now.getISO8601Date()
                    case TokenFinder.TOKEN_KEY_SDK_VERSION:
                        return MobileCore.version
                    case TokenFinder.TOKEN_KEY_CACHEBUST:
                        return String(Int.random(in: 1..<100000000))
                    case TokenFinder.TOKEN_KEY_ALL_URL:
                        guard let dict = event.data else {
                            return ""
                        }
                        return URLUtility.generateQueryString(parameters: EventDataFlattener.getFlattenedDataDict(eventData: dict))
                    case TokenFinder.TOKEN_KEY_ALL_JSON:
                        break
                        
                    default:
                        break
                    }
                } else if path[0] == TokenFinder.TOKEN_KEY_SHARED_STATE {
                    guard path[safe: 1]?.isEqual(to: "com") ?? false, path[safe: 2]?.isEqual(to: "adobe") ?? false, path[safe: 3]?.isEqual(to: "module") ?? false else {
                        return nil
                    }
                    guard let extensionString = path[safe: 4], let extensionName = extensionString.split(separator: "/")[safe: 0] else {
                        return nil
                    }
                    guard let data = extensionRuntime.getSharedState(extensionName: String(extensionName), event: event)?.value, let dataKey = generateEventDataKey(path: Array(path[5..<path.count])) else {
                        // error: shared state not found
                        return nil
                    }
                    if let cachedValue = cachedSharedStateDataItem[dataKey] {
                        return cachedValue
                    }
                    let flattenedData = EventDataFlattener.getFlattenedDataDict(eventData: data)
                    cachedSharedStateDataItem[dataKey] = flattenedData[dataKey]
                    return flattenedData[dataKey]
                    
                } else {
                    // error
                }
                
            } else {
                guard let dataKey = generateEventDataKey(path: path) else {
                    return nil
                }
                guard let dict = event.data else {
                    return ""
                }
                return EventDataFlattener.getFlattenedDataDict(eventData: dict)[dataKey]
            }
            return nil
        }
    }
    
    private func generateEventDataKey(path: [String]) -> String? {
        guard path.count > 0 else {
            return nil
        }
        var key = ""
        for item in path {
            key += "\(item)."
        }
        key.removeLast()
        return key
    }
}

extension String {
    func isEqual(to aString: String) -> Bool {
        return self == aString
    }
}

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard count > index else {
            return nil
        }
        return self[index]
    }
}

class URLUtility {
    static func generateQueryString(parameters: [String: Any]) -> String {
        var queryString = ""
        guard parameters.count > 0 else {
            return queryString
        }
        for (key, value) in parameters {
            if let array = value as? [Any], let arrayValue = URLUtility.joinArray(array: array) {
                queryString += "\(generateKVP(key: key, value: arrayValue))&"
            } else {
                queryString += "\(generateKVP(key: key, value: String(describing: value)))&"
            }
            queryString.removeLast()
        }
        return queryString
    }
    
    private static func generateKVP(key: String, value: String) -> String {
        return "\(key)=\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    private static func joinArray(array: [Any]) -> String? {
        guard array.count > 0 else {
            return nil
        }
        var string = ""
        for item in array {
            string += "\(item),"
        }
        string.removeLast()
        return string
    }
}
