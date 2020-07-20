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
@testable import AEPEventHub
import AEPServices

class MockDataStore: NamedKeyValueService {
    private var dict = [String: Any?]()
    
    func set(collectionName: String, key: String, value: Any?) {
        dict[key] = value
    }
    
    func get(collectionName: String, key: String) -> Any? {
        return dict[key] as Any?
    }
    
    func remove(collectionName: String, key: String) {
        dict.removeValue(forKey: key)
    }
    
    func removeAll(collectionName: String) {
        dict.removeAll()
    }
}
