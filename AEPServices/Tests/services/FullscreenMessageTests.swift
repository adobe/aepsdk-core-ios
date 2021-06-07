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

import Foundation
@testable import AEPServices
import XCTest
import UIKit
import AEPServicesMocks

class FullscreenMessageTests : XCTestCase {
    let mockHtml = "somehtml"
    static var onShowFullscreenMessagingCall = false
    static var onDismissFullscreenMessagingCall = false
    static var onShowFailedCall = false
    var fullscreenMessage : FullscreenMessage?
    static var expectation: XCTestExpectation?
    var mockUIService: UIService?

    var rootViewController: UIViewController!

    var messageMonitor = MessageMonitor()
    var fullscreenListener = MockFullscreenListener()

    override func setUp() {
        FullscreenMessageTests.onShowFullscreenMessagingCall = false
        FullscreenMessageTests.onDismissFullscreenMessagingCall = false
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: fullscreenListener, isLocalImageUsed: false, messageMonitor: messageMonitor)
        mockUIService = MockUIService()
        ServiceProvider.shared.uiService = mockUIService!
    }

    func test_init_whenListenerIsNil() {
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: nil, isLocalImageUsed: false, messageMonitor: messageMonitor)
        XCTAssertNotNil(fullscreenMessage)
    }

    func test_init_whenIsLocalImageTrue() {
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: true, messageMonitor: messageMonitor)
        XCTAssertNotNil(fullscreenMessage)
    }

    func test_init_whenIsLocalImageFalse() {
        fullscreenMessage = FullscreenMessage(payload: mockHtml, listener: MockFullscreenListener(), isLocalImageUsed: false, messageMonitor: messageMonitor)
        XCTAssertNotNil(fullscreenMessage)
    }

    func test_dismiss() {
        FullscreenMessageTests.expectation = XCTestExpectation(description: "Testing Dismiss FullscreenMessage")
        messageMonitor.displayMessage()
        fullscreenMessage?.dismiss()
        wait(for: [FullscreenMessageTests.expectation!], timeout: 10.0)
        XCTAssertTrue(FullscreenMessageTests.onDismissFullscreenMessagingCall)
    }

    func test_show() {
        FullscreenMessageTests.expectation = XCTestExpectation(description: "Testing Show FullscreenMessage")
        messageMonitor.dismissMessage()
        XCTAssertNoThrow(fullscreenMessage?.show())
    }

    func test_showFailed() {
        FullscreenMessageTests.expectation = XCTestExpectation(description: "Testing show failed")
        fullscreenMessage?.show()
        wait(for: [FullscreenMessageTests.expectation!], timeout: 1.0)
        XCTAssertTrue(FullscreenMessageTests.onShowFailedCall)
    }

    class MockFullscreenListener: FullscreenMessageDelegate {
        func onShow(message: FullscreenMessage) {
            FullscreenMessageTests.onShowFullscreenMessagingCall = true
            FullscreenMessageTests.expectation?.fulfill()
        }

        func onDismiss(message: FullscreenMessage) {
            FullscreenMessageTests.onDismissFullscreenMessagingCall = true
            FullscreenMessageTests.expectation?.fulfill()
        }

        func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
            return true
        }

        func onShowFailure() {
            FullscreenMessageTests.onShowFailedCall = true
            FullscreenMessageTests.expectation?.fulfill()
        }
    }
}
