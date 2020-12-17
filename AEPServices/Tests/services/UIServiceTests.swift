//
//  UIService.swift
//  AEPServicesTests
//
//  Created by ravjain on 12/17/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

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
        let uiService = UIService()
        let message = uiService.createFullscreenMessage(html: mockHtml, fullscreenListener: MockFullscreenListener())
        XCTAssertNotNil(message)
    }
    
    func test_CreateFullscreenMessage_whenListenerIsNil() {
        let uiService = UIService()
        let message = uiService.createFullscreenMessage(html: mockHtml, fullscreenListener: nil)
        XCTAssertNotNil(message)
    }
    
    func test_CreateFullscreenMessage_whenIsLocalImageTrue() {
        let uiService = UIService()
        let message = uiService.createFullscreenMessage(html: mockHtml, fullscreenListener: MockFullscreenListener(), isLocalImageUsed: true)
        XCTAssertNotNil(message)
    }
    
    func test_CreateFullscreenMessage_whenIsLocalImageFalse() {
        let uiService = UIService()
        let message = uiService.createFullscreenMessage(html: mockHtml, fullscreenListener: MockFullscreenListener(), isLocalImageUsed: true)
        XCTAssertNotNil(message)
    }

    func test_isMessageDisplayed_DefaultIsFalse() {
        let uiService = UIService()
        let isDisplayed = uiService.isMessageDisplayed()
        XCTAssertFalse(isDisplayed)
    }
    
    func test_ListenerOnShow_IsCalled() {
        let uiService = UIService()
        let message = uiService.createFullscreenMessage(html: mockHtml, fullscreenListener: MockFullscreenListener(), isLocalImageUsed: true)
        XCTAssertNotNil(message)
        message?.show()
        XCTAssertTrue(UIServiceTests.onShowCall)
        reset()
    }

    class MockFullscreenListener: FullscreenListenerInterface {
        func onShow(message: FullScreenMessageUiInterface?) {
            UIServiceTests.onShowCall = true
        }

        func onDismiss(message: FullScreenMessageUiInterface?) {
            UIServiceTests.onDismissCall = true
        }

        func overrideUrlLoad(message: FullScreenMessageUiInterface?, url: String?) -> Bool {
            return true
        }
    }
}
