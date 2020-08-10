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

@testable import AEPCore
import AEPServices
import AEPServicesMocks
import XCTest

class LaunchIDManagerTests: XCTestCase {
    let dataStore = NamedCollectionDataStore(name: "AppIDManagerTests")
    var appIdManager: LaunchIDManager!

    override func setUp() {
        ServiceProvider.shared.systemInfoService = MockSystemInfoService()
        appIdManager = LaunchIDManager(dataStore: dataStore)
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// When no appId is stored in persistence we should return nil when loading the appId
    func testLoadAppIdWhenEmpty() {
        XCTAssertNil(appIdManager.loadAppId())
    }

    /// Round trip of saving appId and loading appId works as expected
    func testLoadAppIdWhenSavedToPersistence() {
        // setup
        let appId = "test-app-id"
        appIdManager.saveAppIdToPersistence(appId: appId)

        // test & verify
        XCTAssertEqual(appId, appIdManager.loadAppId())
    }

    /// When an appId is saved to the manifest we can load it properly
    func testLoadAppIdWhenSavedToManifest() {
        // setup
        if let mockSystemInfoService = ServiceProvider.shared.systemInfoService as? MockSystemInfoService {
            mockSystemInfoService.property = "test-app-id"
        }

        // test & verify
        XCTAssertEqual(ServiceProvider.shared.systemInfoService.getProperty(for: ""), appIdManager.loadAppId())
    }

    /// Loading from persistence returns nil when no appId is saved
    func testLoadAppIdFromPersistenceEmpty() {
        XCTAssertNil(appIdManager.loadAppIdFromPersistence())
    }

    /// AppId is returned when saved to persistence
    func loadAppIdFromPersistenceSimple() {
        // setup
        let appId = "test-app-id"
        appIdManager.saveAppIdToPersistence(appId: appId)

        // test & verify
        XCTAssertEqual(appId, appIdManager.loadAppIdFromPersistence())
    }

    /// When the manifest does not contain an appId we should return nil when loading from the manifest
    func testLoadAppIdFromManifestEmpty() {
        XCTAssertNil(appIdManager.loadAppIdFromManifest())
    }

    /// When an appId is present in the manifest we should successfully load that appId
    func loadAppIdFromManifestSimple() {
        // setup
        if let mockSystemInfoService = ServiceProvider.shared.systemInfoService as? MockSystemInfoService {
            mockSystemInfoService.property = "test-app-id"
        }

        // test & verify
        XCTAssertEqual(ServiceProvider.shared.systemInfoService.getProperty(for: ""), appIdManager.loadAppIdFromManifest())
    }
}
