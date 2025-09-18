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

import XCTest

@testable import AEPRulesEngine

class TokenReplacementTests: XCTestCase {
    func testTokenReplacementNormal() {
        let template = Template(templateString: "aaa{%test%}aaa", tagDelimiterPair: ("{%", "%}"))
        let tran = Transformer()
        let traversable = TestableTraversable(["test": "_test_"])
        let result = template.render(data: traversable, transformers: tran)
        XCTAssertEqual("aaa_test_aaa", result)
    }

    func testTokenReplacementWithTransformation() {
        let template = Template(templateString: "aaa/key={%urlenc(test)%}/aaa", tagDelimiterPair: ("{%", "%}"))
        let tran = Transformer()
        tran.register(name: "urlenc", transformation: { value in
            if value is String {
                return (value as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            }
            return value
        })
        let traversable = TestableTraversable(["test": "value 1"])
        let result = template.render(data: traversable, transformers: tran)
        XCTAssertEqual("aaa/key=value%201/aaa", result)
    }
}
