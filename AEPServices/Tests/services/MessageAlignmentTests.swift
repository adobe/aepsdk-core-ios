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

    class MessageAlignmentTests: XCTestCase {
        func testValueCenter() throws {
            XCTAssertEqual(0, MessageAlignment.center.rawValue)
        }
    
        func testFromStringCenter() throws {
            let align = MessageAlignment.fromString("center")
            XCTAssertEqual(align, .center)
        }
    
        func testValueLeft() throws {
            XCTAssertEqual(1, MessageAlignment.left.rawValue)
        }
    
        func testFromStringLeft() throws {
            let align = MessageAlignment.fromString("left")
            XCTAssertEqual(align, .left)
        }
    
        func testValueRight() throws {
            XCTAssertEqual(2, MessageAlignment.right.rawValue)
        }
    
        func testFromStringRight() throws {
            let align = MessageAlignment.fromString("right")
            XCTAssertEqual(align, .right)
        }
    
        func testValueTop() throws {
            XCTAssertEqual(3, MessageAlignment.top.rawValue)
        }
    
        func testFromStringTop() throws {
            let align = MessageAlignment.fromString("top")
            XCTAssertEqual(align, .top)
        }
    
        func testValueBottom() throws {
            XCTAssertEqual(4, MessageAlignment.bottom.rawValue)
        }
    
        func testFromStringBottom() throws {
            let align = MessageAlignment.fromString("bottom")
            XCTAssertEqual(align, .bottom)
        }
    
        func testFromStringNoMatch() throws {
            let align = MessageAlignment.fromString("oopsee")
            XCTAssertEqual(align, .center, "center should be returned when there's no matching string")
        }
    }
#endif
