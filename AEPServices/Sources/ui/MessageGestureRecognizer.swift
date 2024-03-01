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
    import UIKit

    /// Handles message gesture support
    class MessageGestureRecognizer: UISwipeGestureRecognizer {
        /// The `MessageGesture` associated with this recognizer.
        var gesture: MessageGesture?

        /// The `MessageAnimation` to be used when the message is dismissed.
        var dismissAnimation: MessageAnimation?

        /// The `URL` to be loaded by the message's webview when the provided `gesture` is executed.
        var actionUrl: URL?

        /// A `UISwipeGestureRecognizer.Direction` necessary for capturing the correct gesture.
        var swipeDirection: UISwipeGestureRecognizer.Direction? {
            switch gesture {
            case .swipeUp:
                return .up
            case .swipeDown:
                return .down
            case .swipeLeft:
                return .left
            case .swipeRight:
                return .right
            case .tapBackground:
                return nil
            default:
                return nil
            }
        }

        init(gesture: MessageGesture?, dismissAnimation: MessageAnimation?,
             url: URL?, target: Any?, action: Selector?) {
            super.init(target: target, action: action)

            self.gesture = gesture
            self.dismissAnimation = dismissAnimation
            self.actionUrl = url
        }

        /// Convenience method for initializing a `MessageGestureRecognizer` from a provided `String`.
        ///
        /// If the provided `name` is not recognized in the list, this method will return a recognizer
        /// that supports `MessageGesture.tapBackground`.
        ///
        /// - Parameters:
        ///   - name: `String` representing the type of recognizer that should be created.
        ///   - animation: A `MessageAnimation` that should be used when the message is dismissed.
        ///   - url: The `URL` to be loaded by the message's webview when the provided `gesture` is executed.
        ///   - target: The object to be notified when the `gesture` is executed.
        ///   - action: A `Selector` defined in the `target` that will be called when the `gesture` is executed.
        /// - Returns: A `MessageGestureRecognizer` with settings provided in the parameters.
        static func messageGestureRecognizer(fromString name: String, dismissAnimation animation: MessageAnimation?, url: URL?,
                                             target: Any?, action: Selector?) -> MessageGestureRecognizer {
            switch name {
            case "swipeUp":
                return MessageGestureRecognizer(gesture: .swipeUp, dismissAnimation: animation, url: url, target: target, action: action)
            case "swipeDown":
                return MessageGestureRecognizer(gesture: .swipeDown, dismissAnimation: animation, url: url, target: target, action: action)
            case "swipeRight":
                return MessageGestureRecognizer(gesture: .swipeRight, dismissAnimation: animation, url: url, target: target, action: action)
            case "swipeLeft":
                return MessageGestureRecognizer(gesture: .swipeLeft, dismissAnimation: animation, url: url, target: target, action: action)
            case "tapBackground":
                return MessageGestureRecognizer(gesture: .tapBackground, dismissAnimation: animation, url: url, target: target, action: action)
            default:
                return MessageGestureRecognizer(gesture: .tapBackground, dismissAnimation: animation, url: url, target: target, action: action)
            }
        }
    }
#endif
