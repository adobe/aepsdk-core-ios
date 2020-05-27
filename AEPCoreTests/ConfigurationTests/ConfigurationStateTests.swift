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

class ConfigurationStateTests: XCTestCase {
    var configState: ConfigurationState!
    let dataStore = NamedKeyValueStore(name: ConfigurationConstants.DATA_STORE_NAME)
    var configDownloader: MockConfigurationDownloader!
    

    override func setUp() {
        dataStore.removeAll()
        configDownloader = MockConfigurationDownloader()
        configState = ConfigurationState(dataStore: dataStore, configDownloader: configDownloader)
    }

    private func putAppIdInPersistence(appId: String) {
        dataStore.set(key: ConfigurationConstants.Keys.PERSISTED_APPID, value: appId)
    }

    private func putCachedConfigInPersistence(config: [String: Any]) {
        configDownloader.configFromCache = config
    }

    private func putProgrammaticConfigInPersistence(config: [String: AnyCodable]) {
        dataStore.setObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG, value: config)
    }

    private func putConfigInManifest(config: [String: Any]) {
        configDownloader.configFromManifest = config
    }
    
    private func assertContainsConfig(config: [String: Any]) {
        for (key, _) in config {
            XCTAssertTrue(configState.currentConfiguration.contains(where: {$0.key == key}))
        }
    }
    
    /// #1, appId present, cached config present, bundled config present, programmatic config present
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

    /// #2, appId present, cached config present, bundled config present, programmatic config not present
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

    /// #3, appId present, cached config present, no bundled config, programmatic config present
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

    /// #4, appId present, cached config present, no bundled config, no programmatic config
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

    /// #5, appId present, no cached config, bundled config present, programmatic config present
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

    /// #6, appId present, no cached config, bundled config present, no programmatic
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

    /// #7, appId present, no cached config, no bundled config, programmatic config present
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

    /// #8, appId present, no cached config, no bundled config, no programmatic config
    func testOnlyAppId() {
        // setup
        putAppIdInPersistence(appId: "some-test-app-id")

        // test
        configState.loadInitialConfig()
        
        // verify
        XCTAssertTrue(configState.currentConfiguration.isEmpty)
    }

    /// #9, no appId, cached config present, bundled config present, programmatic config present
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

    /// #10, no appId present, cached config present, bundled config present, no programmatic config
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

    /// #11, no appId, cached config present, no bundled config, programmatic config present
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

    /// #12, no appId, cached config present, no bundled config, no programmatic config
    func testCachedConfig() {
        // setup
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        
        putCachedConfigInPersistence(config: cachedConfig)

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.currentConfiguration.isEmpty)
    }

    /// #13, no appId, no cached config, bundled config present, programmatic config present
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

    /// #14, no appId, no cached config, bundled config present, no programmatic config
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

    /// #15, no appId, no cached config, no bundled config, programmatic config present
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

    /// #16, No appId, no cached config, no bundled config, no programmatic config
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

    /// tests that updating programmatic config updates current and programmatic config
    func testUpdateProgrammaticConfig() {
        // setup
        let expectedConfig = ["testKey": "testVal"]

        // test
        configState.updateWith(programmaticConfig: expectedConfig)

        // verify
        XCTAssertEqual(1, configState.currentConfiguration.count)
        XCTAssertEqual("testVal", configState.currentConfiguration["testKey"] as! String)
        XCTAssertEqual(1, configState.programmaticConfigInDataStore.count)
        XCTAssertEqual("testVal", configState.programmaticConfigInDataStore["testKey"]?.stringValue)
        XCTAssertEqual(dataStore.getObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG), configState.programmaticConfigInDataStore)
    }

    // MARK: updateConfigWith(appId) tests

    /// case 1: happy path, app id is valid and can be downloaded from the network
    func testUpdateConfigWithAppIdSimple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true

        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromUrl = cachedConfig
        
        // test & verify
        configState.updateWith(appId: "valid-app-id") { (config) in
            XCTAssertEqual(cachedConfig.count, config?.count)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// case 2: network is down or app id is invalid, no cached config
    func testUpdateConfigWithAppIdInvalidId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true
        let appId = "app-id-not-on-server"

        // test
        configState.updateWith(appId: appId) { (config) in
            XCTAssertNil(config)
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// case 3: can configure with multiple app ids
    func testUpdateConfigWithAppIdMultiple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromUrl = cachedConfig
        
        // test
        configState.updateWith(appId: "valid-app-id") { (config) in
            XCTAssertEqual(cachedConfig.count, config?.count)
            expectation.fulfill()
            
            self.configState.updateWith(appId: "newAppId") { (newConfig) in
                XCTAssertEqual(cachedConfig.count, newConfig?.count)
                expectation.fulfill()
            }
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// case 4: valid config is preserved even when an invalid app id is passed
    func testUpdateConfigWithValidThenInvalidId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromUrl = cachedConfig
        
        // test
        configState.updateWith(appId: "valid-app-id") { (config) in
            XCTAssertEqual(cachedConfig.count, config?.count)
            self.configDownloader.configFromUrl = nil
            expectation.fulfill()
            
            self.configState.updateWith(appId: "invalid-app-id") { (newConfig) in
                XCTAssertNil(newConfig)
                XCTAssertEqual(cachedConfig.count, self.configState.currentConfiguration.count)
                expectation.fulfill()
            }
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    // MARK: updateConfigWith(filePath)
    
    /// When an empty path is supplied we return false and don't update the current configuration
    func testUpdateConfigWithFilePathEmpty() {
        XCTAssertFalse(configState.updateWith(filePath: ""))
    }
    
    /// When the configuration downloader returns a nil config we properly update the current configuration
    func testUpdateConfigWithFilePathInvalidPath() {
        XCTAssertFalse(configState.updateWith(filePath: "Invalid/Path/ADBMobile.json"))
    }
    
    /// When the configuration downloader returns a valid config we properly update the current configuration
    func testUpdateConfigWithPathSimple() {
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
    }
    
    /// Tests that when we have loaded a config from a file path, then we pass in an invalid path that the previous valid configuration is preserved
    func testUpdateConfigWithValidPathThenInvalid() {
        let cachedConfig = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg", "target.clientCode": "yourclientcode"]
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateWith(filePath: "validPath"))
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)

        configDownloader.configFromPath = nil // simulate file not found
        XCTAssertFalse(configState.updateWith(filePath: "Invalid/Path/ADBMobile.json"))
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
    }

}
