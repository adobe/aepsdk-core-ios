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

/// This class is used to monitor if an UI message is displayed at some point in time,
/// currently this applies for full screen and alert messages.
/// The status will be exposed through the UIService.
/// @see UIService.isMessageDisplayed()
public class UIService: UIServicing {
    private let LOG_PREFIX = "UIService"
    private var isMessageDisplayed = false
    private let messageQueue = DispatchQueue(label: "com.adobe.uiservice.messagemonitor")

    /// Sets the isMessageDisplayed flag on true so other UI messages will not be displayed
    /// in the same time.
    func displayed() {
        messageQueue.async {
            self.isMessageDisplayed = true
        }
    }

    /// Sets the isMessageDisplayed flag on false enabling other messages to be displayed
    func dismissed() {
        messageQueue.async {
            self.isMessageDisplayed = false
        }
    }

    /// Returns current status of the isMessageDisplayed flag
    func isDisplayed() -> Bool {
        return messageQueue.sync {
            isMessageDisplayed
        }
    }

    public func show(message: Messaging) {
        if isDisplayed() {
            Log.debug(label: LOG_PREFIX, "message couldn't be displayed, another message is displayed at this time")
            return
        }
        // Change message monitor to display
        displayed()

        message.show()
    }

    public func dismiss(message: Messaging) {
        if isDisplayed() {
            message.remove()
        }
    }
}
