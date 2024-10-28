//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices

extension AnyCodable: CustomStringConvertible {
    /// Converts `AnyCodable`'s default decode strategy of array `[Any?]`  into `[AnyCodable]` value type
    public static func from(array: [Any?]?) -> [AnyCodable]? {
        guard let unwrappedArray = array else { return nil }

        var newArray: [AnyCodable] = []
        for val in unwrappedArray {
            if let anyCodableVal = val as? AnyCodable {
                newArray.append(anyCodableVal)
            } else {
                newArray.append(AnyCodable(val))
            }
        }

        return newArray
    }

    /// Convenience string description that prints a pretty JSON output of an `AnyCodable` instance without all the `Optional` and `AnyCodable` type wrappers in the output string
    public var description: String {
        if let anyCodableData = try? JSONEncoder().encode(self),
           let jsonObject = try? JSONSerialization.jsonObject(with: anyCodableData),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            return String(decoding: jsonData, as: UTF8.self)
        } else {
            return "\(String(describing: self.value))"
        }
    }

}
