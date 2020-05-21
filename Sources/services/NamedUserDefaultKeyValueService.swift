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

class NamedUserDefaultKeyValueService: NamedKeyValueService {
    
    let keyPrefix = "com.adobe.mobile.datastore"
    
    func set(collectionName: String, key: String, value: Any?) {
        userDefaultsFor(name: collectionName).set(value, forKey: keyPrefix + key)
    }
    
    func get(collectionName: String, key: String) -> Any? {
        guard let value = userDefaultsFor(name: collectionName).object(forKey: keyPrefix + key) else {
            return nil
        }
        return value
    }
    
    func remove(collectionName: String, key: String) {
        userDefaultsFor(name: collectionName).removeObject(forKey: keyPrefix + key)
    }
    
    func removeAll(collectionName: String) {
        for item in userDefaultsFor(name: collectionName).dictionaryRepresentation() {
            userDefaultsFor(name: collectionName).removeObject(forKey: item.key)
        }
    }
    
    private func userDefaultsFor(name: String) -> UserDefaults {
        return UserDefaults(suiteName: "\(keyPrefix).\(name)") ?? UserDefaults.standard
    }
}
