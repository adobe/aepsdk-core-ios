//
// Copyright 2024 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices

public extension NamedCollectionDataStore {
    /// Clears all known locations for Adobe Mobile SDK local device data persistence:
    /// 1. `UserDefaults` - tvOS (in use for all versions) and iOS (in use for Core version lower than v4.2.0) (see: ``UserDefaults/clearAll()``)
    /// 2. `FileManager` - hits databases for each extension (see: ``FileManager/clearCache``)
    /// 3. File system directory - iOS (in use for Core version v4.2.0 and beyond)
    static func clear() {
        UserDefaults.clearAll()
        FileManager.default.clearCache()
        FileManager.default.clearDirectory()
    }
}
