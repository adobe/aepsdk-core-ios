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

    @available(iOSApplicationExtension, unavailable)
    class MessageMonitor: MessageMonitoring {
        private let LOG_PREFIX = "MessageMonitor"
        private var isMsgDisplayed = false
        private let messageQueue = DispatchQueue(label: "com.adobe.uiService.messageMonitor.queue")
        private var displayedMessageId: UUID?

        internal func isMessageDisplayed() -> Bool {
            return messageQueue.sync {
                self.isMsgDisplayed
            }
        }
        
        private func getDisplayedMessageId() -> UUID? {
            return messageQueue.sync {
                self.displayedMessageId
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
                self.displayedMessageId = nil
            }
        }

        internal func show(message: Showable) -> (Bool, PresentationError?) {
            show(message: message, delegateControl: true)
        }

        internal func show(message: Showable, delegateControl: Bool) -> (Bool, PresentationError?) {
            if isMessageDisplayed() {
                Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, another message is displayed at this time.")
                return (false, PresentationError.CONFLICT)
            }

            if delegateControl {
                if ServiceProvider.shared.messagingDelegate?.shouldShowMessage(message: message) == false {
                    Log.debug(label: LOG_PREFIX, "Message couldn't be displayed, MessagingDelegate#showMessage states the message should not be displayed.")
                    return (false, PresentationError.SUPPRESSED_BY_APP_DEVELOPER)
                }
            }

            // Change message monitor to display
            displayMessage()
            
            // if this is a FullscreenMessage, set the ID
            if let fullscreenMessage = message as? FullscreenMessage {
                messageQueue.sync {
                    // set this on message queue
                    displayedMessageId = fullscreenMessage.id
                }
            }

            return (true, nil)
        }

        internal func dismiss() -> Bool {
            return dismiss(nil)
        }
        
        internal func dismiss(_ message: Showable?) -> Bool {
            if !isMessageDisplayed() {
                Log.debug(label: self.LOG_PREFIX, "Message failed to be dismissed, nothing is currently displayed.")
                return false
            }
            
            if let fullscreenMessage = message as? FullscreenMessage {
                if getDisplayedMessageId() != fullscreenMessage.id {
                    Log.debug(label: self.LOG_PREFIX, "Call to dismiss the message failed. Its identifier doesn't match the currently displayed message.")
                    return false
                }
            }
            
            // Change message visibility to dismiss
            dismissMessage()

            return true
        }
    }
#endif
