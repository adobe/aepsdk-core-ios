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
import UIKit

class FullscreenMessageTests : XCTestCase {
    let mockHtml = "somehtml"
    static var onShowFullscreenMessagingCall = false
    static var onDismissullscreenMessagingCall = false
    var fullscreenMessage : FullscreenMessage?
    static var expectation: XCTestExpectation?

    var rootViewController: UIViewController!

    override func setUp() {
        FullscreenMessageTests.onShowFullscreenMessagingCall = false
        FullscreenMessageTests.onDismissullscreenMessagingCall = false
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener())
    }

    func test_init_whenListenerIsNil() {
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: nil)
        XCTAssertNotNil(fullscreenMessage)
    }

    func test_init_whenIsLocalImageTrue() {
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: true)
        XCTAssertNotNil(fullscreenMessage)
    }

    func test_init_whenIsLocalImageFalse() {
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: false)
        XCTAssertNotNil(fullscreenMessage)
    }

    func test_dismiss() {
        FullscreenMessageTests.expectation = XCTestExpectation(description: "Testing Dismiss")
        ServiceProvider.shared.messageMonitorService.displayMessage()
        fullscreenMessage?.dismiss()
        wait(for: [FullscreenMessageTests.expectation!], timeout: 10.0)
        XCTAssertTrue(FullscreenMessageTests.onDismissullscreenMessagingCall)
    }

    func test_show() {
        ServiceProvider.shared.messageMonitorService.dismissMessage()
        fullscreenMessage?.show()
        XCTAssertTrue(ServiceProvider.shared.messageMonitorService.isMessageDisplayed())
    }

    class MockFullscreenListener: FullscreenMessaging {
        func onShow(message: FullscreenMessage?) {
            FullscreenMessageTests.onShowFullscreenMessagingCall = true
            FullscreenMessageTests.expectation?.fulfill()
        }

        func onDismiss(message: FullscreenMessage?) {
            FullscreenMessageTests.onDismissullscreenMessagingCall = true
            FullscreenMessageTests.expectation?.fulfill()
        }

        func overrideUrlLoad(message: FullscreenMessage?, url: String?) -> Bool {
            return true
        }
    }
}
