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

@objc(AEPMessageSettings)
public class MessageSettings: NSObject {
    let parent: Any?
    private(set) var width: Int?
    private(set) var height: Int?
    private(set) var verticalAlign: MessageAlignment = .center
    private(set) var verticalInset: Int?
    private(set) var horizontalAlign: MessageAlignment = .center
    private(set) var horizontalInset: Int?
    private(set) var uiTakeover: Bool = true
    private(set) var animate: Bool = true
    private(set) var gestures: [MessageGesture: URL]?
    
    init(parent: Any? = nil) {
        self.parent = parent
    }
    
    func setWidth(_ width: Int?) -> MessageSettings {
        self.width = width
        return self
    }
    
    func setHeight(_ height: Int?) -> MessageSettings {
        self.height = height
        return self
    }
    
    func setVerticalAlign(_ vAlign: MessageAlignment) -> MessageSettings {
        self.verticalAlign = vAlign
        return self
    }
    
    func setHorizontalAlign(_ hAlign: MessageAlignment) -> MessageSettings {
        self.horizontalAlign = hAlign
        return self
    }
    
    func setVerticalInset(_ vInset: Int?) -> MessageSettings {
        self.verticalInset = vInset
        return self
    }
    
    func setHorizontalInset(_ hInset: Int?) -> MessageSettings {
        self.horizontalInset = hInset
        return self
    }
    
    func setUiTakeover(_ uiTakeover: Bool) -> MessageSettings {
        self.uiTakeover = uiTakeover
        return self
    }
    
    func setAnimate(_ animate: Bool) -> MessageSettings {
        self.animate = animate
        return self
    }
    
    func setGestures(_ gestures: [MessageGesture: URL]?) -> MessageSettings {
        self.gestures = gestures
        return self
    }
}
