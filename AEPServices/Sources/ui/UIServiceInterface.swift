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

/// Interface for displaying alerts, local notifications, and fullscreen web views
public protocol UIServiceInterface {
    
    /// Creates a fullscreen message.
    /// WARNING: This API consumes HTML/CSS/JS using an embedded browser control.
    /// This means it is subject to all the risks of rendering untrusted web pages and running untrusted JS.
    /// Treat all calls to this API with caution and make sure input is vetted for safety somewhere.
    ///
    /// @param html               String html content to be displayed with the message
    /// @param fullscreenListener FullscreenListener listener for fullscreen message events
    /// @return FullScreenMessageUiInterface object if the html is valid, null otherwise
    func createFullscreenMessage(html: String, fullscreenListener: FullscreenListenerInterface) -> FullScreenMessageUiInterface?
    
    /// Creates a fullscreen message.
    /// WARNING: This API consumes HTML/CSS/JS using an embedded browser control.
    /// This means it is subject to all the risks of rendering untrusted web pages and running untrusted JS.
    /// Treat all calls to this API with caution and make sure input is vetted for safety somewhere.
    ///
    /// @param html               String html content to be displayed with the message
    /// @param fullscreenListener FullscreenListener listener for fullscreen message events
    /// @param isLocalImageUsed   If true, an image from the app bundle will be used for the fullscreen message.
    /// @return FullScreenMessageUiInterface object if the html is valid, null otherwise
    func createFullscreenMessage(html: String, fullscreenListener: FullscreenListenerInterface, isLocalImageUsed: Bool) -> FullScreenMessageUiInterface?
    
    /// Returns true if there is another message displayed at this time, false otherwise.
    /// The status is collected from the platform messages monitor and it applies if either
    /// an alert message or a full screen message is displayed at some point.
    func isMessageDisplayed() -> Bool
}
