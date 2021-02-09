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

import Foundation
import UIKit

///
/// UIService for creating UI elements
///
public protocol UIService {

    ///
    /// Creates a `FullscreenPresentable`
    /// - Parameters:
    ///     - payload: The payload used in the FullscreenPresentable as a string
    ///     - listener: The `FullscreenPresentable`'s `FullscreenMessageDelegate`
    ///     - isLocalImageUsed: An optional flag indicating if a local image is used instead of the default image provided
    /// - Returns: A `FullscreenPresentable` implementation
    func createFullscreenMessage(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool) -> FullscreenPresentable

    ///
    /// Creates a `FloatinButtonPresentable`
    /// - Parameters:
    ///     - listener: The `FloatingButtonPresentable`'s `FloatingButtonDelegate`
    /// - Returns: A `FloatingButtonPresentable` implementation
    func createFloatingButton(listener: FloatingButtonDelegate) -> FloatingButtonPresentable

    ///
    /// Creates an `AlertMessageShowable`
    /// - Parameters:
    ///     - title: The title of the alert message as a `String`
    ///     - message: The message of the alert message as a `String`
    ///     - positiveButtonLabel: The positive button label text as a `String?`
    ///     - negativeButtonLabel: The negative button label text as a `String?`
    /// - Returns: An `AlertMessageShowable` implementation
    func createAlertMessage(title: String, message: String, positiveButtonLabel: String?, negativeButtonLabel: String?, listener: AlertMessageDelegate?) -> AlertMessageShowable
}
