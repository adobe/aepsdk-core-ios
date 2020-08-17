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

class V4MigratorTests: XCTestCase {
    private var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }
    private var v4Defaults: UserDefaults {
        if let v4AppGroup = ServiceProvider.shared.namedKeyValueService.getAppGroup(), !v4AppGroup.isEmpty {
            return UserDefaults(suiteName: v4AppGroup) ?? UserDefaults.standard
        }

        return UserDefaults.standard
    }

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
    }

    /// Tests that on a fresh install that all values are nil and nothing is migrated
    func testFreshInstall() {
        // setup
        v4Defaults.set(nil, forKey: MigrationConstants.Lifecycle.V4InstallDate)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        XCTAssertTrue(mockDataStore.dict.isEmpty) // no data to migrate, nothing should be put in the data store
    }

    /// Tests that data from v4 is properly migrated
    func testExistingV4Data() {
        // setup
        let mockDate = Date()
        v4Defaults.set(["acqkey": "acqvalue"], forKey: MigrationConstants.MobileServices.V4AcquisitionData)
        v4Defaults.set("identityIds", forKey: MigrationConstants.Identity.V4Ids)
        v4Defaults.set("identityMid", forKey: MigrationConstants.Identity.V4MID)
        v4Defaults.set(1234, forKey: MigrationConstants.Identity.V4TTL)
        v4Defaults.set("vid", forKey: MigrationConstants.Identity.V4Vid)
        v4Defaults.set("blob", forKey: MigrationConstants.Identity.V4Blob)
        v4Defaults.set("hint", forKey: MigrationConstants.Identity.V4Hint)
        v4Defaults.set(1234, forKey: MigrationConstants.Identity.V4SyncTime)
        v4Defaults.set("pushtoken", forKey: MigrationConstants.Identity.V4PushToken)
        v4Defaults.set(true, forKey: MigrationConstants.Identity.V4PushEnabled)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4InstallDate)
        v4Defaults.set("os", forKey: MigrationConstants.Lifecycle.V4OS)
        v4Defaults.set(552, forKey: MigrationConstants.Lifecycle.V4Launches)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4StartDate)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4PauseDate)
        v4Defaults.set("version", forKey: MigrationConstants.Lifecycle.V4LastVersion)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4UpgradeDate)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4LastUsedDate)
        v4Defaults.set("appid", forKey: MigrationConstants.Lifecycle.V4ApplicationID)
        v4Defaults.set(["lifecyclekey": "lifecycleval"], forKey: MigrationConstants.Lifecycle.V4LifecycleData)
        v4Defaults.set(true, forKey: MigrationConstants.Lifecycle.V4SuccessfulClose)
        v4Defaults.set(3, forKey: MigrationConstants.Lifecycle.V4LaunchesAfterUpgrade)
        v4Defaults.set(["test": 1], forKey: MigrationConstants.MobileServices.V4InAppExcludeList)
        v4Defaults.set(2, forKey: MigrationConstants.Configuration.V4PrivacyStatus)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults should have been removed
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.MobileServices.V4AcquisitionData))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Ids))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4MID))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4TTL))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Vid))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Blob))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Hint))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4SyncTime))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4PushToken))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4PushEnabled))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4InstallDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4OS))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4Launches))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4StartDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4PauseDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LastVersion))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4UpgradeDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LastUsedDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4ApplicationID))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LifecycleData))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4SuccessfulClose))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LaunchesAfterUpgrade))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.MobileServices.V4InAppExcludeList))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        // data should have been migrated to v5 location
        let dataStore = NamedCollectionDataStore(name: "testable")
        let actualAcqData: [String: String]? = dataStore.getObject(key: MigrationConstants.MobileServices.V5AcquisitionData)
        XCTAssertEqual(["acqkey": "acqvalue"], actualAcqData)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: CoreConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        XCTAssertTrue(dataStore.getBool(key: CoreConstants.Identity.DataStoreKeys.PUSH_ENABLED) ?? false)
        let installDate: Date? = dataStore.getObject(key: CoreConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, fallback: nil)
        XCTAssertEqual(mockDate, installDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: CoreConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT))
        XCTAssertEqual("version", dataStore.getString(key: CoreConstants.Lifecycle.DataStoreKeys.LAST_VERSION))
        let lastUsedDate: Date? = dataStore.getObject(key: CoreConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, fallback: nil)
        XCTAssertEqual(mockDate, lastUsedDate)
        let msInstallDate: Date? = dataStore.getObject(key: MigrationConstants.MobileServices.install, fallback: nil)
        XCTAssertEqual(mockDate, msInstallDate)
        let msSeachAdInstallDate: Date? = dataStore.getObject(key: MigrationConstants.MobileServices.installSearchAd, fallback: nil)
        XCTAssertEqual(mockDate, msSeachAdInstallDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: MigrationConstants.MobileServices.V5InAppExcludeList))
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that data is migrated correctly when using an app group
    func testExistingV4DataInAppGroup() {
        // setup
        mockDataStore.setAppGroup("test-app-group")
        let mockDate = Date()
        v4Defaults.set(["acqkey": "acqvalue"], forKey: MigrationConstants.MobileServices.V4AcquisitionData)
        v4Defaults.set("identityIds", forKey: MigrationConstants.Identity.V4Ids)
        v4Defaults.set("identityMid", forKey: MigrationConstants.Identity.V4MID)
        v4Defaults.set(1234, forKey: MigrationConstants.Identity.V4TTL)
        v4Defaults.set("vid", forKey: MigrationConstants.Identity.V4Vid)
        v4Defaults.set("blob", forKey: MigrationConstants.Identity.V4Blob)
        v4Defaults.set("hint", forKey: MigrationConstants.Identity.V4Hint)
        v4Defaults.set(1234, forKey: MigrationConstants.Identity.V4SyncTime)
        v4Defaults.set("pushtoken", forKey: MigrationConstants.Identity.V4PushToken)
        v4Defaults.set(true, forKey: MigrationConstants.Identity.V4PushEnabled)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4InstallDate)
        v4Defaults.set("os", forKey: MigrationConstants.Lifecycle.V4OS)
        v4Defaults.set(552, forKey: MigrationConstants.Lifecycle.V4Launches)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4StartDate)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4PauseDate)
        v4Defaults.set("version", forKey: MigrationConstants.Lifecycle.V4LastVersion)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4UpgradeDate)
        v4Defaults.set(mockDate, forKey: MigrationConstants.Lifecycle.V4LastUsedDate)
        v4Defaults.set("appid", forKey: MigrationConstants.Lifecycle.V4ApplicationID)
        v4Defaults.set(["lifecyclekey": "lifecycleval"], forKey: MigrationConstants.Lifecycle.V4LifecycleData)
        v4Defaults.set(true, forKey: MigrationConstants.Lifecycle.V4SuccessfulClose)
        v4Defaults.set(3, forKey: MigrationConstants.Lifecycle.V4LaunchesAfterUpgrade)
        v4Defaults.set(["test": 1], forKey: MigrationConstants.MobileServices.V4InAppExcludeList)
        v4Defaults.set(2, forKey: MigrationConstants.Configuration.V4PrivacyStatus)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults should have been removed
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.MobileServices.V4AcquisitionData))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Ids))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4MID))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4TTL))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Vid))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Blob))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Hint))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4SyncTime))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4PushToken))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4PushEnabled))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4InstallDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4OS))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4Launches))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4StartDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4PauseDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LastVersion))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4UpgradeDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LastUsedDate))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4ApplicationID))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LifecycleData))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4SuccessfulClose))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Lifecycle.V4LaunchesAfterUpgrade))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.MobileServices.V4InAppExcludeList))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        // data should have been migrated to v5 location
        let dataStore = NamedCollectionDataStore(name: "testable")
        let actualAcqData: [String: String]? = dataStore.getObject(key: MigrationConstants.MobileServices.V5AcquisitionData)
        XCTAssertEqual(["acqkey": "acqvalue"], actualAcqData)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: CoreConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        XCTAssertTrue(dataStore.getBool(key: CoreConstants.Identity.DataStoreKeys.PUSH_ENABLED) ?? false)
        let installDate: Date? = dataStore.getObject(key: CoreConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, fallback: nil)
        XCTAssertEqual(mockDate, installDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: CoreConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT))
        XCTAssertEqual("version", dataStore.getString(key: CoreConstants.Lifecycle.DataStoreKeys.LAST_VERSION))
        let lastUsedDate: Date? = dataStore.getObject(key: CoreConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, fallback: nil)
        XCTAssertEqual(mockDate, lastUsedDate)
        let msInstallDate: Date? = dataStore.getObject(key: MigrationConstants.MobileServices.install, fallback: nil)
        XCTAssertEqual(mockDate, msInstallDate)
        let msSeachAdInstallDate: Date? = dataStore.getObject(key: MigrationConstants.MobileServices.installSearchAd, fallback: nil)
        XCTAssertEqual(mockDate, msSeachAdInstallDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: MigrationConstants.MobileServices.V5InAppExcludeList))
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that existing v4 config is migrated
    func testExistingV4ConfigurationData() {
        // setup
        v4Defaults.set("identityIds", forKey: MigrationConstants.Identity.V4Ids)
        v4Defaults.set("identityMid", forKey: MigrationConstants.Identity.V4MID)
        v4Defaults.set(2, forKey: MigrationConstants.Configuration.V4PrivacyStatus)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults should have been removed
        XCTAssertNotNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4Ids))
        XCTAssertNotNil(v4Defaults.object(forKey: MigrationConstants.Identity.V4MID))
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        // only v5 configuration defaults have been set
        XCTAssertNil(mockDataStore.get(collectionName: "", key: CoreConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that when we have existing v5 config without a privacy that we migrated the v4 privacy and keep the existing config values
    func testExistingV4ConfigurationWhenV5ContainsOverriddenConfigWithoutPrivacyKey() {
        // setup
        v4Defaults.set(2, forKey: MigrationConstants.Configuration.V4PrivacyStatus)

        let existingConfig: [String: AnyCodable] = ["global.ssl": AnyCodable(true)]
        let dataStore = NamedCollectionDataStore(name: "testable")
        dataStore.setObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG, value: existingConfig)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(2, storedConfig?.count)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
        XCTAssertTrue(storedConfig?["global.ssl"]?.boolValue ?? false)
    }

    /// Tests that when we have existing v5 config with a privacy that we did not migrate the v4 privacy and keep the existing config values
    func testExistingV4ConfigurationWhenV5ContainsOverriddenConfigWithPrivacyKey() {
        // setup
        v4Defaults.set(2, forKey: MigrationConstants.Configuration.V4PrivacyStatus)

        let existingConfig: [String: AnyCodable] = ["global.ssl": AnyCodable(true), "global.privacy": AnyCodable(PrivacyStatus.optedIn.rawValue)]
        let dataStore = NamedCollectionDataStore(name: "testable")
        dataStore.setObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG, value: existingConfig)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(2, storedConfig?.count)
        XCTAssertEqual("optedin", storedConfig?["global.privacy"]?.stringValue)
        XCTAssertTrue(storedConfig?["global.ssl"]?.boolValue ?? false)
    }

    /// Tests that the opted in privacy status is migrated
    func testExistingV4ConfigurationDataForOptIn() {
        // setup
        v4Defaults.set(1, forKey: MigrationConstants.Configuration.V4PrivacyStatus) // v4 opted in value

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optedin", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that the opted out privacy status is migrated
    func testExistingV4ConfigurationDataForOptOut() {
        // setup
        v4Defaults.set(2, forKey: MigrationConstants.Configuration.V4PrivacyStatus) // v4 opted out value

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that the unknown privacy status is migrated
    func testExistingV4ConfigurationDataForUnknown() {
        // setup
        v4Defaults.set(3, forKey: MigrationConstants.Configuration.V4PrivacyStatus) // v4 opted out value

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: MigrationConstants.Configuration.V4PrivacyStatus))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optunknown", storedConfig?["global.privacy"]?.stringValue)
    }


}
