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

/// An enum which describes different errors from the AEP SDK can return
@objc public enum AEPError: Int, Error {
    public typealias RawValue = Int

    case unexpected = 0
    case callbackTimeout = 1
    case callbackNil = 2
    case none = 3
    case serverError = 4
    case networkError = 5
    case invalidRequest = 6
    case invalidResponse = 7
    case errorExtensionNotInitialized = 11
}
