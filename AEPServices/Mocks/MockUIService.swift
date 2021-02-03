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
import UIKit

public class MockUIService: UIService {
    
    var createFullscreenMessageCalled = false
    var fullscreenMessage: UIDisplayer?
    public func createFullscreenMessage(payload: String, listener: FullscreenMessageDelegate?, isLocalImageUsed: Bool?) -> UIDisplayer {
        createFullscreenMessageCalled = true
        return fullscreenMessage ?? FullscreenMessage(payload: payload, listener: listener)
    }
    
    var createFloatingButtonCalled = false
    var floatingButton: FloatingButton?
    public func createFloatingButton(listener: FloatingButtonDelegate) -> FloatingButton {
        createFloatingButtonCalled = true
        return floatingButton ?? createFloatingButton(listener: listener)
    }
    
    var createAlertMessageCalled = false
    var alertMessage: UIDisplayer?
    public func createAlertMessage(title: String, message: String, positiveButtonLabel: String?, negativeButtonLabel: String?, listener: AlertMessageDelegate?) -> UIDisplayer {
        createAlertMessageCalled = true
        return alertMessage ?? AlertMessage(title: title, message: message, positiveButtonLabel: positiveButtonLabel, negativeButtonLabel: negativeButtonLabel, listener: listener)
    }
    
    
}
