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

class E2ETestingUITests: XCTestCase {

    override func setUp()  {
        continueAfterFailure = true
    }

    override func tearDown() {

    }

    func testFirstLaunchRule() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Clear Caches/UserDefault"].tap()
        app.buttons["Load AEP SDK"].tap()
        XCTAssert(app.staticTexts["Eventhub Booted"].waitForExistence(timeout: 5))
        sleep(3)
        app.buttons["Verify First Launch Rules"].tap()
        XCTAssert(app.staticTexts["Install event got evaluated"].waitForExistence(timeout: 5))
    }

    func testAttachDataRule() throws {

        let app = XCUIApplication()
        app.launch()
        app.buttons["Load AEP SDK"].tap()
        XCTAssert(app.staticTexts["Eventhub Booted"].waitForExistence(timeout: 5))

        app.buttons["Verify Attach Data Rules"].tap()
        XCTAssert(app.staticTexts["Catch the track action event with attached data"].waitForExistence(timeout: 5))
    }

    func testModifyDataRule() throws {

        let app = XCUIApplication()
        app.launch()
        app.buttons["Load AEP SDK"].tap()
        XCTAssert(app.staticTexts["Eventhub Booted"].waitForExistence(timeout: 5))

        app.buttons["Verify Modify Data Rules"].tap()
        XCTAssert(app.staticTexts["Catch the track action event with modified data"].waitForExistence(timeout: 5))
    }
}
