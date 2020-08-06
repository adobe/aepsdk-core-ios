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

/// Implementation of the `Traversable` protocol which will be used by `SwiftRulesEngine`
struct TokenFinder: Traversable {
    func get(key: String) -> Any? { return nil }
    private let TOKEN_KEY_EVENT_TYPE = "~type"
    private let TOKEN_KEY_EVENT_SOURCE = "~source"
    private let TOKEN_KEY_TIMESTAMP_UNIX = "~timestampu"
    private let TOKEN_KEY_TIMESTAMP_ISO8601 = "~timestampz"
    private let TOKEN_KEY_TIMESTAMP_PLATFORM = "~timestampp"
    private let TOKEN_KEY_SDK_VERSION = "~sdkver"
    private let TOKEN_KEY_CACHEBUST = "~cachebust"
    private let TOKEN_KEY_ALL_URL = "~all_url"
    private let TOKEN_KEY_ALL_JSON = "~all_json"
    private let TOKEN_KEY_SHARED_STATE = "~state"
    private let KEY_PREFIX = "~"
    private let EMPTY_STRING = ""
    private let RANDOM_INT_BOUNDARY = 100000000
    private let TOKEN_KEY_SHARED_STATE_PREFIX_COM = "com"
    private let TOKEN_KEY_SHARED_STATE_PREFIX_COM_INDEX = 1
    private let TOKEN_KEY_SHARED_STATE_PREFIX_ADOBE = "adobe"
    private let TOKEN_KEY_SHARED_STATE_PREFIX_ADOBE_INDEX = 2
    private let TOKEN_KEY_SHARED_STATE_PREFIX_MODULE = "module"
    private let TOKEN_KEY_SHARED_STATE_PREFIX_MODULE_INDEX = 3
    private let TOKEN_KEY_SHARED_STATE_PREFIX_EXTENSION_DESC_SEPARATOR: Character = "/"
    private let TOKEN_KEY_SHARED_STATE_PREFIX_EXTENSION_DESC_INDEX = 4
    private let LOG_TAG = "TokenFinder"
    
    let event: Event
    let extensionRuntime: ExtensionRuntime
    let now = Date()
    var cachedSharedStateDataItem = [String: Any]()
    
    subscript(traverse _: String) -> Any? {
        return nil
    }
    
    /// Overrides default behavior provided by `Traversable` protocol
    /// `TokenFinder` will not fetch all tokens and values when initializing itself, this function will find the right token value when needed and cache it for future usage in the same `TokenFinder` instance.
    subscript(path path: [String]) -> Any? {
        mutating get {
            guard path.count != 0 else {
                Log.warning(label: LOG_TAG, "Invalid input, provided path has no content")
                return nil
            }
            Log.debug(label: LOG_TAG, "Starts to find the token (\(path)) in current context")
            if path[0].hasPrefix(KEY_PREFIX) {
                if path.count == 1 {
                    switch path[0] {
                    case TOKEN_KEY_EVENT_TYPE:
                        return event.type
                    case TOKEN_KEY_EVENT_SOURCE:
                        return event.source
                    case TOKEN_KEY_TIMESTAMP_UNIX:
                        return now.getUnixTimeInSeconds()
                    case TOKEN_KEY_TIMESTAMP_ISO8601:
                        return now.getRFC822Date()
                    case TOKEN_KEY_TIMESTAMP_PLATFORM:
                        return now.getISO8601Date()
                    case TOKEN_KEY_SDK_VERSION:
                        return MobileCore.version
                    case TOKEN_KEY_CACHEBUST:
                        return String(Int.random(in: 1..<RANDOM_INT_BOUNDARY))
                    case TOKEN_KEY_ALL_URL:
                        guard let dict = event.data else {
                            Log.debug(label: LOG_TAG, "Current event data is nil, can not use it to generate an url query string")
                            return EMPTY_STRING
                        }
                        return URLUtility.generateQueryString(parameters: EventDataFlattener.getFlattenedDataDict(eventData: dict))
                    case TOKEN_KEY_ALL_JSON:
                        return generateJsonString(AnyCodable.from(dictionary: event.data))
                    default:
                        return nil
                    }
                } else if path[0] == TOKEN_KEY_SHARED_STATE {
                    guard TOKEN_KEY_SHARED_STATE_PREFIX_COM.isEqual(to: path[safe: TOKEN_KEY_SHARED_STATE_PREFIX_COM_INDEX]),
                        TOKEN_KEY_SHARED_STATE_PREFIX_ADOBE.isEqual(to: path[safe: TOKEN_KEY_SHARED_STATE_PREFIX_ADOBE_INDEX]),
                        TOKEN_KEY_SHARED_STATE_PREFIX_MODULE.isEqual(to: path[safe: TOKEN_KEY_SHARED_STATE_PREFIX_MODULE_INDEX]) else {
                        Log.warning(label: LOG_TAG, "Invalid format, the provided token string (\(path)) can't comply with a shared state key")
                        return nil
                    }
                    guard let extensionString = path[safe: TOKEN_KEY_SHARED_STATE_PREFIX_EXTENSION_DESC_INDEX], let extensionName = extensionString.split(separator: TOKEN_KEY_SHARED_STATE_PREFIX_EXTENSION_DESC_SEPARATOR)[safe: 0] else {
                        Log.warning(label: LOG_TAG, "Invalid format, can't find an extension name from provided token string (\(path)) ")
                        return nil
                    }
                    guard let data = extensionRuntime.getSharedState(extensionName: String(extensionName), event: event)?.value else {
                        Log.warning(label: LOG_TAG, "Can not find the shared state of extension [\(extensionName)]")
                        return nil
                    }
                    guard path.count >= 5, let dataKey = generateEventDataKey(path: Array(path[5..<path.count])) else {
                        Log.warning(label: LOG_TAG, "Failed to extract a shared state's data key from provided token string (\(path)) ")
                        return nil
                    }
                    if let cachedValue = cachedSharedStateDataItem[dataKey] {
                        return cachedValue
                    }
                    let flattenedData = EventDataFlattener.getFlattenedDataDict(eventData: data)
                    cachedSharedStateDataItem[dataKey] = flattenedData[dataKey]
                    return flattenedData[dataKey]
                    
                } else {
                    Log.warning(label: LOG_TAG, "Can't extract a token from provided token string (\(path)) ")
                    return nil
                }
                
            } else {
                guard let dataKey = generateEventDataKey(path: path) else {
                    Log.warning(label: LOG_TAG, "Failed to extract a data key from provided token string (\(path)) ")
                    return nil
                }
                guard let dict = event.data else {
                    Log.debug(label: LOG_TAG, "Current event data is nil, can not use it to do token replacement")
                    return ""
                }
                return EventDataFlattener.getFlattenedDataDict(eventData: dict)[dataKey]
            }
        }
    }
    
    private func generateJsonString(_ data: [String: AnyCodable]?) -> String? {
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(data) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        return nil
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
