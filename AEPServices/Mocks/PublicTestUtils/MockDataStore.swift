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

import AEPServices

public class MockDataStore: NamedCollectionProcessing {
    public var dict = ThreadSafeDictionary<String, Any>()
    private var appGroup: String?

    public init() {}

    // MARK: AppGroup methods
    public func getAppGroup() -> String? {
        return appGroup
    }

    public func setAppGroup(_ appGroup: String?) {
        self.appGroup = appGroup
    }

    // MARK: DataStore dictionary methods
    public func set(collectionName _: String, key: String, value: Any?) {
        dict[key] = value
    }

    public func get(collectionName _: String, key: String) -> Any? {
        return dict[key] as Any?
    }

    public func remove(collectionName _: String, key: String) {
        _ = dict.removeValue(forKey: key)
    }
}
