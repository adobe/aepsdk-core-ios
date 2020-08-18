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

import XCTest
@testable import AEPCore
import AEPServicesMocks
import AEPServices

private struct MockIDParser: IDParsing {
    func convertStringToIds(idString: String?) -> [[String : Any]] {
        return []
    }
}

class V5MigratorTests: XCTestCase {
    private var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }
    private var v5Defaults: UserDefaults {
        if let v5AppGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup(), !v5AppGroup.isEmpty {
            return UserDefaults(suiteName: v5AppGroup) ?? UserDefaults.standard
        }

        return UserDefaults.standard
    }

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
    }

    /// Tests that on a fresh install that all values are nil and nothing is migrated
    func testFreshInstall() {
        // setup
        v5Defaults.set(nil, forKey: V4MigrationConstants.Lifecycle.V4InstallDate)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        XCTAssertTrue(mockDataStore.dict.isEmpty) // no data to migrate, nothing should be put in the data store
    }


}
