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
import AEPServices
import XCTest

public class MockFullscreenListener: FullscreenMessageDelegate {
    var onShowCalled = false
    var onDismissCalled = false
    var overrideUrlLoadCalled = false
    var onShowFailureCalled = false
    
    var expectation: XCTestExpectation?
    
    public func setExpectation(_ expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    public func onShow(message: FullscreenMessage) {
        onShowCalled = true
        expectation?.fulfill()
    }
    
    public func onDismiss(message: FullscreenMessage) {
        onDismissCalled = true
        expectation?.fulfill()
    }
    
    public func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        overrideUrlLoadCalled = true
        return true
    }
    
    public func onShowFailure() {
        onShowFailureCalled = true
        expectation?.fulfill()
    }
}
