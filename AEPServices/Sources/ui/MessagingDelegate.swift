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

    /// UI Message delegate which is used to listen for current message lifecycle events
    @objc(AEPMessagingDelegate)
    public protocol MessagingDelegate {

        /// Invoked when a message is displayed
        /// - Parameters:
        ///     - message: UIMessaging message that is being displayed
        @objc(onShow:)
        func onShow(message: Showable)

        /// Invoked when a message is dismissed
        /// - Parameters:
        ///     - message: UIMessaging message that is being dismissed
        @objc(onDismiss:)
        func onDismiss(message: Showable)

        /// Used to find whether messages should be shown or not
        /// - Parameters:
        ///     - message: UIMessaging message that is about to get displayed
        /// - Returns: true if the message should be shown else false
        @objc(shouldShowMessage:)
        func shouldShowMessage(message: Showable) -> Bool

        /// Called when `message` loads a URL
        /// - Parameters:
        ///     - url: the `URL` being loaded by the `message`
        ///     - message: the Message loading a `URL`
        @objc(urlLoaded:byMessage:)
        optional func urlLoaded(_ url: URL, byMessage message: Showable)
    }
#endif
