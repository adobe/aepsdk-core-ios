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

/// Global UI Message delegate which used to listen for the message visibility updates
@objc(AEPGlobalUIMessaging) public protocol GlobalUIMessaging {

    /// Invoked when the any message is displayed
    /// - Parameters:
    ///     - message: UIMessaging message that is being displayed
    func onShow(message: UIMessaging?)

    /// Invoked when the any message is dismissed
    /// - Parameters:
    ///     - message: UIMessaging message that is being dismissed
    func onDismiss(message: UIMessaging?)

    /// Used to find whether messages should be shown or not
    /// - Returns: true if message needs to be shown else false
    func showMessage() -> Bool
}
