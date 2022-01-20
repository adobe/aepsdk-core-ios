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

import XCTest

@testable import AEPCore

class String_FNV1A32Tests: XCTestCase {

    func testWeirdThings() throws {
        // setup
        let string = "UpperCase:abc_underscore:scorekey:valuenumber:1234"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(960895195, result)
    }
    
    func testRecursiveCalls() throws {
        // setup
        let string = "UpperCase:abc_underscore:scorekey:valuenumber:1234"
        
        // test
        let combinedResult = string.fnv1a32(0)
        let recursiveResult = "number:1234".fnv1a32("key:value".fnv1a32("_underscore:score".fnv1a32("UpperCase:abc".fnv1a32(0))))
        
        // verify
        XCTAssertEqual(960895195, combinedResult)
        XCTAssertEqual(combinedResult, recursiveResult)
    }
    
    // MARK: - Cross-platform tests
    
    // The following tests have equivalents in the Android SDK and are used to ensure both platforms are producing
    // hash values that are consistent with one another.
    // The values are validated against an online hash calculator: https://md5calc.com/hash/fnv1a32?str=
    func testCrossPlatform1() throws {
        // setup
        let string = "aaa:1zzz:true"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(3251025831, result)
    }
    
    func testCrossPlatform2() throws {
        // setup
        let string = "c:2m:1.11"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(2718815288, result)
    }
    
    func testCrossPlatform3() throws {
        // setup
        let string = "aaa:1inner.bbb:5inner.hhh:falsezzz:true"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(4230384023, result)
    }
    
    func testCrossPlatform4() throws {
        // setup
        let string = "aaa:1inner.bbb:5inner.hhh:falseinner.secondInner.ccc:10inner.secondInner.iii:1.1zzz:true"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(1786696518, result)
    }
    
    func testCrossPlatform5() throws {
        // setup
        let string = "a:1b:2"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(3371500665, result)
    }
    
    func testCrossPlatform6() throws {
        // setup
        let string = "1:1222:222A:2Ba:4Bc:10R:8Z:5a:1ba:3bc:9r:7z:6"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(2933724447, result)
    }
    
    func testCrossPlatform7() throws {
        // setup
        let string = "1:1A:2Ba:4Bc:10a:1ba:3bc:9"
        
        // test
        let result = string.fnv1a32(0)
        
        // verify
        XCTAssertEqual(3344627991, result)
    }
}
