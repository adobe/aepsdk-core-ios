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

@available(iOSApplicationExtension, unavailable)
class FullscreenMessage_FrameCalculationTests: XCTestCase {
    
    let ACCURACY: Float = 0.00001
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
    
    
    private func assertEqual(_ val1: CGFloat, _ val2: CGFloat) {
        XCTAssertTrue(fabsf(Float(val1 - val2)) <= ACCURACY)
    }
    
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
        assertEqual(message.frameWhenVisible.size.width, screenWidth)
        assertEqual(message.frameWhenVisible.size.height, screenHeight)
        assertEqual(message.frameWhenVisible.origin.x, 0)
        assertEqual(message.frameWhenVisible.origin.y, 0)
    }
    
    func testNoAnimationFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: noAnimationSettings)
        assertEqual(message.frameBeforeShow.size.width, screenWidth)
        assertEqual(message.frameBeforeShow.size.height, screenHeight)
        assertEqual(message.frameBeforeShow.origin.x, 0)
        assertEqual(message.frameBeforeShow.origin.y, 0)
    }
    
    func testNoAnimationFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: noAnimationSettings)
        assertEqual(message.frameAfterDismiss.size.width, screenWidth)
        assertEqual(message.frameAfterDismiss.size.height, screenHeight)
        assertEqual(message.frameAfterDismiss.origin.x, 0)
        assertEqual(message.frameAfterDismiss.origin.y, 0)
    }
    
    func testTopSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2)
        assertEqual(message.frameWhenVisible.origin.x, 0)
        assertEqual(message.frameWhenVisible.origin.y, screenHeight * 0.05)
    }
    
    func testTopSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        assertEqual(message.frameBeforeShow.size.width, screenWidth)
        assertEqual(message.frameBeforeShow.size.height, screenHeight * 0.2)
        assertEqual(message.frameBeforeShow.origin.x, 0)
        assertEqual(message.frameBeforeShow.origin.y, -(message.frameWhenVisible.size.height + message.frameWhenVisible.origin.y))
    }
    
    func testTopSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        assertEqual(message.frameAfterDismiss.size.width, screenWidth)
        assertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.2)
        assertEqual(message.frameAfterDismiss.origin.x, 0)
        assertEqual(message.frameAfterDismiss.origin.y, -(message.frameWhenVisible.size.height + message.frameWhenVisible.origin.y))
    }
    
    func testTopSettingsNoVerticalInsetFrameWhenVisible() throws {
        topSettings.setVerticalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: topSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2)
        assertEqual(message.frameWhenVisible.origin.x, 0)
        assertEqual(message.frameWhenVisible.origin.y, 0)
    }
    
    func testBotSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2)
        assertEqual(message.frameWhenVisible.origin.x, 0)
        assertEqual(message.frameWhenVisible.origin.y, screenHeight - message.frameWhenVisible.size.height - (screenHeight * 0.05))
    }
    
    func testBotSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        assertEqual(message.frameBeforeShow.size.width, screenWidth)
        assertEqual(message.frameBeforeShow.size.height, screenHeight * 0.2)
        assertEqual(message.frameBeforeShow.origin.x, 0)
        assertEqual(message.frameBeforeShow.origin.y, screenHeight)
    }
    
    func testBotSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        assertEqual(message.frameAfterDismiss.size.width, screenWidth)
        assertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.2)
        assertEqual(message.frameAfterDismiss.origin.x, 0)
        assertEqual(message.frameAfterDismiss.origin.y, screenHeight)
    }
    
    func testBotSettingsNoVerticalInsetFrameWhenVisible() throws {
        botSettings.setVerticalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: botSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.2)
        assertEqual(message.frameWhenVisible.origin.x, 0)
        assertEqual(message.frameWhenVisible.origin.y, screenHeight - message.frameWhenVisible.size.height)
    }
    
    func testRightSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5)
        assertEqual(message.frameWhenVisible.origin.x, screenWidth - message.frameWhenVisible.size.width - (screenWidth * 0.05) )
        assertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testRightSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        assertEqual(message.frameBeforeShow.size.width, screenWidth * 0.8)
        assertEqual(message.frameBeforeShow.size.height, screenHeight * 0.5)
        assertEqual(message.frameBeforeShow.origin.x, screenWidth)
        assertEqual(message.frameBeforeShow.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testRightSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        assertEqual(message.frameAfterDismiss.size.width, screenWidth * 0.8)
        assertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.5)
        assertEqual(message.frameAfterDismiss.origin.x, screenWidth)
        assertEqual(message.frameAfterDismiss.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testRightSettingsNoHorizontalInsetFrameWhenVisible() throws {
        rightSettings.setHorizontalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: rightSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5)
        assertEqual(message.frameWhenVisible.origin.x, screenWidth - message.frameWhenVisible.size.width)
        assertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testLeftSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5)
        assertEqual(message.frameWhenVisible.origin.x, screenWidth * 0.05)
        assertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testLeftSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        assertEqual(message.frameBeforeShow.size.width, screenWidth * 0.8)
        assertEqual(message.frameBeforeShow.size.height, screenHeight * 0.5)
        assertEqual(message.frameBeforeShow.origin.x, -(screenWidth + message.frameWhenVisible.origin.x))
        assertEqual(message.frameBeforeShow.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testLeftSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        assertEqual(message.frameAfterDismiss.size.width, screenWidth * 0.8)
        assertEqual(message.frameAfterDismiss.size.height, screenHeight * 0.5)
        assertEqual(message.frameAfterDismiss.origin.x, -(screenWidth + message.frameWhenVisible.origin.x))
        assertEqual(message.frameAfterDismiss.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testLeftSettingsNoHorizontalInsetFrameWhenVisible() throws {
        leftSettings.setHorizontalInset(nil)
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: leftSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth * 0.8)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5)
        assertEqual(message.frameWhenVisible.origin.x, 0)
        assertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testCenterSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: centerSettings)
        assertEqual(message.frameWhenVisible.size.width, screenWidth * 0.5)
        assertEqual(message.frameWhenVisible.size.height, screenHeight * 0.5)
        assertEqual(message.frameWhenVisible.origin.x, message.frameWhenVisible.size.width * 0.5)
        assertEqual(message.frameWhenVisible.origin.y, message.frameWhenVisible.size.height * 0.5)
    }
    
    func testCenterSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: centerSettings)
        assertEqual(message.frameBeforeShow.size.width, 0)
        assertEqual(message.frameBeforeShow.size.height, 0)
        assertEqual(message.frameBeforeShow.origin.x, screenWidth * 0.5)
        assertEqual(message.frameBeforeShow.origin.y, screenHeight * 0.5)
    }
    
    func testCenterSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor, settings: centerSettings)
        assertEqual(message.frameAfterDismiss.size.width, 0)
        assertEqual(message.frameAfterDismiss.size.height, 0)
        assertEqual(message.frameAfterDismiss.origin.x, screenWidth * 0.5)
        assertEqual(message.frameAfterDismiss.origin.y, screenHeight * 0.5)
    }
    
    func testNoMessageSettingsFrameWhenVisible() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor)
        assertEqual(message.frameWhenVisible.size.width, screenWidth)
        assertEqual(message.frameWhenVisible.size.height, screenHeight)
        assertEqual(message.frameWhenVisible.origin.x, 0)
        assertEqual(message.frameWhenVisible.origin.y, 0)
    }
    
    func testNoMessageSettingsFrameBeforeShow() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor)
        assertEqual(message.frameBeforeShow.size.width, screenWidth)
        assertEqual(message.frameBeforeShow.size.height, screenHeight)
        assertEqual(message.frameBeforeShow.origin.x, 0)
        assertEqual(message.frameBeforeShow.origin.y, 0)
    }
    
    func testNoMessageSettingsFrameAfterDismiss() throws {
        message = FullscreenMessage(payload: "", listener: nil, isLocalImageUsed: false, messageMonitor: monitor)
        assertEqual(message.frameAfterDismiss.size.width, screenWidth)
        assertEqual(message.frameAfterDismiss.size.height, screenHeight)
        assertEqual(message.frameAfterDismiss.origin.x, 0)
        assertEqual(message.frameAfterDismiss.origin.y, 0)
    }
}
