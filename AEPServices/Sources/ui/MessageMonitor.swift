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


/*
 This class is used to monitor if an UI message is displayed at some point in time,
 currently this applies for full screen and alert messages.
 The status will be exposed to the core through the UIService.
 @see UIServiceInterface::IsMessageDisplayed()
 */
class MessageMonitor: NSObject {
    
    private var isMessagedisplayed = false
    private let messageQueue = DispatchQueue(label: "MessageMonito.barrierQueue")
    
    /*
     Sets the message_displayed flag on true so other UI messages will not be displayed
     in the same time.
     */
    func displayed() {
        messageQueue.async {
            self.isMessagedisplayed = true
        }
    }
    
    /*
     Sets the message_displayed flag on false enabling other messages to be displayed
     */
    func dismissed() {
        messageQueue.async {
            self.isMessagedisplayed = false
        }
    }
    
    /*
     Returns current status of the message_displayed flag
     */
    func isDisplayed() -> Bool {
        return messageQueue.sync {
            isMessagedisplayed
        }
    }
}


