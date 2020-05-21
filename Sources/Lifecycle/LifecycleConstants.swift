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

/// Constants for `AEPLifecycle`
struct LifecycleConstants {
    static let START = "start"
    static let PAUSE = "pause"
    
    struct Keys {
        static let ACTION_KEY = "action"
        static let ADDITIONAL_CONTEXT_DATA = "additionalcontextdata"
        // LifecycleDataStore Keys
        static let INSTALL_DATE = "InstallDate"
        static let LAST_LAUNCH_DATE = "LastDateUsed"
        static let LAUNCHES = "Launches"
        static let UPGRADE_DATE = "UpgradeDate"
        static let LAUNCHES_SINCE_UPGRADE = "LaunchesAfterUpgrade"
    }
}
