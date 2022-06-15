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
    import WebKit

    /// Fullscreen message lifecycle event listener
    @available(iOSApplicationExtension, unavailable)
    @objc(AEPFullscreenMessageDelegate) public protocol FullscreenMessageDelegate {
        /// Invoked when the fullscreen message is displayed
        /// - Parameters:
        ///     - message: Fullscreen message which is currently shown
        @objc(onShowFullscreenMessage:)
        func onShow(message: FullscreenMessage)

        /// Invoked when the fullscreen message is dismissed
        /// - Parameters:
        ///     - message: Fullscreen message which is dismissed
        @objc(onDismissFullscreenMessage:)
        func onDismiss(message: FullscreenMessage)

        /// Invoked when the fullscreen message is attempting to load a url
        /// - Parameters:
        ///     - message: Fullscreen message
        ///     - url:     String the url being loaded by the message
        /// - Returns: True if the core wants to handle the URL (and not the fullscreen message view implementation)
        @objc(overrideUrlLoadFullscreenMessage:url:)
        func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool

        /// Invoked when the fullscreen message finished loading its first content on the webView.
        /// - Parameter webView - the `WKWebView` instance that completed loading its initial content.
        @objc(webViewDidFinishInitialLoading:)
        optional func webViewDidFinishInitialLoading(webView: WKWebView)

        ///
        /// Invoked when the FullscreenMessage failed to be displayed
        ///
        func onShowFailure()
    }
#endif
