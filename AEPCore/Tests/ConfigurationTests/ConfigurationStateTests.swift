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
@testable import AEPCoreMocks
//@testable import AEPServicesMocks
import AEPServices
import XCTest

class ConfigurationStateTests: XCTestCase, AnyCodableAsserts {
    var configState: ConfigurationState!
    let dataStore = NamedCollectionDataStore(name: "ConfigurationStateTests")
    var configDownloader: MockConfigurationDownloader!

    override func setUp() {
        configDownloader = MockConfigurationDownloader()
        NamedCollectionDataStore.clear()
        configState = ConfigurationState(dataStore: dataStore, configDownloader: configDownloader)
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func putAppIdInPersistence(appId: String) {
        dataStore.set(key: ConfigurationConstants.DataStoreKeys.PERSISTED_APPID, value: appId)
    }

    private func putCachedConfigInPersistence(config: [String: Any]) {
        configDownloader.configFromCache = config
    }

    private func putProgrammaticConfigInPersistence(config: [String: Any]) {
        if let value = AnyCodable.from(dictionary: config) {
            dataStore.setObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: value)
        }
    }

    private func getProgrammaticConfigFromPersistence() -> [String: AnyCodable]? {
        return dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG)
    }

    private func putConfigInManifest(config: [String: Any]) {
        configDownloader.configFromManifest = config
    }

    // MARK: loadInitialConfig() tests

    /// Tests when appId present, cached config present, bundled config present, programmatic config present
    func testAppIdAndCachedConfigAndBundledConfigAndProgrammaticConfig() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        let programmaticConfig = ["testKey": "testVal"]
        let bundledConfig: [String: Any] = [
            "target.timeout": 5, 
            "bundled.config.key":
                "bundled.config.value"
        ]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        let expected = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode",
            "testKey": "testVal"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)
        XCTAssertFalse(configDownloader.calledLoadDefaultConfig) // bundled config should not even be looked at in this case
    }

    /// Tests when appId present, cached config present, bundled config present, programmatic config not present
    func testAppIdAndCachedConfigAndBundledConfig() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        let bundledConfig: [String : Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value"
        ]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: cachedConfig, actual: configState.environmentAwareConfiguration)
        XCTAssertFalse(configDownloader.calledLoadDefaultConfig) // bundled config should not even be looked at in this case
    }

    /// Tests when appId present, cached config present, no bundled config, programmatic config present
    func testAppIdAndCachedAndProgrammatic() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        let programmaticConfig = ["testKey": "testVal"]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        let expected = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode",
            "testKey": "testVal"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)
    }

    /// Tests when appId present, cached config present, no bundled config, no programmatic config
    func testAppIdAndCachedConfig() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: cachedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests when appId present, no cached config, bundled config present, programmatic config present
    func testAppIdAndBundledConfigAndProgrammatic() {
        // setup
        let programmaticConfig = ["testKey": "testVal"]
        let bundledConfig: [String: Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value"
        ]

        putAppIdInPersistence(appId: "some-test-app-id")
        putProgrammaticConfigInPersistence(config: programmaticConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        let expected: [String: Any] = [
            "bundled.config.key": "bundled.config.value",
            "target.timeout": 5,
            "testKey": "testVal"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when appId present, no cached config, bundled config present, no programmatic
    func testAppIdAndBundledConfig() {
        // setup
        let bundledConfig: [String: Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value"
        ]

        putAppIdInPersistence(appId: "some-test-app-id")
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: bundledConfig, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when appId present, no cached config, no bundled config, programmatic config present
    func testAppIdAndProgrammatic() {
        // setup
        let programmaticConfig = ["testKey": "testVal"]

        putAppIdInPersistence(appId: "some-test-app-id")
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: programmaticConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests when appId present, no cached config, no bundled config, no programmatic config
    func testOnlyAppId() {
        // setup
        putAppIdInPersistence(appId: "some-test-app-id")

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.environmentAwareConfiguration.isEmpty)
    }

    /// Tests when no appId, cached config present, bundled config present, programmatic config present
    func testCachedConfigAndBundledConfigAndProgrammaticConfig() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        let programmaticConfig: [String: Any] = [
            "testKey": "testVal"
        ]
        let bundledConfig: [String: Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value"
        ]

        putCachedConfigInPersistence(config: cachedConfig)
        putConfigInManifest(config: bundledConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        let expected: [String : Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value",
            "testKey": "testVal"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId present, cached config present, bundled config present, no programmatic config
    func testCachedConfigAndBundledConfig() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        let bundledConfig: [String: Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value"
        ]

        putCachedConfigInPersistence(config: cachedConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: bundledConfig, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId, cached config present, no bundled config, programmatic config present
    func testCachedConfigAndProgrammatic() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        let programmaticConfig = ["testKey": "testVal"]

        putCachedConfigInPersistence(config: cachedConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: programmaticConfig, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId, cached config present, no bundled config, no programmatic config
    func testCachedConfig() {
        // setup
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]

        putCachedConfigInPersistence(config: cachedConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.environmentAwareConfiguration.isEmpty)
    }

    /// Tests when no appId, no cached config, bundled config present, programmatic config present
    func testBundledConfigAndProgrammaticConfig() {
        // setup
        let programmaticConfig = ["testKey": "testVal"]
        let bundledConfig: [String: Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value"
        ]

        putConfigInManifest(config: bundledConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        let expected: [String: Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value",
            "testKey": "testVal"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId, no cached config, bundled config present, no programmatic config
    func testBundledConfig() {
        // setup
        let bundledConfig: [String: Any] = [
            "target.timeout": 5,
            "bundled.config.key": "bundled.config.value"
        ]

        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: bundledConfig, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId, no cached config, no bundled config, programmatic config present
    func testProgrammaticConfig() {
        // setup
        let programmaticConfig = ["testKey": "testVal"]

        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        assertEqual(expected: programmaticConfig, actual: configState.environmentAwareConfiguration)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when No appId, no cached config, no bundled config, no programmatic config
    func testEmptyConfig() {
        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.environmentAwareConfiguration.isEmpty)
    }

    // MARK: updateConfigWith(newConfig) tests

    /// Tests that we can successfully update the config with updateConfigWith(newConfig:)
    func testUpdateConfigNewConfigSimple() {
        // setup
        let expectedConfig = ["testKey": "testVal"]

        // test
        configState.updateWith(newConfig: expectedConfig)

        // verify
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests that calling updateConfigWith(newConfig:) properly sets and replaces key/values
    func testUpdateConfigNewConfigOverwrite() {
        // setup
        let expectedConfig = ["testKey": "testVal", "testKey2": "testVal2"]
        let expectedConfig1 = ["testKey": "overwrittenVal", "newKey": "newVal"]

        // test
        configState.updateWith(newConfig: expectedConfig)
        configState.updateWith(newConfig: expectedConfig1)

        // verify
        assertEqual(expected: expectedConfig1, actual: configState.environmentAwareConfiguration)
    }

    /// Test that programmatic config and updateConfigWith merge the existing configs together
    func testUpdateConfigNewConfigPersistedConfigPresent() {
        // setup
        let programmaticConfig = ["programmaticKey": "programmaticVal"]
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        let config = ["testKey": "testVal"]

        // test
        configState.updateWith(newConfig: config)

        // verify
        let expected = [
            "programmaticKey": "programmaticVal",
            "testKey": "testVal"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)
    }

    // MARK: updateProgrammaticConfig tests

    /// Tests that updating programmatic config updates current and programmatic config
    func testUpdateProgrammaticConfig() {
        // setup
        let expectedConfig = ["testKey": "testVal"]

        // test
        configState.updateWith(programmaticConfig: expectedConfig)

        // verify
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
        assertEqual(expected: expectedConfig, actual: getProgrammaticConfigFromPersistence())
    }

    /// Tests that updating programmatic config updates the correct build environment key
    func testUpdateProgrammaticConfigCorrectEnvironmentKey() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "dev",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2",
                                             "analytics.server": "old-server.com"]
        configState.updateWith(newConfig: existingConfig)

        // test
        configState.updateWith(programmaticConfig: ["analytics.rsids": "updated-dev-rsid"])

        // verify
        let expected = [
            "build.environment": "dev",
            "analytics.rsids": "updated-dev-rsid",
            "analytics.server": "old-server.com"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)

        let expectedProgrammatic = [
            "__dev__analytics.rsids": "updated-dev-rsid"
        ]
        assertEqual(expected: expectedProgrammatic, actual: getProgrammaticConfigFromPersistence())
    }

    /// Tests that when there is not matching environment specific key that the key is mapped correctly
    func testUpdateProgrammaticConfigNoMatchingEnvironmentKey() {
        // setup
        let existingConfig = [
            "build.environment": "dev",
            "analytics.rsids": "rsid1,rsid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2"
        ]

        configState.updateWith(newConfig: existingConfig)

        // test
        // __dev__ should not be prepended to analytics.server as there is no __dev__analytics.sever key in the existing config
        configState.updateWith(programmaticConfig: ["analytics.server": "server.com"])


        // verify
        let expected = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "server.com"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)

        let expectedProgrammatic = [
            "analytics.server": "server.com"
        ]
        assertEqual(expected: expectedProgrammatic, actual: getProgrammaticConfigFromPersistence())
    }

    /// Tests that when keys that have environment specific keys and keys that do not are mapped correctly
    func testUpdateProgrammaticConfigDevEnvKeyExistsAndDoesNotExist() {
        // setup
        let existingConfig = [
            "build.environment": "dev",
            "analytics.rsids": "rsid1,rsid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "old-server.com"
        ]

        configState.updateWith(newConfig: existingConfig)

        // test
        // __dev__ should be prepended to rsids but not analytics.server
        configState.updateWith(programmaticConfig: ["__dev__analytics.rsids": "updated,rsids", "analytics.server": "server.com"])

        // verify
        let expected = [
            "build.environment": "dev",
            "analytics.rsids": "updated,rsids",
            "analytics.server": "server.com"
        ]
        assertEqual(expected: expected, actual: configState.environmentAwareConfiguration)

        let expectedProgrammatic = [
            "__dev__analytics.rsids": "updated,rsids",
            "analytics.server": "server.com"
        ]
        assertEqual(expected: expectedProgrammatic, actual: getProgrammaticConfigFromPersistence())
    }

    // MARK: updateConfigWith(appId) tests

    /// Tests the happy path, app id is valid and can be downloaded from the network
    func testUpdateConfigWithAppIdSimple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true

        let cachedConfig = [
            "build.environment": "dev",
            "analytics.rsids": "rsid1,rsid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
        ]
        configDownloader.configFromUrl = cachedConfig

        let appId = "valid-app-id"


        let expectedConfig = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
        ]
        // test & verify
        configState.updateWith(appId: appId) { config in
            self.assertEqual(expected: cachedConfig, actual: config)
            self.assertEqual(expected: expectedConfig, actual: self.configState.environmentAwareConfiguration)
            XCTAssertTrue(self.configState.hasUnexpiredConfig(appId: appId))
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests when network is down or app id is invalid, no cached config
    func testUpdateConfigWithAppIdInvalidId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true
        let appId = "app-id-download-failure"

        // test
        configState.updateWith(appId: appId) { config in
            XCTAssertNil(config)
            XCTAssertFalse(self.configState.hasUnexpiredConfig(appId: appId))
            XCTAssertTrue(self.configState.environmentAwareConfiguration.isEmpty)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)        
    }

    /// Tests that we can configure with multiple app ids
    func testUpdateConfigWithAppIdMultiple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        let firstAppIdConfig = [
            "config1.key": "config1.value"
        ]

        let secondAppIdConfig = [
            "config2.key": "config2.value"
        ]
        configDownloader.configFromUrl = firstAppIdConfig

        // test
        configState.updateWith(appId: "valid-app-id") { config in
            self.assertEqual(expected: firstAppIdConfig, actual: config)
            self.assertEqual(expected: firstAppIdConfig, actual: self.configState.environmentAwareConfiguration)
            expectation.fulfill()

            self.configDownloader.configFromUrl = secondAppIdConfig
            self.configState.updateWith(appId: "newAppId") { newConfig in
                self.assertEqual(expected: secondAppIdConfig, actual: newConfig)
                self.assertEqual(expected: secondAppIdConfig, actual: self.configState.environmentAwareConfiguration)
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that a valid config is preserved for the session even when new app-id download failure happens
    func testUpdateConfigWithValidThenInvalidId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        let firstAppIdConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        configDownloader.configFromUrl = firstAppIdConfig

        // test
        configState.updateWith(appId: "valid-app-id") { config in
            self.assertEqual(expected: firstAppIdConfig, actual: config)
            self.assertEqual(expected: firstAppIdConfig, actual: self.configState.environmentAwareConfiguration)
            self.configDownloader.configFromUrl = nil
            expectation.fulfill()

            self.configState.updateWith(appId: "invalid-app-id") { newConfig in
                XCTAssertNil(newConfig)
                self.assertEqual(expected: firstAppIdConfig, actual: self.configState.environmentAwareConfiguration)
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    // MARK: updateConfigWith(filePath) tests

    /// Tests when an empty path is supplied we return false and don't update the current configuration
    func testUpdateConfigWithFilePathEmpty() {
        XCTAssertFalse(configState.updateWith(filePath: ""))
    }

    /// Tests when the configuration downloader returns a nil config we properly update the current configuration
    func testUpdateConfigWithFilePathInvalidPath() {
        XCTAssertFalse(configState.updateWith(filePath: "Invalid/Path/ADBMobile.json"))
    }

    /// Tests when the configuration downloader returns a valid config we properly update the current configuration
    func testUpdateConfigWithPathSimple() {
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        assertEqual(expected: cachedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests when we have loaded a config from a file path, then we pass in an invalid path that the previous valid configuration is preserved
    func testUpdateConfigWithValidPathThenInvalid() {
        let cachedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode"
        ]
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        assertEqual(expected: cachedConfig, actual: configState.environmentAwareConfiguration)

        configDownloader.configFromPath = nil // simulate file not found
        XCTAssertFalse(configState.updateWith(filePath: "Invalid/Path/ADBMobile.json"))
        assertEqual(expected: cachedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests that the correct config values are shared when the build environment value is empty and all __env__ keys are removed
    func testEnvironmentConfigEmptyEnvironment() {
        // setup
        let existingConfig = [
            "build.environment": "",
            "analytics.rsids": "rsid1,rsid2",
            "__stage__analytics.rsids": "stagersid1,stagersid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]
        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = [
            "build.environment": "",
            "analytics.rsids": "rsid1,rsid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]
        // verify
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests that the correct config values are shared when the build environment value is prod
    func testEnvironmentConfigProd() {
        // setup
        let existingConfig: [String: Any] = [
            "build.environment": "prod",
            "analytics.rsids": "rsid1,rsid2",
            "__stage__analytics.rsids": "stagersid1,stagersid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]

        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = [
            "build.environment": "prod",
            "analytics.rsids": "rsid1,rsid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]

        // verify
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests that the correct config values are shared when the build environment value is staging
    func testEnvironmentConfigStaging() {
        // setup
        let existingConfig: [String: Any] = [
            "build.environment": "stage",
            "analytics.rsids": "rsid1,rsid2",
            "__stage__analytics.rsids": "stagersid1,stagersid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]

        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = [
            "build.environment": "stage",
            "analytics.rsids": "stagersid1,stagersid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]

        // verify
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests that the correct config values are shared when the build environment value is dev
    func testEnvironmentConfigDev() {
        // setup
        let existingConfig: [String: Any] = [
            "build.environment": "dev",
            "analytics.rsids": "rsid1,rsid2",
            "__stage__analytics.rsids": "stagersid1,stagersid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]

        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "mycompany.sc.omtrdc.net"
        ]

        // verify
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests that when there are no environment specific keys, all existing keys are not modified.
    func testEnvironmentConfigNoEnvKeys() {
        // setup
        let newConfig: [String: Any] = [
            "build.environment": "dev", 
            "analytics.rsids": "rsid1,rsid2"
        ]

        // test
        configState.updateWith(newConfig: newConfig)

        // verify
        assertEqual(expected: newConfig, actual: configState.environmentAwareConfiguration)
    }

    /// Tests that environment specific keys are removed when there is no build.environment
    func testEnvironmentConfigNoBuildEnvironment() {
        // setup
        let newConfig: [String: Any] = [
            "__dev__analytics.rsids": "rsid1,rsid2",
            "testKey": "testVal"
        ]

        // test
        configState.updateWith(newConfig: newConfig)

        // verify
        let expectedConfig = [
            "testKey": "testVal"
        ]
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
    }

    // MARK: - Revert Config API Tests
    func testClearConfig() {
        // setup
        let testAppid = "testAppid"
        let cachedConfig: [String: Any] = [
            "build.environment": "dev",
            "analytics.rsids": "rsid1,rsid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "old-server.com"
        ]
        putAppIdInPersistence(appId: testAppid)
        putCachedConfigInPersistence(config: cachedConfig)

        configState.loadInitialConfig()

        // test
        let expectedConfig = ["testKey": "testVal"]
        configState.updateWith(programmaticConfig: expectedConfig)

        // verify
        let configAfterProgrammaticUpdate = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "old-server.com",
            "testKey": "testVal"
        ]
        assertEqual(expected:configAfterProgrammaticUpdate , actual: configState.environmentAwareConfiguration)
        assertEqual(expected:expectedConfig , actual: getProgrammaticConfigFromPersistence())

        configState.clearConfigUpdates()

        let configAfterClear = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "old-server.com"
        ]
        assertEqual(expected:configAfterClear , actual: configState.environmentAwareConfiguration)
        assertEqual(expected:[:] , actual: getProgrammaticConfigFromPersistence())
    }

    // Tests that updating then reverting then updating the config doesn't have remnants from first update
    func testUpdateClearUpdate() {
        // setup
        let testAppid = "testAppid"
        let cachedConfig = [
            "build.environment": "dev",
            "analytics.rsids": "rsid1,rsid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "old-server.com"
        ]
        putAppIdInPersistence(appId: testAppid)
        putCachedConfigInPersistence(config: cachedConfig)

        configState.loadInitialConfig()

        // test
        let firstUpdate = ["shouldNotExist": "afterRevert"]
        configState.updateWith(programmaticConfig: firstUpdate)
        assertEqual(expected:firstUpdate , actual: getProgrammaticConfigFromPersistence())

        configState.clearConfigUpdates()

        let secondUpdate: [String: String] = ["analytics.server": "new-server.com", "newKey": "newValue"]
        configState.updateWith(programmaticConfig:  secondUpdate)

        let expectedConfig = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "new-server.com",
            "newKey": "newValue"
        ]
        assertEqual(expected:expectedConfig , actual: configState.environmentAwareConfiguration)
        assertEqual(expected:secondUpdate , actual: getProgrammaticConfigFromPersistence())
    }

    // Test reverting without an update makes no change
    func testClearWithoutUpdateMakesNoChange() {
        let testAppid = "testAppid"
        let cachedConfig: [String: String] = ["build.environment": "dev",
                                              "analytics.rsids": "rsid1,rsid2",
                                              "__dev__analytics.rsids": "devrsid1,devrsid2",
                                              "analytics.server": "old-server.com"]
        putAppIdInPersistence(appId: testAppid)
        putCachedConfigInPersistence(config: cachedConfig)

        configState.loadInitialConfig()

        configState.clearConfigUpdates()

        let expectedConfig = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "old-server.com"
        ]
        assertEqual(expected:expectedConfig , actual: configState.environmentAwareConfiguration)
        assertEqual(expected:[:] , actual: getProgrammaticConfigFromPersistence())
    }

    func testConfigureWithFilePathThenUpdateThenClear() {
        let cachedConfig: [String: String] = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode",
            "analytics.server": "old-server.com"
        ]
        configDownloader.configFromPath = cachedConfig // simulate file found

        XCTAssertTrue(configState.updateWith(filePath: "validPath"))


        assertEqual(expected: cachedConfig, actual: configState.environmentAwareConfiguration)


        configState.updateWith(programmaticConfig: ["analytics.server": "new-server.com", "newKey": "newValue"])

        let expectedConfig = [
            "experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
            "target.clientCode": "yourclientcode",
            "analytics.server": "new-server.com",
            "newKey": "newValue"
        ]
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)

        configState.clearConfigUpdates()

        assertEqual(expected: cachedConfig, actual: configState.environmentAwareConfiguration)
        assertEqual(expected:[:] , actual: getProgrammaticConfigFromPersistence())
    }

    // Tests that updating then reverting then updating the config doesn't have remnants from first update
    func testConfigureWithFilePathThenUpdateThenClearThenUpdate() {
        // setup
        let cachedConfig: [String: Any] = [
            "build.environment": "dev",
            "analytics.rsids": "rsid1,rsid2",
            "__dev__analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "old-server.com"
        ]
        configDownloader.configFromPath = cachedConfig

        XCTAssertTrue(configState.updateWith(filePath: "validPath"))

        // test
        let firstUpdate = ["shouldNotExist": "afterRevert"]
        configState.updateWith(programmaticConfig: firstUpdate)

        configState.clearConfigUpdates()

        let secondUpdate = ["analytics.server": "new-server.com", "newKey": "newValue"]
        configState.updateWith(programmaticConfig:  secondUpdate)


        let expectedConfig = [
            "build.environment": "dev",
            "analytics.rsids": "devrsid1,devrsid2",
            "analytics.server": "new-server.com",
            "newKey": "newValue"

        ]
        assertEqual(expected: expectedConfig, actual: configState.environmentAwareConfiguration)
        assertEqual(expected:secondUpdate , actual: getProgrammaticConfigFromPersistence())
    }


}
