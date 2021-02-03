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

class MessageMonitorServiceTest : XCTestCase {

    static var mockShouldShow = false

    static var onShowCall = false
    static var onDismissCall = false
    static var shouldShowMessageCall = false
    var mockMessageMonitorService: MessageMonitorService?
    var messageDelegate : MessagingDelegate?
    var message: FullscreenPresentable = FullscreenMessage(payload: "", listener: nil)

    override func setUp() {
        MessageMonitorServiceTest.onShowCall = false
        MessageMonitorServiceTest.onDismissCall = false
        MessageMonitorServiceTest.mockShouldShow = true
        mockMessageMonitorService = MessageMonitorService()
        messageDelegate = MockGlobalUIMessagingListener()
        ServiceProvider.shared.messagingDelegate = messageDelegate
    }

    func test_isMessageDisplayed_DefaultIsFalse() {
        let isDisplayed = mockMessageMonitorService?.isMessageDisplayed()
        XCTAssertTrue((isDisplayed == false))
    }

    func test_isMessageDislayed_isTrue_whenDislayMessageCalled() {
        mockMessageMonitorService?.displayMessage()
        let display : Bool = mockMessageMonitorService?.isMessageDisplayed() == true
        XCTAssertTrue(display)
    }

    func test_isMessageDislayed_isFalse_whenDismissMessageIsCalled() {
        mockMessageMonitorService?.dismissMessage()
        let display : Bool = mockMessageMonitorService?.isMessageDisplayed() == false
        XCTAssertTrue(display)
    }

    func test_show_whenMessageAlreadyDisplayed() {
        mockMessageMonitorService?.displayMessage()
        XCTAssertTrue(mockMessageMonitorService?.show(message: message) == false)
    }

    func test_show_withShouldShowMessageTrue() {
        XCTAssertTrue(mockMessageMonitorService?.show(message: message) == true)
        let display : Bool = mockMessageMonitorService?.isMessageDisplayed() == true
        XCTAssertTrue(display)
    }

    func test_show_withShouldShowMessageFalse() {
        MessageMonitorServiceTest.mockShouldShow = false
        XCTAssertTrue(mockMessageMonitorService?.show(message: message) == false)
        let display : Bool = mockMessageMonitorService?.isMessageDisplayed() == false
        XCTAssertTrue(display)
    }

    func test_dismiss_whenNoMessageToDismiss() {
        mockMessageMonitorService?.dismissMessage()
        XCTAssertTrue(mockMessageMonitorService?.dismiss() == false)
    }

    class MockGlobalUIMessagingListener : MessagingDelegate {
        func onShow(message: Showable) {
            onShowCall = true
        }

        func onDismiss(message: Showable) {
            onDismissCall = true
        }

        func shouldShowMessage(message: Showable) -> Bool {
            shouldShowMessageCall = true
            return MessageMonitorServiceTest.mockShouldShow
        }
    }
}
