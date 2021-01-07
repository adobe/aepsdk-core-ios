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
public protocol UIServicing {
    /// Displays the message if no other message is currently visible
    /// - Parameters:
    ///     - message: Messaging message which needs to be displayed
    func show(message: UIMessaging)

    /// Dimiss the message if the message is currently visible
    /// - Parameters:
    ///     - message: Messaging message which needs to be dimissed
    func dismiss(message: UIMessaging)

    /// Sets the GlobalUIMessaging listener
    /// - Parameters:
    ///     - listener: GlobalUIMessaging listener which is used to listen for message visibility updates
    func setGlobalUIMessagingListener(listener: GlobalUIMessaging?)

    /// - Returns: True if the message is being displayed else false
    func isMessageDisplayed() -> Bool
}
