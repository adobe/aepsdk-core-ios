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
import UIKit

public class UIService: NSObject, UIServiceInterface {
    var messageMonitor: MessageMonitor
    override init() {
        self.messageMonitor = MessageMonitor()
    }
    
    public func createFullscreenMessage(html: String, fullscreenListener: FullscreenListenerInterface) -> FullScreenMessageUiInterface? {
        let fullscreenMessage = FullScreenMessage.createFullscreenMessage(html: html, fullscreenListener, messageMonitor, false)
        fullscreenMessage?.initMessage(html: html, fullscreenListener, messageMonitor, false)
        return fullscreenMessage
    }
    
    public func createFullscreenMessage(html: String, fullscreenListener: FullscreenListenerInterface, isLocalImageUsed: Bool) -> FullScreenMessageUiInterface? {
        let fullscreenMessage = FullScreenMessage.createFullscreenMessage(html: html, fullscreenListener, messageMonitor, isLocalImageUsed)
        fullscreenMessage?.initMessage(html: html, fullscreenListener, messageMonitor, isLocalImageUsed)
        return fullscreenMessage
    }
    
    public func isMessageDisplayed() -> Bool {
        return self.messageMonitor.isDisplayed()
    }
}
