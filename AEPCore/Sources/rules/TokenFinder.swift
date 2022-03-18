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
import AEPRulesEngine

extension String {
    /// Returns the first index of the character in this `String`
    /// - Parameter char: character to be indexed
    /// - Returns: The index of `char` in this `String`, otherwise nil
    fileprivate func indexOf(char: Character) -> Int? {
        return firstIndex(of: char)?.utf16Offset(in: self)
    }

    fileprivate func substring(from: Int, to: Int) -> String {
        let startIndex = index(self.startIndex, offsetBy: from)
        let endIndex = index(self.startIndex, offsetBy: to)
        return String(self[startIndex ... endIndex])
    }
}

/// Implementation of the `Traversable` protocol which will be used by `AEPRulesEngine`
class TokenFinder: Traversable {
    private let LOG_TAG = "TokenFinder"

    private let TOKEN_KEY_EVENT_TYPE = "~type"
    private let TOKEN_KEY_EVENT_SOURCE = "~source"
    private let TOKEN_KEY_TIMESTAMP_UNIX = "~timestampu"
    private let TOKEN_KEY_TIMESTAMP_ISO8601_NO_COLON = "~timestampz"
    private let TOKEN_KEY_TIMESTAMP_ISO8601_UTC_MILLISECONDS = "~timestampp"
    private let TOKEN_KEY_SDK_VERSION = "~sdkver"
    private let TOKEN_KEY_CACHEBUST = "~cachebust"
    private let TOKEN_KEY_ALL_URL = "~all_url"
    private let TOKEN_KEY_ALL_JSON = "~all_json"
    private let TOKEN_KEY_SHARED_STATE = "~state"
    private let EMPTY_STRING = ""
    private let RANDOM_INT_BOUNDARY = 100_000_000

    let event: Event
    let extensionRuntime: ExtensionRuntime
    let now = Date()

    init(event: Event, extensionRuntime: ExtensionRuntime) {
        self.event = event
        self.extensionRuntime = extensionRuntime
    }

    /// Implement the `Traversable` protocol. Retrieve the token value for the specific key.
    /// - Parameter key: the token name
    func get(key: String) -> Any? {
        switch key {
        case TOKEN_KEY_EVENT_TYPE:
            return event.type
        case TOKEN_KEY_EVENT_SOURCE:
            return event.source
        case TOKEN_KEY_TIMESTAMP_UNIX:
            return Int(truncatingIfNeeded: now.getUnixTimeInSeconds())
        case TOKEN_KEY_TIMESTAMP_ISO8601_NO_COLON:
            return now.getISO8601DateNoColon()
        case TOKEN_KEY_TIMESTAMP_ISO8601_UTC_MILLISECONDS:
            return now.getISO8601UTCDateWithMilliseconds()
        case TOKEN_KEY_SDK_VERSION:
            return MobileCore.extensionVersion
        case TOKEN_KEY_CACHEBUST:
            return String(Int.random(in: 1 ..< RANDOM_INT_BOUNDARY))
        case TOKEN_KEY_ALL_URL:
            guard let dict = event.data else {
                Log.debug(label: LOG_TAG, "Current event data is nil, can not use it to generate an url query string")
                return EMPTY_STRING
            }
            return URLUtility.generateQueryString(parameters: dict.flattening())
        case TOKEN_KEY_ALL_JSON:
            return generateJsonString(AnyCodable.from(dictionary: event.data))

        default:
            if key.starts(with: TOKEN_KEY_SHARED_STATE) {
                return getValueFromSharedState(key: key)
            }

            return getValueFromEvent(key: key)
        }
    }

    private func getValueFromSharedState(key: String) -> Any? {
        guard let index = key.indexOf(char: "/") else {
            return nil
        }
        let extensionName = key.substring(from: TOKEN_KEY_SHARED_STATE.count + 1, to: index - 1)
        let dataKeyName = key.substring(from: index + 1, to: key.count - 1)

        guard let data = extensionRuntime.getSharedState(extensionName: String(extensionName), event: event, barrier: false)?.value else {
            Log.trace(label: LOG_TAG, "Can not find the shared state of extension [\(extensionName)]")
            return nil
        }

        let flattenedData = data.flattening()
        return flattenedData[dataKeyName]
    }

    private func getValueFromEvent(key: String) -> Any? {
        guard let dict = event.data else {
            Log.trace(label: LOG_TAG, "Current event data is nil, can not use it to do token replacement")
            return ""
        }
        return dict.flattening()[key]
    }

    private func generateJsonString(_ data: [String: AnyCodable]?) -> String {
        guard let data = data else {
            return ""
        }
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(data) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        return ""
    }
}
