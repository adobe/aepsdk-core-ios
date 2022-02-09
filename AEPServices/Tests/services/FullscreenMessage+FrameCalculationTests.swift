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

@testable import AEPServices
import XCTest

class FullscreenMessage_FrameCalculationTests: XCTestCase {
    
    let ACCURACY = 0.00001
    var message: FullscreenMessage!
    var monitor: MessageMonitoring!
    var noAnimationSettings: MessageSettings!
    var topSettings: MessageSettings!
    var botSettings: MessageSettings!
    var rightSettings: MessageSettings!
    var leftSettings: MessageSettings!
    var centerSettings: MessageSettings!
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    override func setUp() {
        monitor = MessageMonitor()
        noAnimationSettings = MessageSettings().setWidth(100).setHeight(100)
        topSettings = MessageSettings().setWidth(100).setHeight(20).setVerticalAlign(.top).setVerticalInset(5).setDisplayAnimation(.top).setDismissAnimation(.top)
        botSettings = MessageSettings().setWidth(100).setHeight(20).setVerticalAlign(.bottom).setVerticalInset(5).setDisplayAnimation(.bottom).setDismissAnimation(.bottom)
        rightSettings = MessageSettings().setWidth(80).setHeight(50).setHorizontalAlign(.right).setHorizontalInset(5).setDisplayAnimation(.right).setDismissAnimation(.right)
        leftSettings = MessageSettings().setWidth(80).setHeight(50).setHorizontalAlign(.left).setHorizontalInset(5).setDisplayAnimation(.left).setDismissAnimation(.left)
        centerSettings = MessageSettings().setWidth(50).setHeight(50).setHorizontalAlign(.center).setDisplayAnimation(.center).setDismissAnimation(.center)
    }
    
    func testNoAnimationFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: noAnimationSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, 0, accuracy: ACCURACY)
    }
    
    func testNoAnimationFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: noAnimationSettings)
        XCTAssertEqual(message.frameBeforeShow.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.size.height, screenHeight, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.y, 0, accuracy: ACCURACY)
    }
    
    func testNoAnimationFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: noAnimationSettings)
        XCTAssertEqual(message.frameAfterDismiss.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.size.height, screenHeight, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.y, 0, accuracy: ACCURACY)
    }
    
    func testTopSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, screenHeight * 0.05, accuracy: ACCURACY)
    }
    
    func testTopSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        XCTAssertEqual(message.frameBeforeShow.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.y, -(message.frameWhenVisible.size.height + message.frameWhenVisible.origin.y), accuracy: ACCURACY)
    }
    
    func testTopSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        XCTAssertEqual(message.frameAfterDismiss.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.y, -(message.frameWhenVisible.size.height + message.frameWhenVisible.origin.y), accuracy: ACCURACY)
    }
    
    func testTopSettingsNoVerticalInsetFrameWhenVisible() throws {
        topSettings.setVerticalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, 0, accuracy: ACCURACY)
    }
    
    func testBotSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, screenHeight - message.frameWhenVisible.size.height - (screenHeight * 0.05), accuracy: ACCURACY)
    }
    
    func testBotSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        XCTAssertEqual(message.frameBeforeShow.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.y, screenHeight, accuracy: ACCURACY)
    }
    
    func testBotSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        XCTAssertEqual(message.frameAfterDismiss.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.y, screenHeight, accuracy: ACCURACY)
    }
    
    func testBotSettingsNoVerticalInsetFrameWhenVisible() throws {
        botSettings.setVerticalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, screenHeight - message.frameWhenVisible.size.height, accuracy: ACCURACY)
    }
    
    func testRightSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, screenWidth - message.frameWhenVisible.size.width - (screenWidth * 0.05) , accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testRightSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        XCTAssertEqual(message.frameBeforeShow.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.x, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testRightSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        XCTAssertEqual(message.frameAfterDismiss.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.x, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testRightSettingsNoHorizontalInsetFrameWhenVisible() throws {
        rightSettings.setHorizontalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, screenWidth - message.frameWhenVisible.size.width, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testLeftSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, screenWidth * 0.05, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testLeftSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        XCTAssertEqual(message.frameBeforeShow.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.x, -(screenWidth + message.frameWhenVisible.origin.x), accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testLeftSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        XCTAssertEqual(message.frameAfterDismiss.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.x, -(screenWidth + message.frameWhenVisible.origin.x), accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testLeftSettingsNoHorizontalInsetFrameWhenVisible() throws {
        leftSettings.setHorizontalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testCenterSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: centerSettings)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, message.frameWhenVisible.size.width * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5, accuracy: ACCURACY)
    }
    
    func testCenterSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: centerSettings)
        XCTAssertEqual(message.frameBeforeShow.size.width, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.size.height, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.x, screenWidth * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.y, screenHeight * 0.5, accuracy: ACCURACY)
    }
    
    func testCenterSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: centerSettings)
        XCTAssertEqual(message.frameAfterDismiss.size.width, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.size.height, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.x, screenWidth * 0.5, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.y, screenHeight * 0.5, accuracy: ACCURACY)
    }
    
    func testNoMessageSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor)
        XCTAssertEqual(message.frameWhenVisible.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.size.height, screenHeight, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameWhenVisible.origin.y, 0, accuracy: ACCURACY)
    }
    
    func testNoMessageSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor)
        XCTAssertEqual(message.frameBeforeShow.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.size.height, screenHeight, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameBeforeShow.origin.y, 0, accuracy: ACCURACY)
    }
    
    func testNoMessageSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor)
        XCTAssertEqual(message.frameAfterDismiss.size.width, screenWidth, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.size.height, screenHeight, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.x, 0, accuracy: ACCURACY)
        XCTAssertEqual(message.frameAfterDismiss.origin.y, 0, accuracy: ACCURACY)
    }
}
