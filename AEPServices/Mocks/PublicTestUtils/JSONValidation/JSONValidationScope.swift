/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import Foundation

/// Represents the scope of a validation option.
///
/// When applying an option to a path, the scope determines whether the option
/// applies only to that specific node or to the entire subtree beneath it.
public enum JSONValidationScope: String, Hashable {
    /// Only this node should apply the current configuration.
    case singleNode
    
    /// This node and all descendants should apply the current configuration.
    case subtree
}

extension JSONValidationScope: CustomStringConvertible {
    public var description: String {
        switch self {
        case .singleNode: return "Node"
        case .subtree: return "Tree"
        }
    }
}



