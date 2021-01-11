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
@testable import AEPServices
import XCTest



class UIServiceTests : XCTestCase {

    let mockHtml = "somehtml"
    static var onShowCall = false
    static var onDismissCall = false

    func reset() {
        UIServiceTests.onShowCall = false
        UIServiceTests.onDismissCall = false
    }

    func test_CreateFullscreenMessage_whenValidMessage() {
        let message = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener())
        XCTAssertNotNil(message)
    }

    func test_CreateFullscreenMessage_whenListenerIsNil() {
        let message = FullscreenMessage(payload: mockHtml, listener: nil)
        XCTAssertNotNil(message)
    }

    func test_CreateFullscreenMessage_whenIsLocalImageTrue() {
        let message = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: true)
        XCTAssertNotNil(message)
    }

    func test_CreateFullscreenMessage_whenIsLocalImageFalse() {
        let message = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: false)
        XCTAssertNotNil(message)
    }

    func test_isMessageDisplayed_DefaultIsFalse() {
        let uiService = MessageMonitor()
        let isDisplayed = uiService.isMessageDisplayed()
        XCTAssertFalse(isDisplayed)
    }

    func test_ListenerOnShow_IsCalled() {
        let uiService = MessageMonitor()
        let message = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: true)
        XCTAssertNotNil(message)
        uiService.show(message: message)
        XCTAssertTrue(UIServiceTests.onShowCall)
        reset()
    }

    class MockFullscreenListener: FullscreenMessaging {
        func onShow(message: UIMessaging?) {
            UIServiceTests.onShowCall = true
        }

        func onDismiss(message: UIMessaging?) {
            UIServiceTests.onDismissCall = true
        }

        func overrideUrlLoad(message: UIMessaging?, url: String?) -> Bool {
            return true
        }
    }
}
