/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Fullscreen message lifecycle event listener for native implementation
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
@objc(AEPFullscreenMessageNativeDelegate)
@available(tvOS 13.0, *)
public protocol FullscreenMessageNativeDelegate {
    /// Invoked when the fullscreen message is displayed
    /// - Parameters:
    ///     - message: Fullscreen message which is currently shown
    @objc(onShowFullscreenMessageNative:)
    func onShow(message: FullscreenMessageNative)

    /// Invoked when the fullscreen message is dismissed
    /// - Parameters:
    ///     - message: Fullscreen message which is dismissed
    @objc(onDismissFullscreenMessageNative:)
    func onDismiss(message: FullscreenMessageNative)

    /// Invoked when the FullscreenMessage failed to be displayed
    /// - Parameters:
    ///  - message - the message that was not displayed
    ///  - error - a `PresentationError` containing the reason why the message was not shown
    @objc(onErrorFullscreenMessageNative:error:)
    optional func onError(message: FullscreenMessageNative, error: PresentationError)
}
