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

extension String {
    /// Compare itself to another string
    /// - Parameter aString: The `String` to compare this `String` against
    /// - Returns: `true` if the arguments is not `nil` and it represents an equivalent `String`; `false` otherwise
    func isEqual(to aString: String?) -> Bool {
        guard let newString = aString else {
            return false
        }
        return self == newString
    }
}
