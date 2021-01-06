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

/// This class is used to monitor if an UI message is displayed at some point in time, currently this applies for full screen and alert messages.
/// The status is exposed through isMessageDisplayed.
class UIService: UIServicing {
    private let LOG_PREFIX = "UIService"
    private(set) var isMessageDisplayed: Bool {
        get {
            return messageQueue.sync {
                self.isMessageDisplayed
            }
        }
        set(value) {
            self.isMessageDisplayed = value
        }
    }
    private let messageQueue = DispatchQueue(label: "com.adobe.uiservice.messagemonitor")

    init() {
        isMessageDisplayed = false
    }

    /// Sets the isMessageDisplayed flag on true so other UI messages will not be displayed
    /// in the same time.
    func display() {
        messageQueue.async {
            self.isMessageDisplayed = true
        }
    }

    /// Sets the isMessageDisplayed flag on false enabling other messages to be displayed
    func dismiss() {
        messageQueue.async {
            self.isMessageDisplayed = false
        }
    }

    /// Displays the message if no other message is currently visible
    /// - Parameters:
    ///     - message: Messaging message which needs to be displayed
    public func show(message: UIMessaging) {
        if isMessageDisplayed {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, another message is displayed at this time.")
            return
        }
        // Change message monitor to display
        display()

        message.show()
    }

    /// Dimiss the message if the message is currently visible
    /// - Parameters:
    ///     - message: Messaging message which needs to be dimissed
    public func dismiss(message: UIMessaging) {
        if isMessageDisplayed {
            dismiss()
            message.remove()
        } else {
            Log.debug(label: LOG_PREFIX, "Message failed to be dismissed, nothing is currently displayed.")
        }
    }
}
