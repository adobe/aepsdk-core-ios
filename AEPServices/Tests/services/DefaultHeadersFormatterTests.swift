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

@testable import AEPServices

class DefaultHeadersFormatterTest: XCTestCase {
    private var localeStringArr: [[String: String]] = {
        [
            ["en-US": "C"],
            ["en-US": "*"],
            ["en-US": "POSIX"],
            ["en-GB": "en_GB"],
            ["en-US": "en_US.UTF-8"],
            ["it-CH": "it_CH.ISO8859-1"],
            ["it-CH": "it_CH.ISO8859-15"],
            ["ja-JP": "ja_JP.SJIS"],
            ["ru-RU": "ru_RU.KOI8-R"],
            ["zh-HK": "zh_HK.Big5HKSCS"],
            ["de-DE": "de-DE_phoneb"],
            ["en": "en"],
            ["ast": "ast"],
            ["zh": "zh-Hant"],
            ["zh-HK": "zh_Hant_HK"],
            ["zh": "zh-yue"],
            ["zh-HK": "zh_yue_HK"],
            ["zh-HK": "zh-yue-Hant-HK"],
            ["es-005": "es_005"],
            ["de-DE": "de_DE_u_co_phonebk"],
            ["sl": "sl_nedis"],
            ["es-ES": "es-ES-i-klingon"]
        ]
    }()

    func testDifferentFormattedLocales() {
        for dict in localeStringArr {
            guard let (k, v) = dict.first else {
                XCTFail()
                return
            }

            let formattedLocale = DefaultHeadersFormatter.formatLocale(v)

            XCTAssertEqual(k, formattedLocale)
        }
    }

    func testEmptyLocale() {
        let formattedLocale = DefaultHeadersFormatter.formatLocale("")
        XCTAssertEqual("en-US", formattedLocale)
    }
}

