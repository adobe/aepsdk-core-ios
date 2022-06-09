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
    @testable import AEPServices
    import XCTest

    class MessageGestureTests: XCTestCase {
        func testValueSwipeUp() throws {
            XCTAssertEqual(0, MessageGesture.swipeUp.rawValue)
        }
    
        func testFromStringSwipeUp() throws {
            let gesture = MessageGesture.fromString("swipeUp")
            XCTAssertEqual(gesture, .swipeUp)
        }
    
        func testValueSwipeDown() throws {
            XCTAssertEqual(1, MessageGesture.swipeDown.rawValue)
        }
    
        func testFromStringSwipeDown() throws {
            let gesture = MessageGesture.fromString("swipeDown")
            XCTAssertEqual(gesture, .swipeDown)
        }
    
        func testValueSwipeLeft() throws {
            XCTAssertEqual(2, MessageGesture.swipeLeft.rawValue)
        }
    
        func testFromStringSwipeLeft() throws {
            let gesture = MessageGesture.fromString("swipeLeft")
            XCTAssertEqual(gesture, .swipeLeft)
        }
    
        func testValueSwipeRight() throws {
            XCTAssertEqual(3, MessageGesture.swipeRight.rawValue)
        }
    
        func testFromStringSwipeRight() throws {
            let gesture = MessageGesture.fromString("swipeRight")
            XCTAssertEqual(gesture, .swipeRight)
        }
    
        func testValueBackgroundTap() throws {
            XCTAssertEqual(4, MessageGesture.backgroundTap.rawValue)
        }
    
        func testFromStringBackgroundTap() throws {
            let gesture = MessageGesture.fromString("backgroundTap")
            XCTAssertEqual(gesture, .backgroundTap)
        }
    
        func testFromStringNoMatch() throws {
            let gesture = MessageGesture.fromString("oopsee")
            XCTAssertNil(gesture)
        }
    }
#endif
