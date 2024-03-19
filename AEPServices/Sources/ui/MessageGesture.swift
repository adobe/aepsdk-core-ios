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

    /// A MessageGesture represents a user interaction with a UIView.
    @objc (AEPMessageGesture)
    public enum MessageGesture: Int {
        case swipeUp = 0
        case swipeDown = 1
        case swipeLeft = 2
        case swipeRight = 3
        case tapBackground = 4

        /// Converts a `String` to its respective `MessageGesture`
        /// If `string` is not a valid `MessageGesture`, calling this method will return `nil`
        /// - Parameter string: a `String` representation of a `MessageGesture`
        /// - Returns: a `MessageGesture` representing the passed-in `String`
        public static func fromString(_ string: String) -> MessageGesture? {
            switch string {
            case "swipeUp":
                return .swipeUp
            case "swipeDown":
                return .swipeDown
            case "swipeRight":
                return .swipeRight
            case "swipeLeft":
                return .swipeLeft
            case "tapBackground":
                return .tapBackground
            default:
                return nil
            }
        }
    }
#endif
