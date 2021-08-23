/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Constants for `LifecycleV2`
enum LifecycleV2Constants {
    static let EXTENSION_NAME = "com.adobe.module.lifecycle"
    static let LOG_TAG = "Lifecycle"

    static let STATE_UPDATE_TIMEOUT_SEC = TimeInterval(2)

    static let CACHE_TIMEOUT_SECONDS = TimeInterval(2)

    enum EventType {
        static let APP_LAUNCH = "application.launch"
        static let APP_CLOSE = "application.close"
    }

    /// The values in this section need to be prefixed with v2 to avoid any conflicts with the dataStore keys from standard `Lifecycle` extension
    enum DataStoreKeys {
        static let LAST_APP_VERSION = "v2.last.app.version"
        static let APP_START_DATE = "v2.app.start.date"
        static let APP_PAUSE_DATE = "v2.app.pause.date"
        static let APP_CLOSE_DATE = "v2.app.close.date"
    }
}