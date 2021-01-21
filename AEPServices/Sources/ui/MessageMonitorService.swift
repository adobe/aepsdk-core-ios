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

class MessageMonitorService: MessageMonitorServicing {
    private let LOG_PREFIX = "MessageMonitor"
    private var isMsgDisplayed = false
    private let messageQueue = DispatchQueue(label: "com.adobe.uiservice.messagemonitor")

    internal func isMessageDisplayed() -> Bool {
        return messageQueue.sync {
            self.isMsgDisplayed
        }
    }

    internal func displayMessage() {
        messageQueue.async {
            self.isMsgDisplayed = true
        }
    }

    internal func dismissMessage() {
        messageQueue.async {
            self.isMsgDisplayed = false
        }
    }

    internal func show(message: UIMessaging) -> Bool {
        if isMessageDisplayed() {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, another message is displayed at this time.")
            return false
        }

        if ServiceProvider.shared.messagingDelegate?.shouldShowMessage(message: message) == false {
            Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, MessagingDelegate#showMessage states the message should not be displayed.")
            return false
        }

        // Change message monitor to display
        displayMessage()

        return true
    }

    internal func dismiss() -> Bool {
        if !isMessageDisplayed() {
            Log.debug(label: self.LOG_PREFIX, "Message failed to be dismissed, nothing is currently displayed.")
            return false
        }

        // Change message visibility to dismiss
        dismissMessage()

        return true
    }
}
