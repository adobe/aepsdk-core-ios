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

/// Fullscreen message event listener
public protocol FullscreenListenerInterface {
    
    /// Invoked when the fullscreen message is displayed
    /// @param message FullScreenMessageUiInterface message that is being displayed
    func onShow(message: FullScreenMessageUiInterface?)
    
    /// Invoked when the fullscreen message is dismissed
    /// @param message FullScreenMessageUiInterface message that is being dismissed
    func onDismiss(message: FullScreenMessageUiInterface?)
    
    /// Invoked when the fullscreen message is attempting to load a url
    /// @param message FullScreenMessageUiInterface message that is attempting to load the url
    /// @param url     String the url being loaded by the message
    /// @return True if the core wants to handle the URL (and not the fullscreen message view implementation)
    func overrideUrlLoad(message: FullScreenMessageUiInterface?, url : String?) -> Bool
}
