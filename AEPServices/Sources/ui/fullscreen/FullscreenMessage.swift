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

public class FullScreenMessage: FullScreenMessageUiInterface {
    var fullScreenMessageHandler: FullScreenUIHandler?

    static func createFullscreenMessage(html: String, _ listener: FullscreenListenerInterface, _ messageMonnitor: MessageMonitor, _ isLocalImageUsed: Bool) -> FullScreenMessage? {
        let newMessage: FullScreenMessage = FullScreenMessage()
        return newMessage
    }

    func initMessage(html: String, _ listener: FullscreenListenerInterface, _ messageMonnitor: MessageMonitor, _ isLocalImageUsed: Bool) {
        fullScreenMessageHandler = FullScreenUIHandler(payload: html, message: self, listener: listener, monitor: messageMonnitor, isLocalImageUsed: isLocalImageUsed )
    }

    public func show() {
        fullScreenMessageHandler?.show()
    }

    public func openUrl(url: String) {
        fullScreenMessageHandler?.openUrl(url: url)
    }

    public func remove() {
        fullScreenMessageHandler?.dismiss()
    }
}
