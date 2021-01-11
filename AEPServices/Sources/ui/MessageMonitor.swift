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
public class MessageMonitor {
    private let LOG_PREFIX = "MessageMonitor"
    private var isMsgDisplayed = false
    var globalUIMessagingListener: GlobalUIMessaging?
    private let messageQueue = DispatchQueue(label: "com.adobe.uiservice.messagemonitor")

    // Current message which is being displayed
    var currentMessage: UIMessaging?

    /// Sets the isMessageDisplayed flag on true so other UI messages will not be displayed
    /// in the same time.
    public func displayMessage() {
        messageQueue.async {
            self.isMsgDisplayed = true
        }
    }

    /// Sets the isMessageDisplayed flag on false enabling other messages to be displayed
    public func dismissMessage() {
        messageQueue.async {
            self.isMsgDisplayed = false
        }
    }
    
    func showMessage() {
        // Determine whether the message should be shown or not based on global ui messaging listener
        if globalUIMessagingListener?.showMessage() == false {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, globalUIMessaging#showMessage states the message should not be displayed.")
            return
        }
    }

    public func show(message: UIMessaging) {
        if isMessageDisplayed() {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, another message is displayed at this time.")
            return
        }

        // Determine whether the message should be shown or not based on global ui messaging listener
        if globalUIMessagingListener?.showMessage() == false {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, globalUIMessaging#showMessage states the message should not be displayed.")
            return
        }

        // Change message monitor to display
        displayMessage()

        // Assiging the currentMessage
        self.currentMessage = message

        // Notifiying global listeners
        globalUIMessagingListener?.onShow(message: message)

        // Show message
        message.show()
    }

    public func dismiss() {
        if isMessageDisplayed() {
            // Change message visibility to dismiss
            dismissMessage()

            // Notifiying global listeners
            globalUIMessagingListener?.onDismiss(message: currentMessage)

            // Assiging the currentMessage
            self.currentMessage = nil
        } else {
            Log.debug(label: LOG_PREFIX, "Message failed to be dismissed, nothing is currently displayed.")
        }
    }

    public func setGlobalUIMessagingListener(listener: GlobalUIMessaging?) {
        self.globalUIMessagingListener = listener
    }

    public func isMessageDisplayed() -> Bool {
        return messageQueue.sync {
            self.isMsgDisplayed
        }
    }
}
