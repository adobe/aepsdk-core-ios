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
#if os(iOS)
    import Foundation
    @testable import AEPServices
    import UIKit

    @available(iOSApplicationExtension, unavailable)
    public class MockUIService: UIService {
    
        public init() {}
    
        var mockMessageMonitor: MessageMonitoring?
    
        var createFullscreenMessageCalled = false
        var fullscreenMessage: FullscreenPresentable?
        public func createFullscreenMessage(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool) -> FullscreenPresentable {
            createFullscreenMessageCalled = true
            return fullscreenMessage ?? FullscreenMessage(payload: payload, listener: listener, isLocalImageUsed: isLocalImageUsed, messageMonitor: mockMessageMonitor ?? MessageMonitor())
        }
    
        var createFloatingButtonCalled = false
        var floatingButton: FloatingButtonPresentable?
        public func createFloatingButton(listener: FloatingButtonDelegate) -> FloatingButtonPresentable {
            createFloatingButtonCalled = true
            return floatingButton ?? createFloatingButton(listener: listener)
        }   
    
    }
#endif
