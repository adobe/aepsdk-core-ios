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

class AlertMessageTests : XCTestCase {
    static let mockTitle = "mockTitle"
    static let mockMessage = "mockMessage"
    static let mockPositiveLabel = "mockPositiveLabel"
    static let mockNegativeLabel = "mockNegativeLabel"
    var alertMessage : AlertMessage?
    static var expectation: XCTestExpectation?
    var rootViewController: UIViewController!
    var mockUIService: UIService?

    var mockListener: AlertMessageDelegate?
    var messageDelegate : MessagingDelegate?
    
    var messageMonitor = MessageMonitor()

    static var onShowFailedCall = false
    
    override func setUp() {
        mockListener = MockListener()
        alertMessage = AlertMessage(title: AlertMessageTests.mockTitle, message: AlertMessageTests.mockMessage, positiveButtonLabel: AlertMessageTests.mockPositiveLabel, negativeButtonLabel: AlertMessageTests.mockNegativeLabel, listener: mockListener, messageMonitor: messageMonitor)
        messageDelegate = MockGlobalUIMessagingListener()
        ServiceProvider.shared.messagingDelegate = messageDelegate
        mockUIService = MockUIService()
        ServiceProvider.shared.uiService = mockUIService!
    }

    func test_init_whenListenerIsNil() {
        alertMessage = AlertMessage(title: AlertMessageTests.mockTitle, message: AlertMessageTests.mockMessage, positiveButtonLabel: AlertMessageTests.mockPositiveLabel, negativeButtonLabel: AlertMessageTests.mockNegativeLabel, listener: nil, messageMonitor: messageMonitor)
        XCTAssertNotNil(alertMessage)
    }

    func test_init_whenListenerIsPresent() {
        XCTAssertNotNil(alertMessage)
    }

    func test_show() {
        messageMonitor.dismissMessage()
        XCTAssertNoThrow(alertMessage?.show())
    }
    
    func testShowFailed() {
        AlertMessageTests.expectation = XCTestExpectation(description: "Testing show failed")
        alertMessage = AlertMessage(title: "", message: "", positiveButtonLabel: "", negativeButtonLabel: "", listener: mockListener, messageMonitor: messageMonitor)
        alertMessage?.show()
        wait(for: [AlertMessageTests.expectation!], timeout: 1.0)
        XCTAssertTrue(AlertMessageTests.onShowFailedCall)
    }

    class MockListener: AlertMessageDelegate {
        func onPositiveResponse(message: AlertMessage) {}
        func onNegativeResponse(message: AlertMessage) {}
        func onShow(message: AlertMessage) {}
        func onDismiss(message: AlertMessage) {}
        func onShowFailed() {
            AlertMessageTests.onShowFailedCall = true
            AlertMessageTests.expectation?.fulfill()
        }
    }

    class MockGlobalUIMessagingListener : MessagingDelegate {
        func onShow(message: Showable) {}

        func onDismiss(message: Showable) {}

        func shouldShowMessage(message: Showable) -> Bool {
            return MessageMonitorServiceTest.mockShouldShow
        }
    }
}
