/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPLifecycle
import XCTest

class XDMLanguageTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    // MARK: Encodable tests

    func testEncodeLanguage_whenValid() throws {
        // setup
        let lang = XDMLanguage(language: "en-US")
        XCTAssertEqual("en-US", lang.language)

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(lang))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "language" : "en-US"
        }
        """

        XCTAssertEqual(expected, dataStr)
    }

    func testEncodeLanguage_whenInvalid() throws {
        // setup
        let lang = XDMLanguage(language: "en-US@calendar=buddhist")
        XCTAssertNil(lang.language)

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(lang))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {

        }
        """

        XCTAssertEqual(expected, dataStr)
    }

    // MARK: isValidLanguageTag tests

    // List of test language strings to verify isValidLanguageTag function
    // [$0: language string to test, $1: expected is valid]
    let isValidLanguageTagCases = [
        ("en-US", true),
        ("en", true),
        ("und-US", true),
        ("und-u-va-posix", true),
        ("und-POSIX", true),
        ("und", true),
        ("de-u-va-posix", true),
        ("de-DE-u-va-posix", true),
        ("de-DE-POSIX", true),
        ("de-POSIX", true),
        ("de-Latn-POSIX", true),
        ("zh-Hant-HK", true),
        ("und-Hans-CN", true),
        ("no-NO-x-lvariant-ny", true),
        ("sr-Latn-ME", true),
        ("sr-ME-x-lvariant-Latn", true),
        ("ja-JP-x-lvariant-jp", true),
        ("ja-JP-u-ca-japanese", true),
        ("th-TH-x-lvariant-th", true),
        ("th-TH-u-ca-buddhist", true),
        ("en-u-ca-buddhist-nu-thai", true),
        ("th-TH-u-ca-buddhist-nu-thai", true),
        ("i-klingon", true),
        ("en@calendar=buddhist;numbers=thai", false),
        ("en-US@calendar=buddhist", false),
        ("-US", false),
        ("en_US", false),
        ("de--POSIX", false),
        ("zh-HK#Hant", false),
        ("th-TH-TH-#u-nu-thai", false),
        ("", false)
    ]

    func testIsValidLanguageTag() throws {
        XCTAssertFalse(isValidLanguageTagCases.isEmpty)

        isValidLanguageTagCases.forEach {
            let lang = XDMLanguage(language: $0)
            if $1 {
                XCTAssertEqual($0, lang.language, "Expected input language '\($0)' to be valid.")
            } else {
                XCTAssertNil(lang.language, "Expected input language '\($0)' to be invalid.")
            }
        }


    }

}

