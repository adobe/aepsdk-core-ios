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

/// Contains the status and value for a given shared state
@objc(AEPSharedStateResult)
public class SharedStateResult: NSObject {
    @objc public let status: SharedStateStatus
    @objc public let value: [String: Any]?

    /// Creates a new shared state result with given status and value
    /// - Parameters:
    ///   - status: status of the shared state
    ///   - value: value of the shared state
    init(status: SharedStateStatus, value: [String: Any]?) {
        self.status = status
        self.value = value
    }
}
