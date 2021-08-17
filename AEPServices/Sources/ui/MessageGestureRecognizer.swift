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
import UIKit

class MessageGestureRecognizer: UISwipeGestureRecognizer {
    var gesture: MessageGesture?
    var dismissAnimation: MessageAnimation?
    var actionUrl: URL?
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
        case .backgroundTap:
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

        // TODO: how to handle background tap
        if swipeDirection == nil {
            // if swipeDirection is nil, do a background tap recognizer
        }
    }

    static func messageGestureRecognizer(fromString name: String, dismissAnimation: MessageAnimation?, url: URL?,
                                         target: Any?, action: Selector?) -> MessageGestureRecognizer {
        switch name {
        case "swipeUp":
            return MessageGestureRecognizer(gesture: .swipeUp, dismissAnimation: dismissAnimation, url: url, target: target, action: action)
        case "swipeDown":
            return MessageGestureRecognizer(gesture: .swipeDown, dismissAnimation: dismissAnimation, url: url, target: target, action: action)
        case "swipeRight":
            return MessageGestureRecognizer(gesture: .swipeRight, dismissAnimation: dismissAnimation, url: url, target: target, action: action)
        case "swipeLeft":
            return MessageGestureRecognizer(gesture: .swipeLeft, dismissAnimation: dismissAnimation, url: url, target: target, action: action)
        case "backgroundTap":
            return MessageGestureRecognizer(gesture: .backgroundTap, dismissAnimation: dismissAnimation, url: url, target: target, action: action)
        default:
            return MessageGestureRecognizer(gesture: .backgroundTap, dismissAnimation: dismissAnimation, url: url, target: target, action: action)
        }
    }
}
