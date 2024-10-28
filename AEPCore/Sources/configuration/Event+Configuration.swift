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

/// Adds convenience properties to an `Event` for the Configuration extension
extension Event {
    /// Returns true if this `Event` is an update configuration event, otherwise false
    var isUpdateConfigEvent: Bool {
        return data?[ConfigurationConstants.Keys.UPDATE_CONFIG] != nil
    }

    /// Returns true if this `Event` is a get configuration event, otherwise false
    var isGetConfigEvent: Bool {
        return data?[ConfigurationConstants.Keys.RETRIEVE_CONFIG] as? Bool ?? false
    }

    /// Returns true if this `Event` is a clear configuration event, otherwise false
    var isClearConfigEvent: Bool {
        return data?[ConfigurationConstants.Keys.CLEAR_UPDATED_CONFIG] as? Bool ?? false
    }

    /// Returns true if this `Event` is an internal configure with appId event, otherwise false
    var isInternalConfigEvent: Bool {
        return data?[ConfigurationConstants.Keys.IS_INTERNAL_EVENT] as? Bool ?? false
    }

    /// Returns the appId stored in `data` if found, otherwise nil
    var appId: String? {
        return data?[ConfigurationConstants.Keys.JSON_APP_ID] as? String
    }

    /// Returns the file path stored in `data` if found, otherwise nil
    var filePath: String? {
        return data?[ConfigurationConstants.Keys.JSON_FILE_PATH] as? String
    }
}
