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

    ///
    /// Represents a FloatingButton UI element which is both `Showable` and `Dismissible`
    ///
    @objc(AEPFloatingButtonPresentable)
    @available(iOSApplicationExtension, unavailable)
    public protocol FloatingButtonPresentable: Showable, Dismissible {

        /// Set the Image for the floating button.
        /// The size of the floating button is 60x60 (width x height), provide the image data accordingly
        /// - Parameters:
        ///     - imageData : The `Data` representation of a UIImage
        func setButtonImage(imageData: Data)

        /// Set the initial position of floating button.
        /// By default the initial position is set to `FloatingButtonPosition.center`.
        /// Call this method before calling `floatingButton.show()` to set the position of the floating button when it appears.
        /// - Parameters:
        ///     - position : The `FloatingButtonPosition` defining the initial position of the floating button.
        func setInitial(position: FloatingButtonPosition)
    }
#endif
