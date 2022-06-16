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

    class MessageAnimationTests: XCTestCase {        
        func testValueNone() throws {
            XCTAssertEqual(0, MessageAnimation.none.rawValue)
        }
    
        func testFromStringNone() throws {
            let animation = MessageAnimation.fromString("none")
            XCTAssertEqual(animation, .none)
        }
    
        func testValueLeft() throws {
            XCTAssertEqual(1, MessageAnimation.left.rawValue)
        }
    
        func testFromStringLeft() throws {
            let animation = MessageAnimation.fromString("left")
            XCTAssertEqual(animation, .left)
        }
    
        func testValueRight() throws {
            XCTAssertEqual(2, MessageAnimation.right.rawValue)
        }
    
        func testFromStringRight() throws {
            let animation = MessageAnimation.fromString("right")
            XCTAssertEqual(animation, .right)
        }
    
        func testValueTop() throws {
            XCTAssertEqual(3, MessageAnimation.top.rawValue)
        }
    
        func testFromStringTop() throws {
            let animation = MessageAnimation.fromString("top")
            XCTAssertEqual(animation, .top)
        }
    
        func testValueBottom() throws {
            XCTAssertEqual(4, MessageAnimation.bottom.rawValue)
        }
    
        func testFromStringBottom() throws {
            let animation = MessageAnimation.fromString("bottom")
            XCTAssertEqual(animation, .bottom)
        }
    
        func testValueCenter() throws {
            XCTAssertEqual(5, MessageAnimation.center.rawValue)
        }
    
        func testFromStringCenter() throws {
            let animation = MessageAnimation.fromString("center")
            XCTAssertEqual(animation, .center)
        }
    
        func testValueFade() throws {
            XCTAssertEqual(6, MessageAnimation.fade.rawValue)
        }
    
        func testFromStringFade() throws {
            let animation = MessageAnimation.fromString("fade")
            XCTAssertEqual(animation, .fade)
        }
    
        func testFromStringNoMatch() throws {
            let animation = MessageAnimation.fromString("oopsee")
            XCTAssertEqual(animation, .none)
        }
    }
#endif
