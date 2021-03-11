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
@testable import AEPIdentity

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

    override func tearDown() {
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_TTL")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITOR_ID")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_BLOB")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_HINT")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_SYNCTIME")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_KEY_PUSH_TOKEN")
        v5Defaults.removeObject(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PUSH_ENABLED")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.InstallDate")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.OsVersion")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.Launches")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.SessionStart")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.PauseDate")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.LastVersion")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.UpgradeDate")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.LastDateUsed")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.AppId")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.LifecycleData")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.SuccessfulClose")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_Lifecycle.LaunchesAfterUpgrade")
        v5Defaults.removeObject(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")
    }

    /// Tests that on a fresh install that all values are nil and nothing is migrated
    func testFreshInstall() {
        // setup
        v5Defaults.set(nil, forKey: V4MigrationConstants.Lifecycle.V4_INSTALL_DATE)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        XCTAssertTrue(mockDataStore.dict.isEmpty) // no data to migrate, nothing should be put in the data store
    }

    /// Tests that when there is existing data from legacy v5 that we migrate that data
    func testExistingV5Data() {
        // setup
        let mockDate = Date()
        v5Defaults.set("identityECID", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID")
        v5Defaults.set("identityIds", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS")
        v5Defaults.set(1234, forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_TTL")
        v5Defaults.set("vid", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITOR_ID")
        v5Defaults.set("blob", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_BLOB")
        v5Defaults.set("hint", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_HINT")
        v5Defaults.set(1234, forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_SYNCTIME")
        v5Defaults.set("pushtoken", forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_KEY_PUSH_TOKEN")
        v5Defaults.set(true, forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PUSH_ENABLED")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.InstallDate")
        v5Defaults.set("os", forKey: "Adobe.AdobeMobile_Lifecycle.OsVersion")
        v5Defaults.set(552, forKey: "Adobe.AdobeMobile_Lifecycle.Launches")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.SessionStart")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.PauseDate")
        v5Defaults.set("version", forKey: "Adobe.AdobeMobile_Lifecycle.LastVersion")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.UpgradeDate")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.LastDateUsed")
        v5Defaults.set("appid", forKey: "Adobe.AdobeMobile_Lifecycle.AppId")
        v5Defaults.set(["lifecyclekey": "lifecycleval"], forKey: "Adobe.AdobeMobile_Lifecycle.LifecycleData")
        v5Defaults.set(true, forKey: "Adobe.AdobeMobile_Lifecycle.SuccessfulClose")
        v5Defaults.set(3, forKey: "Adobe.AdobeMobile_Lifecycle.LaunchesAfterUpgrade")
        v5Defaults.set("{\"global.privacy\": \"optedout\"}", forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")

        // test
        V5Migrator(idParser: MockIDParser()).migrate()

        // verify
        // legacy v5 defaults should have been removed
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_TTL"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITOR_ID"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_BLOB"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_HINT"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_SYNCTIME"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_KEY_PUSH_TOKEN"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PUSH_ENABLED"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.InstallDate"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.OsVersion"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.Launches"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.SessionStart"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.PauseDate"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LastVersion"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.UpgradeDate"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LastDateUsed"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.AppId"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LifecycleData"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.SuccessfulClose"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LaunchesAfterUpgrade"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map"))

        // data should have been migrated to v5 location
        let dataStore = NamedCollectionDataStore(name: "testable")
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        XCTAssertTrue(dataStore.getBool(key: V4MigrationConstants.Identity.DataStoreKeys.PUSH_ENABLED) ?? false)
        let installDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, fallback: nil)
        XCTAssertEqual(mockDate.timeIntervalSince1970, installDate?.timeIntervalSince1970)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT))
        XCTAssertEqual("version", dataStore.getString(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_VERSION))
        let lastUsedDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, fallback: nil)
        XCTAssertEqual(mockDate.timeIntervalSince1970, lastUsedDate?.timeIntervalSince1970)
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that when the app group is set that migration works as expected from legacy v5
    func testExistingV5DataInAppGroup() {
        // setup
        mockDataStore.setAppGroup("test-app-group")
        let mockDate = Date()
        v5Defaults.set("identityECID", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID")
        v5Defaults.set("identityIds", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS")
        v5Defaults.set(1234, forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_TTL")
        v5Defaults.set("vid", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITOR_ID")
        v5Defaults.set("blob", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_BLOB")
        v5Defaults.set("hint", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_HINT")
        v5Defaults.set(1234, forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_SYNCTIME")
        v5Defaults.set("pushtoken", forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_KEY_PUSH_TOKEN")
        v5Defaults.set(true, forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PUSH_ENABLED")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.InstallDate")
        v5Defaults.set("os", forKey: "Adobe.AdobeMobile_Lifecycle.OsVersion")
        v5Defaults.set(552, forKey: "Adobe.AdobeMobile_Lifecycle.Launches")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.SessionStart")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.PauseDate")
        v5Defaults.set("version", forKey: "Adobe.AdobeMobile_Lifecycle.LastVersion")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.UpgradeDate")
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.LastDateUsed")
        v5Defaults.set("appid", forKey: "Adobe.AdobeMobile_Lifecycle.AppId")
        v5Defaults.set(["lifecyclekey": "lifecycleval"], forKey: "Adobe.AdobeMobile_Lifecycle.LifecycleData")
        v5Defaults.set(true, forKey: "Adobe.AdobeMobile_Lifecycle.SuccessfulClose")
        v5Defaults.set(3, forKey: "Adobe.AdobeMobile_Lifecycle.LaunchesAfterUpgrade")
        v5Defaults.set("{\"global.privacy\": \"optedout\"}", forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")

        // test
        V5Migrator(idParser: MockIDParser()).migrate()

        // verify
        // legacy v5 defaults should have been removed
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_TTL"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITOR_ID"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_BLOB"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_HINT"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_SYNCTIME"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_KEY_PUSH_TOKEN"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PUSH_ENABLED"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.InstallDate"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.OsVersion"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.Launches"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.SessionStart"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.PauseDate"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LastVersion"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.UpgradeDate"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LastDateUsed"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.AppId"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LifecycleData"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.SuccessfulClose"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_Lifecycle.LaunchesAfterUpgrade"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map"))

        // data should have been migrated to v5 location
        let dataStore = NamedCollectionDataStore(name: "testable")
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        XCTAssertTrue(dataStore.getBool(key: V4MigrationConstants.Identity.DataStoreKeys.PUSH_ENABLED) ?? false)
        let installDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, fallback: nil)
        XCTAssertEqual(mockDate.timeIntervalSince1970, installDate?.timeIntervalSince1970)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT))
        XCTAssertEqual("version", dataStore.getString(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_VERSION))
        let lastUsedDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, fallback: nil)
        XCTAssertEqual(mockDate.timeIntervalSince1970, lastUsedDate?.timeIntervalSince1970)
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that legacy v5 configuration is migrated
    func testExistingV5ConfigurationData() {
        // setup
        v5Defaults.set("identityECID", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID")
        v5Defaults.set("identityIds", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS")
        v5Defaults.set("{\"global.privacy\": \"optedout\"}", forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")

        // test
        V5Migrator(idParser: MockIDParser()).migrate()

        // verify
        // legacy v5 defaults should have been removed
        XCTAssertNotNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID"))
        XCTAssertNotNil(v5Defaults.object(forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS"))
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map"))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that when we have existing v5 config with a privacy that we did not migrate the legacy v5 privacy and keep the existing config values
    func testExistingV5ConfigurationWhenV5ContainsOverriddenConfigWithPrivacyKey() {
        // setup
        v5Defaults.set("{\"global.privacy\": \"optedout\"}", forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")

        let existingConfig: [String: AnyCodable] = ["global.ssl": AnyCodable(true), "global.privacy": AnyCodable(PrivacyStatus.optedIn.rawValue)]
        let dataStore = NamedCollectionDataStore(name: "testable")
        dataStore.setObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: existingConfig)

        // test
        V5Migrator(idParser: MockIDParser()).migrate()

        // verify
        // legacy v5 defaults removed
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map"))

        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(2, storedConfig?.count)
        XCTAssertEqual("optedin", storedConfig?["global.privacy"]?.stringValue)
        XCTAssertTrue(storedConfig?["global.ssl"]?.boolValue ?? false)
    }

    /// Tests that the opted in privacy status is migrated
    func testExistingV5ConfigurationDataForOptIn() {
        // setup
        v5Defaults.set("{\"global.privacy\": \"optedin\"}", forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")

        // test
        V5Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v5 defaults removed
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map"))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optedin", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that the opted out privacy status is migrated
    func testExistingV5ConfigurationDataForOptOut() {
        // setup
        v5Defaults.set("{\"global.privacy\": \"optedout\"}", forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")

        // test
        V5Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v5 defaults removed
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map"))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that the opted unknown privacy status is migrated
    func testExistingV5ConfigurationDataForOptUnknown() {
        // setup
        v5Defaults.set("{\"global.privacy\": \"optunknown\"}", forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map")

        // test
        V5Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v5 defaults removed
        XCTAssertNil(v5Defaults.object(forKey: "Adobe.AdobeMobile_ConfigState.config.overridden.map"))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optunknown", storedConfig?["global.privacy"]?.stringValue)
    }

    func testExistingV5IdentityData() {
        let mockDate = Date()
        v5Defaults.set(mockDate.timeIntervalSince1970, forKey: "Adobe.AdobeMobile_Lifecycle.InstallDate")
        v5Defaults.set("identityECID", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID")
        v5Defaults.set("&d_cid_ic=type%01id%011", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_VISITORID_IDS")
        v5Defaults.set(1234, forKey: "Adobe.visitorIDServiceDataStore.ADBMOBILE_VISITORID_TTL")
        v5Defaults.set("blob", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_BLOB")
        v5Defaults.set("hint", forKey: "Adobe.visitorIDServiceDataStore.ADOBEMOBILE_PERSISTED_MID_HINT")

        // test
        V5Migrator(idParser: IDParser()).migrate()

        // verify
        var identityProperties = IdentityProperties()
        identityProperties.loadFromPersistence()

        XCTAssertEqual("identityECID", identityProperties.ecid?.ecidString)
        XCTAssertEqual(30, identityProperties.ttl)
        XCTAssertEqual("blob", identityProperties.blob)
        XCTAssertEqual("hint", identityProperties.locationHint)
        XCTAssertEqual(1, identityProperties.customerIds?.count)
        XCTAssertEqual("id", identityProperties.customerIds?[0].identifier)
        XCTAssertEqual("type", identityProperties.customerIds?[0].type)
        XCTAssertEqual("d_cid_ic", identityProperties.customerIds?[0].origin)
        XCTAssertEqual(1, identityProperties.customerIds?[0].authenticationState.rawValue)
    }

}
