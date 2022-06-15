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
    @testable import AEPServices
    import XCTest

    class MessagingDelegateTests: XCTestCase {
    
        let delegate = TestDelegate()
        let showable = TestShowable()
        let url = URL(string: "https://adobe.com")!
        
        class TestShowable: Showable {
            func show() {}
        }
    
        class TestDelegate: MessagingDelegate {
            var onShowCalled = false
            var onDismissCalled = false
            var shouldShowMessageCalled = false
            var urlLoadedCalled = false
            var paramShowable: Showable?
            var paramUrl: URL?
        
            func onShow(message: Showable) {
                paramShowable = message
                onShowCalled = true
            }
        
            func onDismiss(message: Showable) {
                paramShowable = message
                onDismissCalled = true
            }
        
            func shouldShowMessage(message: Showable) -> Bool {
                paramShowable = message
                shouldShowMessageCalled = true
                return true
            }
        
            func urlLoaded(_ url: URL, byMessage message: Showable) {
                paramShowable = message
                paramUrl = url
                urlLoadedCalled = true
            }
        }
    
        func testOnShow() throws {
            delegate.onShow(message: showable)
            XCTAssertTrue(delegate.onShowCalled)
            XCTAssertNotNil(delegate.paramShowable)
            XCTAssertNotNil(delegate.paramShowable as? TestShowable)
        }
    
        func testOnDismiss() throws {
            delegate.onDismiss(message: showable)
            XCTAssertTrue(delegate.onDismissCalled)
            XCTAssertNotNil(delegate.paramShowable)
            XCTAssertNotNil(delegate.paramShowable as? TestShowable)
        }
    
        func testShouldShowMessage() throws {
            let result = delegate.shouldShowMessage(message: showable)
            XCTAssertTrue(result)
            XCTAssertTrue(delegate.shouldShowMessageCalled)
            XCTAssertNotNil(delegate.paramShowable)
            XCTAssertNotNil(delegate.paramShowable as? TestShowable)
        }
    
        func testUrlLoaded() throws {
            delegate.urlLoaded(url, byMessage: showable)
            XCTAssertTrue(delegate.urlLoadedCalled)
            XCTAssertNotNil(delegate.paramShowable)
            XCTAssertNotNil(delegate.paramShowable as? TestShowable)
            XCTAssertEqual(url, delegate.paramUrl)
        }
    }
#endif
