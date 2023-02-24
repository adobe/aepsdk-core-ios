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

    // List of test language strings to verify isValidLanguageTag positive function
    let isValidLanguageTagCasesTrue = [
        ("en-US"),
        ("en"),
        ("und-US"),
        ("und-u-va-posix"),
        ("und-POSIX"),
        ("und"),
        ("de-u-va-posix"),
        ("de-DE-u-va-posix"),
        ("de-DE-POSIX"),
        ("de-POSIX"),
        ("de-Latn-POSIX"),
        ("zh-Hant-HK"),
        ("und-Hans-CN"),
        ("no-NO-x-lvariant-ny"),
        ("sr-Latn-ME"),
        ("sr-ME-x-lvariant-Latn"),
        ("ja-JP-x-lvariant-jp"),
        ("ja-JP-u-ca-japanese"),
        ("th-TH-x-lvariant-th"),
        ("th-TH-u-ca-buddhist"),
        ("en-u-ca-buddhist-nu-thai"),
        ("th-TH-u-ca-buddhist-nu-thai"),
        ("i-klingon")
    ]

    func testIsValidLanguageTag_positiveCases() throws {
        XCTAssertFalse(isValidLanguageTagCasesTrue.isEmpty)

        isValidLanguageTagCasesTrue.forEach {
            let lang = XDMLanguage(language: $0)
            XCTAssertEqual($0, lang.language, "Expected input language '\($0)' to be valid.")
        }
    }

    // List of test language strings to verify isValidLanguageTag negative function
    let isValidLanguageTagCasesFalse = [
        ("en@calendar=buddhist;numbers=thai"),
        ("en-US@calendar=buddhist"),
        ("-US"),
        ("en_US"),
        ("de--POSIX"),
        ("zh-HK#Hant"),
        ("th-TH-TH-#u-nu-thai"),
        ("")
    ]

    func testIsValidLanguageTag_negativeCases() throws {
        XCTAssertFalse(isValidLanguageTagCasesFalse.isEmpty)

        isValidLanguageTagCasesFalse.forEach {
            let lang = XDMLanguage(language: $0)
            XCTAssertNil(lang.language, "Expected input language '\($0)' to be invalid.")
        }
    }

}

