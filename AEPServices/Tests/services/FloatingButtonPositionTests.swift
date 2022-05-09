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
@testable import AEPServices
import XCTest

@available(iOSApplicationExtension, unavailable)
class FloatingButtonPositionTests : XCTestCase {
    
    // A sample screen bounds to which the button has to be centered
    var screenBounds = CGSize(width: 100, height: 100)
    
    // Few other constants to know for the test
    // FloatingButtonWidth = 60
    // FloatingButtonHeight = 60
    // TopMargin = 40
    
    func test_PositionCenter_Frame() {
        // test
        let centerFrame = FloatingButtonPosition.center.frame(screenBounds: screenBounds)
        
        // verify the the button positions to the center of the screen
        XCTAssertEqual(20, centerFrame.origin.x)
        XCTAssertEqual(20, centerFrame.origin.y)
        XCTAssertEqual(60, centerFrame.size.width)
        XCTAssertEqual(60, centerFrame.size.height)
    }
    
    func test_PositionTopRight_Frame() {
        // test
        let topRightFrame = FloatingButtonPosition.topRight.frame(screenBounds: screenBounds)
        
        // verify the the button positions to the topRight of the screen
        XCTAssertEqual(40, topRightFrame.origin.x)
        XCTAssertEqual(40, topRightFrame.origin.y)
        XCTAssertEqual(60, topRightFrame.size.width)
        XCTAssertEqual(60, topRightFrame.size.height)
    }
        
    func test_PositionTopLeft_Frame() {
        // test
        let topLeftFrame = FloatingButtonPosition.topLeft.frame(screenBounds: screenBounds)
        
        // verify the the button positions to the topLeft of the screen
        XCTAssertEqual(0, topLeftFrame.origin.x)
        XCTAssertEqual(40, topLeftFrame.origin.y)
        XCTAssertEqual(60, topLeftFrame.size.width)
        XCTAssertEqual(60, topLeftFrame.size.height)
    }

}
