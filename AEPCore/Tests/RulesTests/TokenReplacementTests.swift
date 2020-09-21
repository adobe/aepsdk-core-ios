/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

import XCTest

@testable import AEPRulesEngine

class TokenReplacementTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTokenReplacementNormal() {
        let template = Template(templateString: "aaa{%test%}aaa", tagDelimiterPair: ("{%", "%}"))
        let tran = Transform()
        let result = template.render(data: ["test": "_test_"] as! Traversable, transformers: tran)
        XCTAssertEqual("aaa_test_aaa", result)
    }

    func testTokenReplacementWithTransformation() {
        let template = Template(templateString: "aaa/key={%urlenc(test)%}/aaa", tagDelimiterPair: ("{%", "%}"))
        let tran = Transform()
        tran.register(name: "urlenc", transformation: { value in
            if value is String {
                return (value as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            }
            return value
        })
        let result = template.render(data: ["test": "value 1"] as! Traversable, transformers: tran)
        XCTAssertEqual("aaa/key=value%201/aaa", result)
    }
}
