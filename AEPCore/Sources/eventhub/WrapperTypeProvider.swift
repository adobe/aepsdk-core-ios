/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

/// `WrapperTypeProvider` is responsible for managing the wrapper type in a thread-safe manner.
class WrapperTypeProvider {
    private var _wrapperType: WrapperType = .none
    private var isFrozen = false

    private let queue = DispatchQueue(label: "com.adobe.wrapperInfo.queue")

    /// The wrapper type for the SDK. This value can only be set once. After the first assignment, it becomes frozen and cannot be modified.
    var wrapperType: WrapperType {
        get {
            return queue.sync {
                return _wrapperType
            }
        }
        set {
            queue.sync {
                guard !isFrozen else {
                    return
                }
                _wrapperType = newValue
                isFrozen = true
            }
        }
    }
    
    /// Resets the wrapper type to its default value (`.none`) and allows it to be set again. This method is intended to be used only in tests to allow reinitialization.
    func reset() {
        queue.sync {
            _wrapperType = .none
            isFrozen = false
        }
    }
}
