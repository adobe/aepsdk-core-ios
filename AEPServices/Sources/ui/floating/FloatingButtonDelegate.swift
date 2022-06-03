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

    /// Floating button lifecycle event listener
    @objc(AEPFloatingButtonDelegate) public protocol FloatingButtonDelegate {
        /// Invoked when the floating button is tapped
        func onTapDetected()

        /// Invoked when the floating button is dragged on the screen
        func onPanDetected()

        /// Invoked when the floating button is displayed
        @objc(onShowWithFloatingButton)
        func onShow()

        /// Invoked when the floating button is removed
        @objc(onDismissWithFloatingButton)
        func onDismiss()
    }
#endif
