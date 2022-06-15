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

    class MessageGestureRecognizerTests: XCTestCase {
        let testTarget: String = "iamatest"
        let testUrl = URL(string: "https://adobe.com")
        
        @objc func testSelector() {
            return
        }
    
        func testInit() throws {
            let recognizer = MessageGestureRecognizer(gesture: .swipeUp, dismissAnimation: .bottom, url: testUrl,
                                                      target: testTarget, action: #selector(testSelector))
            XCTAssertNotNil(recognizer)
            XCTAssertEqual(recognizer.gesture, .swipeUp)
            XCTAssertEqual(recognizer.dismissAnimation, .bottom)
            XCTAssertEqual(recognizer.actionUrl, testUrl)
            XCTAssertEqual(recognizer.swipeDirection, .up)
        }
    
        func testInitNils() throws {
            let recognizer = MessageGestureRecognizer(gesture: nil, dismissAnimation: nil, url: nil, target: nil, action: nil)
            XCTAssertNotNil(recognizer)
            XCTAssertNil(recognizer.gesture)
            XCTAssertNil(recognizer.dismissAnimation)
            XCTAssertNil(recognizer.actionUrl)
            XCTAssertNil(recognizer.swipeDirection)
        }
    
        func testInitFromStringSwipeUp() throws {
            let recognizer = MessageGestureRecognizer.messageGestureRecognizer(fromString: "swipeUp", dismissAnimation: .top, url: testUrl,
                                                                               target: testTarget, action: #selector(testSelector))
            XCTAssertNotNil(recognizer)
            XCTAssertEqual(recognizer.gesture, .swipeUp)
            XCTAssertEqual(recognizer.dismissAnimation, .top)
            XCTAssertEqual(recognizer.actionUrl, testUrl)
            XCTAssertEqual(recognizer.swipeDirection, .up)
        }
    
        func testInitFromStringSwipeDown() throws {
            let recognizer = MessageGestureRecognizer.messageGestureRecognizer(fromString: "swipeDown", dismissAnimation: .bottom, url: testUrl,
                                                                               target: testTarget, action: #selector(testSelector))
            XCTAssertNotNil(recognizer)
            XCTAssertEqual(recognizer.gesture, .swipeDown)
            XCTAssertEqual(recognizer.dismissAnimation, .bottom)
            XCTAssertEqual(recognizer.actionUrl, testUrl)
            XCTAssertEqual(recognizer.swipeDirection, .down)
        }
    
        func testInitFromStringSwipeRight() throws {
            let recognizer = MessageGestureRecognizer.messageGestureRecognizer(fromString: "swipeRight", dismissAnimation: .right, url: testUrl,
                                                                               target: testTarget, action: #selector(testSelector))
            XCTAssertNotNil(recognizer)
            XCTAssertEqual(recognizer.gesture, .swipeRight)
            XCTAssertEqual(recognizer.dismissAnimation, .right)
            XCTAssertEqual(recognizer.actionUrl, testUrl)
            XCTAssertEqual(recognizer.swipeDirection, .right)
        }
    
        func testInitFromStringSwipeLeft() throws {
            let recognizer = MessageGestureRecognizer.messageGestureRecognizer(fromString: "swipeLeft", dismissAnimation: .left, url: testUrl,
                                                                               target: testTarget, action: #selector(testSelector))
            XCTAssertNotNil(recognizer)
            XCTAssertEqual(recognizer.gesture, .swipeLeft)
            XCTAssertEqual(recognizer.dismissAnimation, .left)
            XCTAssertEqual(recognizer.actionUrl, testUrl)
            XCTAssertEqual(recognizer.swipeDirection, .left)
        }
    
        func testInitFromStringBackgroundTap() throws {
            let recognizer = MessageGestureRecognizer.messageGestureRecognizer(fromString: "backgroundTap", dismissAnimation: .fade, url: testUrl,
                                                                               target: testTarget, action: #selector(testSelector))
            XCTAssertNotNil(recognizer)
            XCTAssertEqual(recognizer.gesture, .backgroundTap)
            XCTAssertEqual(recognizer.dismissAnimation, .fade)
            XCTAssertEqual(recognizer.actionUrl, testUrl)
            XCTAssertNil(recognizer.swipeDirection)
        }
    
        func testInitFromStringNoMatch() throws {
            let recognizer = MessageGestureRecognizer.messageGestureRecognizer(fromString: "oopsee", dismissAnimation: .fade, url: testUrl,
                                                                               target: testTarget, action: #selector(testSelector))
            XCTAssertNotNil(recognizer)
            XCTAssertEqual(recognizer.gesture, .backgroundTap)
            XCTAssertEqual(recognizer.dismissAnimation, .fade)
            XCTAssertEqual(recognizer.actionUrl, testUrl)
            XCTAssertNil(recognizer.swipeDirection)
        }
    }
#endif
