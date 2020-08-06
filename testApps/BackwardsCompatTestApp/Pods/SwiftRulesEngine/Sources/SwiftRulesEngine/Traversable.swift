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

/// A type that can be traversed by the rules engine to retrieve a certain key/value pair.
public protocol Traversable {
    func get(key: String) -> Any?
}

extension Traversable {
    subscript(path path: [String]) -> Any? {
        let result = path.reduce(self as Any?) {
            switch $0 {
            case is Traversable:
                return ($0 as! Traversable).get(key: $1)
            default:
                return nil
            }
        }
        return result
    }
}
