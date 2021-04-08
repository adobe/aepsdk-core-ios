/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

public enum PrettyDictionary {

    /// Converts a String-Any dictionary to a prettified JSON string
    ///
    /// - Parameter dictionary: `Dictionary` to be prettified
    /// - Returns: `JSON` string
    public static func prettify(_ dictionary: [String: Any?]?) -> String {
        guard let dictionary = dictionary else {
            return ""
        }
        guard JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
              let prettyPrintedString = String(data: data, encoding: String.Encoding.utf8) else {
            return " \(dictionary as AnyObject)"
        }
        return prettyPrintedString
    }
}
