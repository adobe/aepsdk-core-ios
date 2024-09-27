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

/// Defines the public interface for the Tracking methods
@objc
public extension MobileCore {
    /// Generates and dispatches a track action `Event`
    /// - Parameters:
    ///   - action: `String` representing the name of the action to be tracked
    ///   - data: Dictionary of data to attach to the dispatched `Event`
    @objc(trackAction:data:)
    static func track(action: String?, data: [String: Any]?) {
        apiDefaultInstance.track(action: action, data: data)        
    }

    /// Generates and dispatches a track state `Event`
    /// - Parameters:
    ///   - state: `String` representing the name of the state to be tracked
    ///   - data: Dictionary of data to attach to the dispatched `Event`
    @objc(trackState:data:)
    static func track(state: String?, data: [String: Any]?) {
        apiDefaultInstance.track(state: state, data: data)
    }
}
