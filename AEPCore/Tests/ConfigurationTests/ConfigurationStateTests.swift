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
import XCTest

class ConfigurationStateTests: XCTestCase {
    var configState: ConfigurationState!
    let dataStore = NamedCollectionDataStore(name: "ConfigurationStateTests")
    var configDownloader: MockConfigurationDownloader!

    override func setUp() {
        configDownloader = MockConfigurationDownloader()
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

    private func putProgrammaticConfigInPersistence(config: [String: AnyCodable]) {
        dataStore.setObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG, value: config)
    }

    private func putConfigInManifest(config: [String: Any]) {
        configDownloader.configFromManifest = config
    }

    private func assertContainsConfig(config: [String: Any]) {
        for (key, _) in config {
            XCTAssertTrue(configState.currentConfiguration.contains(where: { $0.key == key }))
        }
    }

    // MARK: loadInitialConfig() tests

    /// Tests when appId present, cached config present, bundled config present, programmatic config present
    func testAppIdAndCachedConfigAndBundledConfigAndProgrammaticConfig() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: programmaticConfig)
        XCTAssertFalse(configDownloader.calledLoadDefaultConfig) // bundled config should not even be looked at in this case
    }

    /// Tests when appId present, cached config present, bundled config present, programmatic config not present
    func testAppIdAndCachedConfigAndBundledConfig() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
        XCTAssertFalse(configDownloader.calledLoadDefaultConfig) // bundled config should not even be looked at in this case
    }

    /// Tests when appId present, cached config present, no bundled config, programmatic config present
    func testAppIdAndCachedAndProgrammatic() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: programmaticConfig)
    }

    /// Tests when appId present, cached config present, no bundled config, no programmatic config
    func testAppIdAndCachedConfig() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]

        putAppIdInPersistence(appId: "some-test-app-id")
        putCachedConfigInPersistence(config: cachedConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
    }

    /// Tests when appId present, no cached config, bundled config present, programmatic config present
    func testAppIdAndBundledConfigAndProgrammatic() {
        // setup
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putAppIdInPersistence(appId: "some-test-app-id")
        putProgrammaticConfigInPersistence(config: programmaticConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: programmaticConfig)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
        XCTAssertNotNil(configState.currentConfiguration["bundled.config.key"])
    }

    /// Tests when appId present, no cached config, bundled config present, no programmatic
    func testAppIdAndBundledConfig() {
        // setup
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putAppIdInPersistence(appId: "some-test-app-id")
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count, configState.currentConfiguration.count)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when appId present, no cached config, no bundled config, programmatic config present
    func testAppIdAndProgrammatic() {
        // setup
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]

        putAppIdInPersistence(appId: "some-test-app-id")
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: programmaticConfig)
    }

    /// Tests when appId present, no cached config, no bundled config, no programmatic config
    func testOnlyAppId() {
        // setup
        putAppIdInPersistence(appId: "some-test-app-id")

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.currentConfiguration.isEmpty)
    }

    /// Tests when no appId, cached config present, bundled config present, programmatic config present
    func testCachedConfigAndBundledConfigAndProgrammaticConfig() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putCachedConfigInPersistence(config: cachedConfig)
        putConfigInManifest(config: bundledConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: programmaticConfig)
        assertContainsConfig(config: bundledConfig)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId present, cached config present, bundled config present, no programmatic config
    func testCachedConfigAndBundledConfig() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putCachedConfigInPersistence(config: cachedConfig)
        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count, configState.currentConfiguration.count)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
        assertContainsConfig(config: bundledConfig)
    }

    /// Tests when no appId, cached config present, no bundled config, programmatic config present
    func testCachedConfigAndProgrammatic() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]

        putCachedConfigInPersistence(config: cachedConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: programmaticConfig)
    }

    /// Tests when no appId, cached config present, no bundled config, no programmatic config
    func testCachedConfig() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]

        putCachedConfigInPersistence(config: cachedConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.currentConfiguration.isEmpty)
    }

    /// Tests when no appId, no cached config, bundled config present, programmatic config present
    func testBundledConfigAndProgrammaticConfig() {
        // setup
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putConfigInManifest(config: bundledConfig)
        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: bundledConfig)
        assertContainsConfig(config: programmaticConfig)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId, no cached config, bundled config present, no programmatic config
    func testBundledConfig() {
        // setup
        let bundledConfig: [String: Any] = ["target.timeout": 5, "bundled.config.key": "bundled.config.value"]

        putConfigInManifest(config: bundledConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: bundledConfig)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// Tests when no appId, no cached config, no bundled config, programmatic config present
    func testProgrammaticConfig() {
        // setup
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]

        putProgrammaticConfigInPersistence(config: programmaticConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(programmaticConfig.count, configState.currentConfiguration.count)
        assertContainsConfig(config: programmaticConfig)
    }

    /// Tests when No appId, no cached config, no bundled config, no programmatic config
    func testEmptyConfig() {
        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.currentConfiguration.isEmpty)
    }

    // MARK: updateConfigWith(newConfig) tests

    /// Tests that we can successfully update the config with updateConfigWith(newConfig:)
    func testUpdateConfigNewConfigSimple() {
        // setup
        let expectedConfig = ["testKey": "testVal"]

        // test
        configState.updateWith(newConfig: expectedConfig)

        // verify
        XCTAssertEqual(1, configState.currentConfiguration.count)
        XCTAssertEqual("testVal", configState.currentConfiguration["testKey"] as! String)
    }

    /// Tests that calling updateConfigWith(newConfig:) properly sets and updates key/values
    func testUpdateConfigNewConfigOverwriteAndMerge() {
        // setup
        let expectedConfig = ["testKey": "testVal"]
        let expectedConfig1 = ["testKey": "overwrittenVal", "newKey": "newVal"]

        // test
        configState.updateWith(newConfig: expectedConfig)
        configState.updateWith(newConfig: expectedConfig1)

        // verify
        XCTAssertEqual(2, configState.currentConfiguration.count)
        XCTAssertEqual("overwrittenVal", configState.currentConfiguration["testKey"] as! String)
        XCTAssertEqual("newVal", configState.currentConfiguration["newKey"] as! String)
    }

    /// Test that programmatic config and updateConfigWith merge the existing configs together
    func testUpdateConfigNewConfigPersistedConfigPresent() {
        // setup
        let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]
        putProgrammaticConfigInPersistence(config: programmaticConfig)
        let expectedConfig = ["programmaticKey": "programmaticVal"]

        // test
        configState.updateWith(newConfig: expectedConfig)

        // verify
        XCTAssertEqual(2, configState.currentConfiguration.count)
        XCTAssertEqual("programmaticVal", configState.currentConfiguration["programmaticKey"] as! String)
        XCTAssertEqual("testVal", configState.currentConfiguration["testKey"] as! String)
        assertContainsConfig(config: programmaticConfig)
    }

    // MARK: updateProgrammaticConfig tests

    /// Tests that updating programmatic config updates current and programmatic config
    func testUpdateProgrammaticConfig() {
        // setup
        let expectedConfig = ["testKey": "testVal"]

        // test
        configState.updateWith(programmaticConfig: expectedConfig)

        // verify
        XCTAssertEqual(1, configState.currentConfiguration.count)
        XCTAssertEqual("testVal", configState.currentConfiguration["testKey"] as! String)
        XCTAssertEqual(1, configState.programmaticConfigInDataStore.count)
        XCTAssertEqual("testVal", configState.programmaticConfigInDataStore["testKey"]?.value as? String)
        XCTAssertEqual(dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG), configState.programmaticConfigInDataStore)
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
        XCTAssertEqual("updated-dev-rsid", configState.currentConfiguration["__dev__analytics.rsids"] as? String)
        XCTAssertEqual("rsid1,rsid2", configState.currentConfiguration["analytics.rsids"] as? String)
        XCTAssertEqual("updated-dev-rsid", configState.environmentAwareConfiguration["analytics.rsids"] as? String)
    }

    // MARK: updateConfigWith(appId) tests

    /// Tests the happy path, app id is valid and can be downloaded from the network
    func testUpdateConfigWithAppIdSimple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true

        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromUrl = cachedConfig

        let appId = "valid-app-id"

        // test & verify
        configState.updateWith(appId: appId) { config in
            XCTAssertEqual(cachedConfig.count, config?.count)
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
        let appId = "app-id-not-on-server"

        // test
        configState.updateWith(appId: appId) { config in
            XCTAssertNil(config)
            XCTAssertFalse(self.configState.hasUnexpiredConfig(appId: appId))
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

        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromUrl = cachedConfig

        // test
        configState.updateWith(appId: "valid-app-id") { config in
            XCTAssertEqual(cachedConfig.count, config?.count)
            expectation.fulfill()

            self.configState.updateWith(appId: "newAppId") { newConfig in
                XCTAssertEqual(cachedConfig.count, newConfig?.count)
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 1)
    }

    /// Tests that a valid config is preserved even when an invalid app id is passed
    func testUpdateConfigWithValidThenInvalidId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromUrl = cachedConfig

        // test
        configState.updateWith(appId: "valid-app-id") { config in
            XCTAssertEqual(cachedConfig.count, config?.count)
            self.configDownloader.configFromUrl = nil
            expectation.fulfill()

            self.configState.updateWith(appId: "invalid-app-id") { newConfig in
                XCTAssertNil(newConfig)
                XCTAssertEqual(cachedConfig.count, self.configState.currentConfiguration.count)
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
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
    }

    /// Tests when we have loaded a config from a file path, then we pass in an invalid path that the previous valid configuration is preserved
    func testUpdateConfigWithValidPathThenInvalid() {
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)

        configDownloader.configFromPath = nil // simulate file not found
        XCTAssertFalse(configState.updateWith(filePath: "Invalid/Path/ADBMobile.json"))
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
    }

    /// Tests that the correct config values are shared when the build environment value is empty and all __env__ keys are removed
    func testEnvironmentConfigEmptyEnvironment() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__stage__analytics.rsids": "stagersid1,stagersid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2",
                                             "analytics.server": "mycompany.sc.omtrdc.net"]
        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = ["build.environment": "",
                              "analytics.rsids": "rsid1,rsid2",
                              "analytics.server": "mycompany.sc.omtrdc.net"]

        // test
        let envAwareConfig = configState.computeEnvironmentConfig()

        // verify
        XCTAssertEqual(expectedConfig, envAwareConfig as? [String: String])
    }

    /// Tests that the correct config values are shared when the build environment value is prod
    func testEnvironmentConfigProd() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "prod",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__stage__analytics.rsids": "stagersid1,stagersid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2",
                                             "analytics.server": "mycompany.sc.omtrdc.net"]

        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = ["build.environment": "prod",
                              "analytics.rsids": "rsid1,rsid2",
                              "analytics.server": "mycompany.sc.omtrdc.net"]

        // test
        let envAwareConfig = configState.computeEnvironmentConfig()

        // verify
        XCTAssertEqual(expectedConfig, envAwareConfig as? [String: String])
    }

    /// Tests that the correct config values are shared when the build environment value is staging
    func testEnvironmentConfigStaging() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "stage",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__stage__analytics.rsids": "stagersid1,stagersid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2",
                                             "analytics.server": "mycompany.sc.omtrdc.net"]

        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = ["build.environment": "stage",
                              "analytics.rsids": "stagersid1,stagersid2",
                              "analytics.server": "mycompany.sc.omtrdc.net"]

        // test
        let envAwareConfig = configState.computeEnvironmentConfig()

        // verify
        XCTAssertEqual(expectedConfig, envAwareConfig as? [String: String])
    }

    /// Tests that the correct config values are shared when the build environment value is dev
    func testEnvironmentConfigDev() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "dev",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__stage__analytics.rsids": "stagersid1,stagersid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2",
                                             "analytics.server": "mycompany.sc.omtrdc.net"]

        configState.updateWith(newConfig: existingConfig)

        let expectedConfig = ["build.environment": "dev",
                              "analytics.rsids": "devrsid1,devrsid2",
                              "analytics.server": "mycompany.sc.omtrdc.net"]

        // test
        let envAwareConfig = configState.computeEnvironmentConfig()

        // verify
        XCTAssertEqual(expectedConfig, envAwareConfig as? [String: String])
    }

    /// Tests that when there are no environment specific keys, all existing keys are not modified.
    func testMapEnvironmentKeysNoEnvKeys() {
        // setup
        let newConfig: [String: Any] = ["build.environment": "dev",
                                        "analytics.rsids": "rsid1,rsid2"]

        // test
        let mappedConfig = configState.mapEnvironmentKeys(programmaticConfig: newConfig)

        // verify
        XCTAssertEqual(newConfig as? [String: String], mappedConfig as? [String: String])
    }

    /// Tests that when a config key that has a build specific key is mapped to the specific key
    func testMapEnvironmentKeysDevEnvKeyExist() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "dev",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2"]

        configState.updateWith(newConfig: existingConfig)

        // __dev__ should be prepended to the analytics.rsids key as we are in dev env
        let expected: [String: Any] = ["__dev__analytics.rsids": "updated,rsids"]

        // test
        let mappedConfig = configState.mapEnvironmentKeys(programmaticConfig: ["analytics.rsids": "updated,rsids"])

        // verify
        XCTAssertEqual(expected as? [String: String], mappedConfig as? [String: String])
    }

    /// Tests that when there is not matching environment specific key that the key is mapped correctly
    func testMapEnvironmentKeysDevEnvKeyDoesNotExist() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "dev",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2"]

        configState.updateWith(newConfig: existingConfig)

        // __dev__ should not be prepended to analytics.server as there is no __dev__analytics.sever key in the existing config
        let expected: [String: Any] = ["analytics.server": "server.com"]

        // test
        let mappedConfig = configState.mapEnvironmentKeys(programmaticConfig: ["analytics.server": "server.com"])

        // verify
        XCTAssertEqual(expected as? [String: String], mappedConfig as? [String: String])
    }

    /// Tests that when keys that have environment specific keys and keys that do not are mapped correctly
    func testMapEnvironmentKeysDevEnvKeyExistsAndDoesNotExist() {
        // setup
        let existingConfig: [String: Any] = ["build.environment": "dev",
                                             "analytics.rsids": "rsid1,rsid2",
                                             "__dev__analytics.rsids": "devrsid1,devrsid2",
                                             "analytics.server": "old-server.com"]

        configState.updateWith(newConfig: existingConfig)

        // __dev__ should be prepended to rsids but not analytics.server
        let expected: [String: Any] = ["__dev__analytics.rsids": "updated,rsids", "analytics.server": "server.com"]

        // test
        let mappedConfig = configState.mapEnvironmentKeys(programmaticConfig: ["analytics.rsids": "updated,rsids", "analytics.server": "server.com"])

        // verify
        XCTAssertEqual(expected as? [String: String], mappedConfig as? [String: String])
    }

    // MARK: - Revert Config API Tests
    func testClearConfig() {
        // setup
        let expectedConfig = ["testKey": "testVal"]
        let testAppid = "testAppid"
        let cachedConfig: [String: Any] = ["build.environment": "dev",
                                           "analytics.rsids": "rsid1,rsid2",
                                           "__dev__analytics.rsids": "devrsid1,devrsid2",
                                           "analytics.server": "old-server.com"]
        putAppIdInPersistence(appId: testAppid)
        putCachedConfigInPersistence(config: cachedConfig)

        configState.loadInitialConfig()

        // test
        configState.updateWith(programmaticConfig: expectedConfig)

        // verify
        XCTAssertEqual(5, configState.currentConfiguration.count)
        XCTAssertEqual("testVal", configState.currentConfiguration["testKey"] as! String)
        XCTAssertEqual(1, configState.programmaticConfigInDataStore.count)
        XCTAssertEqual("testVal", configState.programmaticConfigInDataStore["testKey"]?.value as? String)
        XCTAssertEqual(dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG), configState.programmaticConfigInDataStore)

        configState.clearConfigUpdates()

        XCTAssertEqual(4, configState.currentConfiguration.count)
        XCTAssertNil(configState.currentConfiguration["testKey"] as? String)
        XCTAssertEqual(0, configState.programmaticConfigInDataStore.count)
        XCTAssertNil(configState.programmaticConfigInDataStore["testKey"]?.value as? String)
        XCTAssertEqual(0, (dataStore.getObject(key: ConfigurationConstants.DataStoreKeys.PERSISTED_OVERRIDDEN_CONFIG) as [String:AnyCodable]?)?.count)
    }

    // Tests that updating then reverting then updating the config doesn't have remnants from first update
    func testUpdateClearUpdate() {
        // setup
        let firstUpdate = ["shouldNotExist": "afterRevert"]
        let testAppid = "testAppid"
        let cachedConfig: [String: Any] = ["build.environment": "dev",
                                           "analytics.rsids": "rsid1,rsid2",
                                           "__dev__analytics.rsids": "devrsid1,devrsid2",
                                           "analytics.server": "old-server.com"]
        let expectedConfig2: [String: String] = ["analytics.server": "new-server.com", "newKey": "newValue"]
        putAppIdInPersistence(appId: testAppid)
        putCachedConfigInPersistence(config: cachedConfig)

        configState.loadInitialConfig()

        // test
        configState.updateWith(programmaticConfig: firstUpdate)

        configState.clearConfigUpdates()

        configState.updateWith(programmaticConfig:  expectedConfig2)

        XCTAssertEqual(5, configState.currentConfiguration.count)
        XCTAssertNil(configState.currentConfiguration["shouldNotExist"] as? String)
        XCTAssertEqual(2, configState.programmaticConfigInDataStore.count)
        XCTAssertNil(configState.programmaticConfigInDataStore["testKey"]?.value as? String)
        let progammaticMapped: [String: String] = configState.programmaticConfigInDataStore.mapValues{$0.stringValue!}
        XCTAssertEqual(expectedConfig2, progammaticMapped)
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

        let mappedCurrentConfig: [String: String] = configState.currentConfiguration.mapValues {$0 as! String}
        XCTAssertEqual(mappedCurrentConfig, cachedConfig)
    }

    func testConfigureWithFilePathThenUpdateThenClear() {
        let cachedConfig: [String: String] = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
                                              "target.clientCode": "yourclientcode",
                                              "analytics.server": "old-server.com"]
        configDownloader.configFromPath = cachedConfig // simulate file found

        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        XCTAssertEqual(cachedConfig, configState.currentConfiguration.mapValues{$0 as! String})

        configState.updateWith(programmaticConfig: ["analytics.server": "new-server.com", "newKey": "newValue"])

        XCTAssertEqual(4, configState.currentConfiguration.count)
        XCTAssertEqual("new-server.com", configState.currentConfiguration["analytics.server"] as? String)
        XCTAssertEqual("newValue", configState.currentConfiguration["newKey"] as? String)

        configState.clearConfigUpdates()

        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        XCTAssertEqual(cachedConfig, configState.currentConfiguration.mapValues{$0 as! String})
    }

    // Tests that updating then reverting then updating the config doesn't have remnants from first update
    func testConfigureWithFilePathThenUpdateThenClearThenUpdate() {
        // setup
        let firstUpdate = ["shouldNotExist": "afterRevert"]
        let cachedConfig: [String: Any] = ["build.environment": "dev",
                                           "analytics.rsids": "rsid1,rsid2",
                                           "__dev__analytics.rsids": "devrsid1,devrsid2",
                                           "analytics.server": "old-server.com"]
        let expectedConfig2: [String: String] = ["analytics.server": "new-server.com", "newKey": "newValue"]

        configDownloader.configFromPath = cachedConfig
        XCTAssertTrue(configState.updateWith(filePath: "validPath"))

        // test
        configState.updateWith(programmaticConfig: firstUpdate)

        configState.clearConfigUpdates()

        configState.updateWith(programmaticConfig:  expectedConfig2)

        XCTAssertEqual(5, configState.currentConfiguration.count)
        XCTAssertNil(configState.currentConfiguration["shouldNotExist"] as? String)
        XCTAssertEqual(2, configState.programmaticConfigInDataStore.count)
        XCTAssertNil(configState.programmaticConfigInDataStore["testKey"]?.value as? String)
        let progammaticMapped: [String: String] = configState.programmaticConfigInDataStore.mapValues{$0.stringValue!}
        XCTAssertEqual(expectedConfig2, progammaticMapped)
    }


}
