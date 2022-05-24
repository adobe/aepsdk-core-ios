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

@available(iOSApplicationExtension, unavailable)
class FloatingButtonTests : XCTestCase {

    var mockListener: FloatingButtonDelegate?
    var floatingButton : FloatingButton?
    var mockUIService: UIService?

    override func setUp() {
        mockListener = MockListener()
        mockUIService = MockUIService()
        ServiceProvider.shared.uiService = mockUIService!
    }

    func test_init_whenListenerIsNil() {
        floatingButton = FloatingButton(listener: nil)
        XCTAssertNotNil(floatingButton)
    }

    func test_init_whenListenerIsPresent() {
        floatingButton = FloatingButton(listener: mockListener)
        XCTAssertNotNil(floatingButton)
    }

    func test_display() {
        floatingButton = FloatingButton(listener: mockListener)
        XCTAssertNoThrow(floatingButton?.show())
    }

    func test_remove() {
        floatingButton = FloatingButton(listener: mockListener)
        XCTAssertNoThrow(floatingButton?.dismiss())
    }

    func test_setButtonImage() {
        floatingButton = FloatingButton(listener: mockListener)
        XCTAssertNoThrow(floatingButton?.setButtonImage(imageData: Data()))
    }

    func test_setInitialPosition() {
        floatingButton = FloatingButton(listener: mockListener)
        XCTAssertNoThrow(floatingButton?.setInitial(position: .center))
        XCTAssertNoThrow(floatingButton?.show())
    }

    class MockListener: FloatingButtonDelegate {
        func onShow() {}
        func onDismiss() {}
        func onTapDetected() {}
        func onPanDetected() {}
    }
}

