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

public extension Date {
    func getUnixTimeInSeconds() -> Int64 {
        return Int64(timeIntervalSince1970)
    }

    func getRFC822Date() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd'T'HH:mm:ssZZZ")
        return formatter.string(from: self)
    }

    func getISO8601Date() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd'T'HH:mm:ssXXX")
        return formatter.string(from: self)
    }
}
