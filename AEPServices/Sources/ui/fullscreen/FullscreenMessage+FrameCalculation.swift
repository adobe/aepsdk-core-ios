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

extension FullscreenMessage {
    // MARK: - internal vars
    
    /// calculated frames are used for animation
    /// frameWhenVisible is the frame when the message is visible to the user
    var frameWhenVisible: CGRect {
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    /// frameBeforeShow considers displayAnimation and positions the message appropriately
    var frameBeforeShow: CGRect {
        guard let displayAnimation = settings?.displayAnimation else {
            return frameWhenVisible
        }
        
        switch displayAnimation {
        case .top:
            return CGRect(x: originX, y: -(originY + height), width: width, height: height)
        case .bottom:
            return CGRect(x: originX, y: originY + height, width: width, height: height)
        case .right:
            return CGRect(x: originX + width, y: originY, width: width, height: height)
        case .left:
            return CGRect(x: -(originX + width), y: originY, width: width, height: height)
        case .center:
            return CGRect(x: screenWidth * 0.5, y: screenHeight * 0.5, width: 0, height: 0)
        default:
            return frameWhenVisible
        }
    }
    
    /// frameAfterDismiss considers dismissAnimation and positions the message appropriately
    var frameAfterDismiss: CGRect {
        guard let dismissAnimation = settings?.dismissAnimation else {
            return frameWhenVisible
        }
        
        switch dismissAnimation {
        case .top:
            return CGRect(x: originX, y: -(originY + height), width: width, height: height)
        case .bottom:
            return CGRect(x: originX, y: originY + height, width: width, height: height)
        case .right:
            return CGRect(x: originX + width, y: originY, width: width, height: height)
        case .left:
            return CGRect(x: -(originX + width), y: originY, width: width, height: height)
        case .center:
            return CGRect(x: screenWidth * 0.5, y: screenHeight * 0.5, width: 0, height: 0)
        default:
            return frameWhenVisible
        }
    }
    
    // MARK: - private vars
    
    // returns the width of the screen, measured in points
    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    // width in settings represents a percentage of the screen.
    // e.g. - 80 = 80% of the screen width
    // default value is full screen width
    private var width: CGFloat {
        if let settingsWidth = settings?.width {
            return screenWidth * CGFloat(settingsWidth) / 100
        }
        
        return screenWidth
    }
    
    // height in settings represents a percentage of the screen.
    // e.g. - 80 = 80% of the screen height
    // default value is full screen height
    private var height: CGFloat {
        if let settingsHeight = settings?.height {
            return screenHeight * CGFloat(settingsHeight) / 100
        }
        
        return screenHeight
    }
    
    // x origin is calculated by settings values of horizontal alignment and horizontal inset
    // if horizontal alignment is center, horizontal inset is ignored and x is calculated so that the message will be
    // centered according to its width
    // if horizontal alignment is left or right, the inset will be calculated as a percentage width from the respective
    // alignment origin
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
    
    // y origin is calculated by settings values of vertical alignment and vertical inset
    // if vertical alignment is center, vertical inset is ignored and y is calculated so that the message will be
    // centered according to its height
    // if vertical alignment is top or bottom, the inset will be calculated as a percentage height from the respective
    // alignment origin
    private var originY: CGFloat {
        // default to 0 for y origin if unspecified
        guard let settings = settings else {
            return 0
        }
        
        if settings.verticalAlign == .top {
            // check for an inset, otherwise top alignment means return 0
            if let vInset = settings.verticalInset {
                // since y alignment starts at 0 on the top, this value just needs to be
                // the percentage value translated to actual points
                return screenHeight * CGFloat(vInset) / 100
            } else {
                return 0
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
        return (screenHeight - height) / 2
    }
}
