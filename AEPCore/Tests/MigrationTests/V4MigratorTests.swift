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
        v4Defaults.set(nil, forKey: V4MigrationConstants.Lifecycle.V4_INSTALL_DATE)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        XCTAssertTrue(mockDataStore.dict.isEmpty) // no data to migrate, nothing should be put in the data store
    }

    /// Tests that data from v4 is properly migrated
    func testExistingV4Data() {
        // setup
        let mockDate = NSDate()
        v4Defaults.set(["acqkey": "acqvalue"], forKey: V4MigrationConstants.MobileServices.V4_ACQUISITION_DATA)
        v4Defaults.set("identityIds", forKey: V4MigrationConstants.Identity.V4_IDS)
        v4Defaults.set("identityECID", forKey: V4MigrationConstants.Identity.V4_ECID)
        v4Defaults.set(1234, forKey: V4MigrationConstants.Identity.V4_TTL)
        v4Defaults.set("vid", forKey: V4MigrationConstants.Identity.V4_VID)
        v4Defaults.set("blob", forKey: V4MigrationConstants.Identity.V4_BLOB)
        v4Defaults.set("hint", forKey: V4MigrationConstants.Identity.V4_HINT)
        v4Defaults.set(1234, forKey: V4MigrationConstants.Identity.V4_SYNC_TIME)
        v4Defaults.set("pushtoken", forKey: V4MigrationConstants.Identity.V4_PUSH_TOKEN)
        v4Defaults.set(true, forKey: V4MigrationConstants.Identity.V4_PUSH_ENABLED)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_INSTALL_DATE)
        v4Defaults.set("os", forKey: V4MigrationConstants.Lifecycle.V4_OS)
        v4Defaults.set(552, forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_START_DATE)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_PAUSE_DATE)
        v4Defaults.set("version", forKey: V4MigrationConstants.Lifecycle.V4_LAST_VERSION)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_UPGRADE_DATE)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_LAST_USED_DATE)
        v4Defaults.set("appid", forKey: V4MigrationConstants.Lifecycle.V4_APPLICATION_ID)
        v4Defaults.set(["lifecyclekey": "lifecycleval"], forKey: V4MigrationConstants.Lifecycle.V4_LIFECYCLE_DATA)
        v4Defaults.set(true, forKey: V4MigrationConstants.Lifecycle.V4_SUCCESSFUL_CLOSE)
        v4Defaults.set(3, forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES_AFTER_UPGRADE)
        v4Defaults.set(["test": 1], forKey: V4MigrationConstants.MobileServices.V4_IN_APP_EXCLUDE_LIST)
        v4Defaults.set(2, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults should have been removed
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.MobileServices.V4_ACQUISITION_DATA))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_IDS))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_ECID))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_TTL))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_VID))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_BLOB))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_HINT))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_SYNC_TIME))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_PUSH_TOKEN))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_PUSH_ENABLED))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_INSTALL_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_OS))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_START_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_PAUSE_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAST_VERSION))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_UPGRADE_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAST_USED_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_APPLICATION_ID))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LIFECYCLE_DATA))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_SUCCESSFUL_CLOSE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES_AFTER_UPGRADE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.MobileServices.V4_IN_APP_EXCLUDE_LIST))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        // data should have been migrated to v5 location
        let dataStore = NamedCollectionDataStore(name: "testable")
        let actualAcqData: [String: String]? = dataStore.getObject(key: V4MigrationConstants.MobileServices.V5_ACQUISITION_DATA)
        XCTAssertEqual(["acqkey": "acqvalue"], actualAcqData)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        XCTAssertTrue(dataStore.getBool(key: V4MigrationConstants.Identity.DataStoreKeys.PUSH_ENABLED) ?? false)
        let installDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, fallback: nil)
        XCTAssertEqual(mockDate as Date?, installDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT))
        XCTAssertEqual("version", dataStore.getString(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_VERSION))
        let lastUsedDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, fallback: nil)
        XCTAssertEqual(mockDate as Date?, lastUsedDate)
        let msInstallDate: Date? = dataStore.getObject(key: V4MigrationConstants.MobileServices.INSTALL, fallback: nil)
        XCTAssertEqual(mockDate as Date?, msInstallDate)
        let msSeachAdInstallDate: Date? = dataStore.getObject(key: V4MigrationConstants.MobileServices.INSTALL_SEARCH_AD, fallback: nil)
        XCTAssertEqual(mockDate as Date?, msSeachAdInstallDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.MobileServices.V5_IN_APP_EXCLUDE_LIST))
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that data is migrated correctly when using an app group
    func testExistingV4DataInAppGroup() {
        // setup
        mockDataStore.setAppGroup("test-app-group")
        let mockDate = Date()
        v4Defaults.set(["acqkey": "acqvalue"], forKey: V4MigrationConstants.MobileServices.V4_ACQUISITION_DATA)
        v4Defaults.set("identityIds", forKey: V4MigrationConstants.Identity.V4_IDS)
        v4Defaults.set("identityECID", forKey: V4MigrationConstants.Identity.V4_ECID)
        v4Defaults.set(1234, forKey: V4MigrationConstants.Identity.V4_TTL)
        v4Defaults.set("vid", forKey: V4MigrationConstants.Identity.V4_VID)
        v4Defaults.set("blob", forKey: V4MigrationConstants.Identity.V4_BLOB)
        v4Defaults.set("hint", forKey: V4MigrationConstants.Identity.V4_HINT)
        v4Defaults.set(1234, forKey: V4MigrationConstants.Identity.V4_SYNC_TIME)
        v4Defaults.set("pushtoken", forKey: V4MigrationConstants.Identity.V4_PUSH_TOKEN)
        v4Defaults.set(true, forKey: V4MigrationConstants.Identity.V4_PUSH_ENABLED)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_INSTALL_DATE)
        v4Defaults.set("os", forKey: V4MigrationConstants.Lifecycle.V4_OS)
        v4Defaults.set(552, forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_START_DATE)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_PAUSE_DATE)
        v4Defaults.set("version", forKey: V4MigrationConstants.Lifecycle.V4_LAST_VERSION)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_UPGRADE_DATE)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_LAST_USED_DATE)
        v4Defaults.set("appid", forKey: V4MigrationConstants.Lifecycle.V4_APPLICATION_ID)
        v4Defaults.set(["lifecyclekey": "lifecycleval"], forKey: V4MigrationConstants.Lifecycle.V4_LIFECYCLE_DATA)
        v4Defaults.set(true, forKey: V4MigrationConstants.Lifecycle.V4_SUCCESSFUL_CLOSE)
        v4Defaults.set(3, forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES_AFTER_UPGRADE)
        v4Defaults.set(["test": 1], forKey: V4MigrationConstants.MobileServices.V4_IN_APP_EXCLUDE_LIST)
        v4Defaults.set(2, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults should have been removed
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.MobileServices.V4_ACQUISITION_DATA))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_IDS))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_ECID))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_TTL))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_VID))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_BLOB))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_HINT))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_SYNC_TIME))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_PUSH_TOKEN))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_PUSH_ENABLED))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_INSTALL_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_OS))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_START_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_PAUSE_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAST_VERSION))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_UPGRADE_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAST_USED_DATE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_APPLICATION_ID))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LIFECYCLE_DATA))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_SUCCESSFUL_CLOSE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Lifecycle.V4_LAUNCHES_AFTER_UPGRADE))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.MobileServices.V4_IN_APP_EXCLUDE_LIST))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        // data should have been migrated to v5 location
        let dataStore = NamedCollectionDataStore(name: "testable")
        let actualAcqData: [String: String]? = dataStore.getObject(key: V4MigrationConstants.MobileServices.V5_ACQUISITION_DATA)
        XCTAssertEqual(["acqkey": "acqvalue"], actualAcqData)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        XCTAssertTrue(dataStore.getBool(key: V4MigrationConstants.Identity.DataStoreKeys.PUSH_ENABLED) ?? false)
        let installDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.INSTALL_DATE, fallback: nil)
        XCTAssertEqual(mockDate, installDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Lifecycle.DataStoreKeys.PERSISTED_CONTEXT))
        XCTAssertEqual("version", dataStore.getString(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_VERSION))
        let lastUsedDate: Date? = dataStore.getObject(key: V4MigrationConstants.Lifecycle.DataStoreKeys.LAST_LAUNCH_DATE, fallback: nil)
        XCTAssertEqual(mockDate, lastUsedDate)
        let msInstallDate: Date? = dataStore.getObject(key: V4MigrationConstants.MobileServices.INSTALL, fallback: nil)
        XCTAssertEqual(mockDate, msInstallDate)
        let msSeachAdInstallDate: Date? = dataStore.getObject(key: V4MigrationConstants.MobileServices.INSTALL_SEARCH_AD, fallback: nil)
        XCTAssertEqual(mockDate, msSeachAdInstallDate)
        XCTAssertNotNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.MobileServices.V5_IN_APP_EXCLUDE_LIST))
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that existing v4 config is migrated
    func testExistingV4ConfigurationData() {
        // setup
        v4Defaults.set("identityIds", forKey: V4MigrationConstants.Identity.V4_IDS)
        v4Defaults.set("identityECID", forKey: V4MigrationConstants.Identity.V4_ECID)
        v4Defaults.set(2, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults should have been removed
        XCTAssertNotNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_IDS))
        XCTAssertNotNil(v4Defaults.object(forKey: V4MigrationConstants.Identity.V4_ECID))
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        // only v5 configuration defaults have been set
        XCTAssertNil(mockDataStore.get(collectionName: "", key: V4MigrationConstants.Identity.DataStoreKeys.IDENTITY_PROPERTIES))
        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that when we have existing v5 config without a privacy that we migrated the v4 privacy and keep the existing config values
    func testExistingV4ConfigurationWhenV5ContainsOverriddenConfigWithoutPrivacyKey() {
        // setup
        v4Defaults.set(2, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS)

        let existingConfig: [String: AnyCodable] = ["global.ssl": AnyCodable(true)]
        let dataStore = NamedCollectionDataStore(name: "testable")
        dataStore.setObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: existingConfig)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(2, storedConfig?.count)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
        XCTAssertTrue(storedConfig?["global.ssl"]?.boolValue ?? false)
    }

    /// Tests that when we have existing v5 config with a privacy that we did not migrate the v4 privacy and keep the existing config values
    func testExistingV4ConfigurationWhenV5ContainsOverriddenConfigWithPrivacyKey() {
        // setup
        v4Defaults.set(2, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS)

        let existingConfig: [String: AnyCodable] = ["global.ssl": AnyCodable(true), "global.privacy": AnyCodable(PrivacyStatus.optedIn.rawValue)]
        let dataStore = NamedCollectionDataStore(name: "testable")
        dataStore.setObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: existingConfig)

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(2, storedConfig?.count)
        XCTAssertEqual("optedin", storedConfig?["global.privacy"]?.stringValue)
        XCTAssertTrue(storedConfig?["global.ssl"]?.boolValue ?? false)
    }

    /// Tests that the opted in privacy status is migrated
    func testExistingV4ConfigurationDataForOptIn() {
        // setup
        v4Defaults.set(1, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS) // v4 opted in value

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optedin", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that the opted out privacy status is migrated
    func testExistingV4ConfigurationDataForOptOut() {
        // setup
        v4Defaults.set(2, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS) // v4 opted out value

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optedout", storedConfig?["global.privacy"]?.stringValue)
    }

    /// Tests that the unknown privacy status is migrated
    func testExistingV4ConfigurationDataForUnknown() {
        // setup
        v4Defaults.set(3, forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS) // v4 opted out value

        // test
        V4Migrator(idParser: MockIDParser()).migrate()

        // verify
        // v4 defaults removed
        XCTAssertNil(v4Defaults.object(forKey: V4MigrationConstants.Configuration.V4_PRIVACY_STATUS))

        let dataStore = NamedCollectionDataStore(name: "testable")
        let storedConfig: [String: AnyCodable]? = dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
        XCTAssertEqual(1, storedConfig?.count)
        XCTAssertEqual("optunknown", storedConfig?["global.privacy"]?.stringValue)
    }

    func testExistingV4IdentityData() {
        // setup
        let mockDate = Date()
        v4Defaults.set("&d_cid_ic=type%01id%011", forKey: V4MigrationConstants.Identity.V4_IDS)
        v4Defaults.set("identityECID", forKey: V4MigrationConstants.Identity.V4_ECID)
        v4Defaults.set(1234, forKey: V4MigrationConstants.Identity.V4_TTL)
        v4Defaults.set("blob", forKey: V4MigrationConstants.Identity.V4_BLOB)
        v4Defaults.set("hint", forKey: V4MigrationConstants.Identity.V4_HINT)
        v4Defaults.set(mockDate, forKey: V4MigrationConstants.Lifecycle.V4_INSTALL_DATE)

        // test
        V4Migrator(idParser: IDParser()).migrate()

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
