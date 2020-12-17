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

public class FullScreenMessage {
    var fullScreenMessageHandler: FullScreenUIHandler?
    
    /// @private constructor
    /// @see CreateFullscreenMessage method for construction
    private init() {}

    static func createFullscreenMessage(html: String, _ listener: FullscreenListenerInterface, _ messageMonnitor: MessageMonitor, _ isLocalImageUsed: Bool) -> FullScreenMessage? {
        let newMessage: FullScreenMessage = FullScreenMessage()
        return newMessage
    }

    /// Initializes the platform message handler after the full screen message instance was created.
    /// Note: we cannot do this step is done in the constructor, as the instance for FullscreenMessage is not created at that time
    /// @param html - html content that will be loaded on message show
    /// @param listener - listener which will be called on message show/dismiss/openUrl
    /// @param messageMonnitor - MessageMonitor object which determines whether any display is already present
    /// @param isLocalImageUsed If true, an image from the app bundle will be used for the fullscreen message.
    func initMessage(html: String, _ listener: FullscreenListenerInterface, _ messageMonnitor: MessageMonitor, _ isLocalImageUsed: Bool) {
        fullScreenMessageHandler = FullScreenUIHandler(payload: html, message: self, listener: listener, monitor: messageMonnitor, isLocalImageUsed: isLocalImageUsed )
    }
}

//MARK: - Protocol Methods
extension FullScreenMessage : FullScreenMessageUiInterface {

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
