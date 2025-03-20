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
import UIKit
#if os(iOS)
import WebKit
#endif

@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
class AEPUIService: UIService {
    private var messageMonitor = MessageMonitor()
#if os(iOS)
    func createFullscreenMessage(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool = false) -> FullscreenPresentable {
        return createFullscreenMessage(payload: payload, listener: listener, isLocalImageUsed: isLocalImageUsed, settings: nil)
    }

    func createFullscreenMessage(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool = false, settings: MessageSettings? = nil) -> FullscreenPresentable {
        return FullscreenMessage(payload: payload, listener: listener, isLocalImageUsed: isLocalImageUsed, messageMonitor: messageMonitor, settings: settings)
    }
    #endif

    func createFloatingButton(listener: FloatingButtonDelegate) -> FloatingButtonPresentable {
        return FloatingButton(listener: listener)
    }
}

