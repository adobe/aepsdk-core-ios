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

class MessageMonitorServiceTest : XCTestCase {
    
    static var mockShouldShow = false
    
    static var onShowCall = false
    static var onDismissCall = false
    static var shouldShowMessageCall = false
    var mockMessageMonitorService: MessageMonitorService?

    override func setUp() {
        MessageMonitorServiceTest.onShowCall = false
        MessageMonitorServiceTest.onDismissCall = false
        MessageMonitorServiceTest.mockShouldShow = true
        mockMessageMonitorService = MessageMonitorService()
        mockMessageMonitorService?.setGlobalUIMessagingListener(listener: MockGlobalUIMessagingListener())
    }
    
    func test_setGlobalUIMessagingListener_whenValidGlobalListeners() {
        XCTAssertNotNil(mockMessageMonitorService?.globalUIMessagingListener)
    }
    
    func test_setGlobalUIMessagingListener_whenNilGlobalListeners() {
        mockMessageMonitorService?.setGlobalUIMessagingListener(listener: nil)
        XCTAssertNil(mockMessageMonitorService?.globalUIMessagingListener)
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
        XCTAssertTrue(mockMessageMonitorService?.show() == false)
    }

    func test_show_withShouldShowMessageTrue() {
        XCTAssertTrue(mockMessageMonitorService?.show() == true)
        let display : Bool = mockMessageMonitorService?.isMessageDisplayed() == true
        XCTAssertTrue(display)
    }
    
    func test_show_withShouldShowMessageFalse() {
        MessageMonitorServiceTest.mockShouldShow = false
        XCTAssertTrue(mockMessageMonitorService?.show() == false)
        let display : Bool = mockMessageMonitorService?.isMessageDisplayed() == false
        XCTAssertTrue(display)
    }
    
    func test_dismiss_whenNoMessageToDismiss() {
        mockMessageMonitorService?.dismissMessage()
        XCTAssertTrue(mockMessageMonitorService?.dismiss() == false)
    }
    
    class MockGlobalUIMessagingListener : GlobalUIMessaging {
        func onShow() {
            onShowCall = true
        }
        
        func onDismiss() {
            onDismissCall = true
        }
        
        func shouldShowMessage() -> Bool {
            shouldShowMessageCall = true
            return MessageMonitorServiceTest.mockShouldShow
        }
    }
}
