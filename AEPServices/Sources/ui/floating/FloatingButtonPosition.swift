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

    @available(iOSApplicationExtension, unavailable)
    @objc(AEPFloatingButtonPosition) public enum FloatingButtonPosition: Int {

        case center
        case topRight
        case topLeft

        internal func frame(screenBounds: CGSize) -> CGRect {
            switch self {
            case .center:
                return CGRect(x: (Int(screenBounds.width) - FloatingButton.PREVIEW_BUTTON_WIDTH) / 2,
                              y: (Int(screenBounds.height) - FloatingButton.PREVIEW_BUTTON_HEIGHT) / 2,
                              width: FloatingButton.PREVIEW_BUTTON_WIDTH,
                              height: FloatingButton.PREVIEW_BUTTON_HEIGHT)

            case .topRight:
                return CGRect(x: (Int(screenBounds.width) - FloatingButton.PREVIEW_BUTTON_WIDTH),
                              y: FloatingButton.BUTTON_TOP_MARGIN,
                              width: FloatingButton.PREVIEW_BUTTON_WIDTH,
                              height: FloatingButton.PREVIEW_BUTTON_HEIGHT)

            case .topLeft:
                return CGRect(x: 0,
                              y: FloatingButton.BUTTON_TOP_MARGIN,
                              width: FloatingButton.PREVIEW_BUTTON_WIDTH,
                              height: FloatingButton.PREVIEW_BUTTON_HEIGHT)
            }

        }
    }
#endif
