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

class UserDefaultsNamedCollection: NamedCollectionProcessing {
    let keyPrefix = "com.adobe.mobile.datastore"
    var appGroup: String?

    func setAppGroup(_ appGroup: String?) {
        self.appGroup = appGroup
    }

    func getAppGroup() -> String? {
        return appGroup
    }

    func set(collectionName: String, key: String, value: Any?) {
        userDefault.set(value, forKey: keyNameFor(collectionName: collectionName, key: key))
    }

    func get(collectionName: String, key: String) -> Any? {
        guard let value = userDefault.object(forKey: keyNameFor(collectionName: collectionName, key: key)) else {
            return nil
        }
        return value
    }

    func remove(collectionName: String, key: String) {
        userDefault.removeObject(forKey: keyNameFor(collectionName: collectionName, key: key))
    }

    var userDefault: UserDefaults {
        if let appGroup = self.appGroup {
            return UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
        }
        return UserDefaults.standard
    }

    private func keyNameFor(collectionName: String, key: String) -> String {
        return "Adobe.\(collectionName).\(key)"
    }
}
