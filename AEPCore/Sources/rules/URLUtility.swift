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

class URLUtility {
    /// Converts a dictionary to a string which comply with "URL Query String"
    /// - Parameter parameters: the dictionary to be converted
    /// - Returns: resulted query string
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
        }
        if queryString.count > 0 { queryString.removeLast() }
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
