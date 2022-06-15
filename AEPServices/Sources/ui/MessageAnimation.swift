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
#if os(iOS)
    import Foundation

    /// A MessageAnimation represents the type of animation that should be used when displaying or dismissing a message.
    @objc (AEPMessageAnimation)
    public enum MessageAnimation: Int {
        case none = 0
        case left = 1
        case right = 2
        case top = 3
        case bottom = 4
        case center = 5
        case fade = 6

        /// Converts a `String` to its respective `MessageAnimation`
        /// If `string` is not a valid `MessageAnimation`, calling this method will return `.none`
        /// - Parameter string: a `String` representation of a `MessageAnimation`
        /// - Returns: a `MessageAnimation` representing the passed-in `String`
        public static func fromString(_ string: String) -> MessageAnimation {
            switch string {
            case "none":
                return .none
            case "left":
                return .left
            case "right":
                return .right
            case "top":
                return .top
            case "bottom":
                return .bottom
            case "center":
                return .center
            case "fade":
                return .fade
            default:
                return .none
            }
        }
    }
#endif
