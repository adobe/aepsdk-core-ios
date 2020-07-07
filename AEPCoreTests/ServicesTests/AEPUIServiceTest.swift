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

@testable import AEPCore
import XCTest

class AEPUIServiceTest: XCTestCase {
    private let uiService = AEPServiceProvider.shared.uiService

    func urlHandlerReturnFalse(url: String) -> Bool {
        false
    }

    func urlHandlerReturnTrue(url: String) -> Bool {
        true
    }

    func testOpenUrl() throws {
        XCTAssertTrue(uiService.openUrl("adobe.com"))
    }

    func testUrlHandlerReturnFalse() throws {
        AEPUrlHandler.urlHandler = urlHandlerReturnFalse
        XCTAssertFalse(uiService.openUrl("adobe.com"))
    }

    func testUrlHandlerReturnTrue() throws {
        AEPUrlHandler.urlHandler = urlHandlerReturnTrue
        XCTAssertTrue(uiService.openUrl("adobe.com"))
    }

    func testOpenUrlWithEmptyString() throws {
        XCTAssertFalse(uiService.openUrl(""))
    }
}
