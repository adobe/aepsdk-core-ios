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

    /// This protocol is used to monitor if an UI message is displayed at some point in time, currently this applies for full screen and alert messages.
    /// The status is exposed through isMessageDisplayed.
    protocol MessageMonitoring {
        /// - Returns: `true` if a message is being displayed
        func isMessageDisplayed() -> Bool

        /// Sets the isMessageDisplayed flag to true so other UI messages will not be displayed at the same time.
        func displayMessage()

        /// Sets the isMessageDisplayed flag to false
        func dismissMessage()

        /// Determines whether the provided `message` should be shown.
        /// If a UI message is already showing, this method will return `false`.
        /// If `MobileCore.messagingDelegate` exists, this method will call its `shouldShowMessage(:)` method.
        /// - Parameter message: `Showable` message to be shown
        /// - Returns: `true` if message needs to be shown
        func show(message: Showable) -> Bool

        /// Determines whether the provided `message` should be shown.
        /// If a UI message is already showing, this method will return `false`.
        /// If `delegateControl` is `true` and `MobileCore.messagingDelegate` exists,
        ///   this method will call the delegate's `shouldShowMessage(:)` method.
        /// - Parameters:
        ///   - message: `Showable` message to be shown
        ///   - delegateControl: If set to `true`, the `MessagingDelegate` will control whether the message should be shown.
        /// - Returns: `true` if message needs to be shown
        func show(message: Showable, delegateControl: Bool) -> Bool

        /// Check if the message is being displayed and call invoke the appropriate listeners
        /// - Returns: `true` if message needs to be dismissed
        func dismiss() -> Bool
    }
#endif
