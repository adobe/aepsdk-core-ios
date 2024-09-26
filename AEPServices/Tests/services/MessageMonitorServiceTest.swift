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
#if os(iOS)
    import Foundation
    @testable import AEPServices
    import XCTest

    @available(iOSApplicationExtension, unavailable)
    class MessageMonitorServiceTest : XCTestCase {

        static var mockShouldShow = false

        static var onShowCall = false
        static var onDismissCall = false
        static var shouldShowMessageCall = false
        var mockMessageMonitor: MessageMonitoring!
        var messageDelegate : MessagingDelegate?
        var message: FullscreenPresentable?

        override func setUp() {
            MessageMonitorServiceTest.onShowCall = false
            MessageMonitorServiceTest.onDismissCall = false
            MessageMonitorServiceTest.mockShouldShow = true
            mockMessageMonitor = MessageMonitor()
            message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: mockMessageMonitor!)
            messageDelegate = MockGlobalUIMessagingListener()
            ServiceProvider.shared.messagingDelegate = messageDelegate
        }

        func test_isMessageDisplayed_DefaultIsFalse() {
            XCTAssertFalse(mockMessageMonitor.isMessageDisplayed())
        }

        func test_isMessageDisplayed_isTrue_whenDislayMessageCalled() {
            mockMessageMonitor?.displayMessage()
            XCTAssertTrue(mockMessageMonitor.isMessageDisplayed())
        }

        func test_isMessageDisplayed_isFalse_whenDismissMessageIsCalled() {
            mockMessageMonitor?.dismissMessage()
            XCTAssertFalse(mockMessageMonitor.isMessageDisplayed())
        }

        func test_show_whenMessageAlreadyDisplayed() {
            mockMessageMonitor?.displayMessage()
            let (shouldShow, error) = mockMessageMonitor.show(message: message!)
            XCTAssertFalse(shouldShow)
            XCTAssertEqual(PresentationError(.showFailure("Conflict")).getReason(), error?.getReason())
        }

        func test_show_withShouldShowMessageTrue() {
            let (shouldShow, error) = mockMessageMonitor.show(message: message!)
            XCTAssertTrue(shouldShow)
            XCTAssertNil(error)
            XCTAssertTrue(mockMessageMonitor.isMessageDisplayed())
        }

        func test_show_withShouldShowMessageFalse() {
            MessageMonitorServiceTest.mockShouldShow = false
            let (shouldShow, error) = mockMessageMonitor.show(message: message!)
            XCTAssertFalse(shouldShow)
            XCTAssertEqual(PresentationError(.showFailure("SuppressedByAppDeveloper")).getReason(), error?.getReason())
            XCTAssertFalse(mockMessageMonitor.isMessageDisplayed())
        }

        func test_dismiss_whenNoMessageToDismiss() {
            mockMessageMonitor.dismissMessage()
            XCTAssertFalse(mockMessageMonitor.dismiss())
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
#endif
