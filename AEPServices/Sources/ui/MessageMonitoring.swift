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
        /// - Returns: True if the message is being displayed else false
        func isMessageDisplayed() -> Bool

        /// Sets the isMessageDisplayed flag on true so other UI messages will not be displayed
        /// in the same time.
        func displayMessage()

        /// Sets the isMessageDisplayed flag on true so other UI messages will not be displayed
        /// in the same time.
        func dismissMessage()

        /// Check if any message is being displayed already or if the message should be shown based on `MessagingDelegate`
        /// - Parameters:UIMessaging message which needs to be shown
        /// - Returns: True if message needs to be shown false otherwise
        func show(message: Showable) -> Bool

        // Check if the message is being displayed and call invoke the appropriate listeners
        /// - Returns: True if message needs to be dismissed false otherwise
        func dismiss() -> Bool
    }
#endif
