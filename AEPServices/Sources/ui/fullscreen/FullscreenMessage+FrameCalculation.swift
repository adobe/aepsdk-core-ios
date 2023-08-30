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
    extension FullscreenMessage {
        /// NOTE - all methods in this extension must be called from the main thread

        // MARK: - internal vars

        /// NOTE - `frameWhenVisible`, `frameBeforeShow` and `frameAfterDismiss` are calculated frames are used for animation

        /// frameWhenVisible is the frame when the message is visible to the user
        /// this method should only be called from the main thread
        var frameWhenVisible: CGRect {
            return CGRect(x: originX, y: originY, width: width, height: height)
        }

        /// frameBeforeShow considers displayAnimation and positions the message appropriately
        /// this method should only be called from the main thread
        var frameBeforeShow: CGRect {
            guard let displayAnimation = settings?.displayAnimation else {
                return frameWhenVisible
            }

            switch displayAnimation {
            case .top:
                return CGRect(x: originX, y: -(height + originY), width: width, height: height)
            case .bottom:
                return CGRect(x: originX, y: screenHeight, width: width, height: height)
            case .right:
                return CGRect(x: screenWidth, y: originY, width: width, height: height)
            case .left:
                return CGRect(x: -(screenWidth + originX), y: originY, width: width, height: height)
            case .center:
                return CGRect(x: screenWidth * 0.5, y: screenHeight * 0.5, width: 0, height: 0)
            default:
                return frameWhenVisible
            }
        }

        /// frameAfterDismiss considers dismissAnimation and positions the message appropriately
        /// this method should only be called from the main thread
        var frameAfterDismiss: CGRect {
            guard let dismissAnimation = settings?.dismissAnimation else {
                return frameWhenVisible
            }

            switch dismissAnimation {
            case .top:
                return CGRect(x: originX, y: -(height + originY), width: width, height: height)
            case .bottom:
                return CGRect(x: originX, y: screenHeight, width: width, height: height)
            case .right:
                return CGRect(x: screenWidth, y: originY, width: width, height: height)
            case .left:
                return CGRect(x: -(screenWidth + originX), y: originY, width: width, height: height)
            case .center:
                return CGRect(x: screenWidth * 0.5, y: screenHeight * 0.5, width: 0, height: 0)
            default:
                return frameWhenVisible
            }
        }

        /// returns the width of the screen, measured in points
        /// this method should only be called from the main thread
        var screenWidth: CGFloat {
            if #available(iOS 13.0, *) {
                if let keyWindow = UIApplication.shared.getKeyWindow() {
                    return keyWindow.frame.width
                }
            }

            return UIScreen.main.bounds.width
        }

        /// returns the height of the screen, measured in points
        /// this method should only be called from the main thread
        var screenHeight: CGFloat {
            let isVAlignBottom = settings?.verticalAlign == .bottom
            if #available(iOS 13.0, *) {
                if let keyWindow = UIApplication.shared.getKeyWindow() {
                    return isVAlignBottom ? keyWindow.frame.height : keyWindow.frame.height - safeAreaHeight
                }
            }

            return isVAlignBottom ? UIScreen.main.bounds.height : UIScreen.main.bounds.height - safeAreaHeight
        }

        /// calculates the safe area at the top of the screen, measured by status bar and/or notch
        /// this method should only be called from the main thread
        var safeAreaHeight: CGFloat {
            if #available(iOS 16.0, *) {
                if let fullscreen = UIApplication.shared.getKeyWindow()?.windowScene?.isFullScreen, fullscreen {
                    return 0
                }
            }
            if #available(iOS 13.0, *) {
                return UIApplication.shared.getKeyWindow()?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            } else {
                return UIApplication.shared.statusBarFrame.height
            }
        }

        // MARK: - private vars

        /// width in settings represents a percentage of the screen.
        /// e.g. - 80 = 80% of the screen width.
        /// default value is full screen width.
        /// this method should only be called from the main thread
        private var width: CGFloat {
            if let settingsWidth = settings?.width {
                return screenWidth * CGFloat(settingsWidth) / 100
            }

            return screenWidth
        }

        /// height in settings represents a percentage of the screen.
        /// e.g. - 80 = 80% of the screen height.
        /// default value is full screen height.
        /// this method should only be called from the main thread
        private var height: CGFloat {
            if let settingsHeight = settings?.height {
                return screenHeight * CGFloat(settingsHeight) / 100
            }

            return screenHeight
        }

        /// x origin is calculated by settings values of horizontal alignment and horizontal inset.
        /// if horizontal alignment is center, horizontal inset is ignored and x is calculated so that the message will be
        /// centered according to its width.
        /// if horizontal alignment is left or right, the inset will be calculated as a percentage width from the respective
        /// alignment origin.
        /// this method should only be called from the main thread
        private var originX: CGFloat {
            // default to 0 for x origin if unspecified
            guard let settings = settings else {
                return 0
            }

            if settings.horizontalAlign == .left {
                // check for an inset, otherwise left alignment means return 0
                if let hInset = settings.horizontalInset {
                    // since x alignment starts at 0 on the left, this value just needs to be
                    // the percentage value translated to actual points
                    return screenWidth * CGFloat(hInset) / 100
                } else {
                    return 0
                }
            } else if settings.horizontalAlign == .right {
                // check for an inset
                if let hInset = settings.horizontalInset {
                    // x alignment here is screen width - message width - inset value converted from percentage to points
                    return screenWidth - width - (screenWidth * CGFloat(hInset) / 100)
                } else {
                    // no inset, right x alignment means screen width - message width
                    return screenWidth - width
                }
            }

            // handle center alignment, x is (screen width - message width) / 2
            return (screenWidth - width) / 2
        }

        /// y origin is calculated by settings values of vertical alignment and vertical inset.
        /// if vertical alignment is center, vertical inset is ignored and y is calculated so that the message will be
        /// centered according to its height.
        /// if vertical alignment is top or bottom, the inset will be calculated as a percentage height from the respective
        /// alignment origin.
        /// this method should only be called from the main thread
        private var originY: CGFloat {
            // default to 0 (considering safe area) for y origin if unspecified
            guard let settings = settings else {
                return safeAreaHeight
            }

            if settings.verticalAlign == .top {
                // check for an inset, otherwise top alignment means return 0
                if let vInset = settings.verticalInset {
                    // since y alignment starts at 0 on the top, this value just needs to be
                    // the percentage value translated to actual points
                    return screenHeight * CGFloat(vInset) / 100 + safeAreaHeight
                } else {
                    return safeAreaHeight
                }
            } else if settings.verticalAlign == .bottom {
                // check for an inset
                if let vInset = settings.verticalInset {
                    // y alignment here is screen height - message height - inset value converted from percentage to points
                    return screenHeight - height - (screenHeight * CGFloat(vInset) / 100)
                } else {
                    // no inset, bottom y alignment means screen height - message height
                    return screenHeight - height
                }
            }

            // handle center alignment, y is (screen height - message height) / 2
            return (screenHeight - height) / 2 + safeAreaHeight
        }
    }
#endif
