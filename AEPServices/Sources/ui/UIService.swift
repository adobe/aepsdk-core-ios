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
    import UIKit

    ///
    /// UIService for creating UI elements
    ///
    @objc (AEPUIServiceProtocol)
    @available(iOSApplicationExtension, unavailable)
    public protocol UIService {

        /// Creates a `FullscreenPresentable`
        /// - Parameters:
        ///     - payload: The payload used in the FullscreenPresentable as a string
        ///     - listener: The `FullscreenPresentable`'s `FullscreenMessageDelegate`
        ///     - isLocalImageUsed: An optional flag indicating if a local image is used instead of the default image provided
        /// - Returns: A `FullscreenPresentable` implementation
        @objc
        func createFullscreenMessage(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool) -> FullscreenPresentable

        /// Creates a `FullscreenPresentable`
        /// - Parameters:
        ///     - payload: The payload used in the FullscreenPresentable as a string
        ///     - listener: The `FullscreenPresentable`'s `FullscreenMessageDelegate`
        ///     - isLocalImageUsed: An optional flag indicating if a local image is used instead of the default image provided
        ///     - settings: The `MessageSettings` that define construction, behavior and ownership of the newly created message
        /// - Returns: A `FullscreenPresentable` implementation
        @objc
        optional func createFullscreenMessage(payload: String,
                                              listener: FullscreenMessageDelegate?,
                                              isLocalImageUsed: Bool,
                                              settings: MessageSettings?) -> FullscreenPresentable

        /// Creates a `FloatingButtonPresentable`
        /// - Parameters:
        ///     - listener: The `FloatingButtonPresentable`'s `FloatingButtonDelegate`
        /// - Returns: A `FloatingButtonPresentable` implementation
        @objc
        func createFloatingButton(listener: FloatingButtonDelegate) -> FloatingButtonPresentable
    }
#endif
