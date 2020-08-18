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

/// Constants for V5 -> V5 migration
enum V5MigrationConstants {
    enum Configuration {
        static let DATASTORE_NAME = "AdobeMobile_ConfigState"
        static let OVERRIDDEN_CONFIG = "config.overridden.map"
    }

    enum Identity {
        static let DATASTORE_NAME = "visitorIDServiceDataStore"
    }

    enum Lifecycle {
        static let DATASTORE_NAME = "AdobeMobile_Lifecycle"
        static let INSTALL_DATE = "InstallDate"
    }

    enum MobileServices {
        static let DATASTORE_NAME = "MobileServices"
        static let AcquisitionData = "Adobe.MobileServices.acquisition_json"
        static let Install = "Adobe.MobileServices.install"
        static let InstallSearchAd = "Adobe.MobileServices.install.searchad"
        static let ExcludeList = "Adobe.MobileServices.blacklist"
    }
}
