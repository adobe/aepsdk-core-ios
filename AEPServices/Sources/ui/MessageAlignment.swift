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

    /// A MessageAlignment represents the anchor point on a view for a non-fullscreen message.
    @objc (AEPMessageAlignment)
    public enum MessageAlignment: Int {
        case center = 0
        case left = 1
        case right = 2
        case top = 3
        case bottom = 4

        /// Converts a `String` to its respective `MessageAlignment`
        /// If `string` is not a valid `MessageAlignment`, calling this method will return `.center`
        /// - Parameter string: a `String` representation of a `MessageAlignment`
        /// - Returns: a `MessageAlignment` representing the passed-in `String`
        public static func fromString(_ string: String) -> MessageAlignment {
            switch string {
            case "center":
                return .center
            case "left":
                return .left
            case "right":
                return .right
            case "top":
                return .top
            case "bottom":
                return .bottom
            default:
                return .center
            }
        }
    }
#endif
