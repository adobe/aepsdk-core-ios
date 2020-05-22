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
    let programmaticConfig: [String: AnyCodable] = ["testKey": AnyCodable("testVal")]
    let cachedConfig: [String: AnyCodable] = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
                                                 "target.clientCode": "yourclientcode",
                                                 "target.timeout": 5,
                                                 "audience.server": "omniture.demdex.net",
                                                 "audience.timeout": 5,
                                                 "analytics.rsids": "mobilersidsample",
                                                 "analytics.server": "obumobile1.sc.omtrdc.net",
                                                 "analytics.aamForwardingEnabled": false,
                                                 "analytics.offlineEnabled": true,
                                                 "analytics.batchLimit": 0,
                                                 "analytics.backdatePreviousSessionInfo": false,
                                                 "global.privacy": "optedin",
                                                 "lifecycle.sessionTimeout": 300,
                                                 "rules.url": "https://link.to.rules/test.zip",
                                                 "exampleKey": "exampleVal",
                                                 "exampleKey1": "exampleVal1"]
    
    let bundledConfig: [String: Any] = ["target.timeout": 5,
                          "global.privacy": "optedin",
                          "analytics.backdatePreviousSessionInfo": false,
                          "analytics.offlineEnabled": true,
                          "build.environment": "prod",
                          "rules.url": "https://assets.adobedtm.com/launch-EN1a68f9bc5b3c475b8c232adc3f8011fb-rules.zip",
                          "target.clientCode": "",
                          "experienceCloud.org": "972C898555E9F7BC7F000101@AdobeOrg",
                          "lifecycle.sessionTimeout": 300,
                          "target.environmentId": "",
                          "analytics.server": "obumobile5.sc.omtrdc.net",
                          "analytics.rsids": "adobe.bundled.config",
                          "analytics.batchLimit": 3,
                          "property.id": "PR3dd64c475eb747339f0319676d56b1df",
                          "global.ssl": true,
                          "analytics.aamForwardingEnabled": true,
                          "bundled.config.key": "bundled.config.value"
                        ]

    var configState: ConfigurationState!
    let dataStore = NamedKeyValueStore(name: ConfigurationConstants.DATA_STORE_NAME)
    var appIdManager: AppIDManager!
    var configDownloader: MockConfigurationDownloader!
    

    override func setUp() {
        dataStore.removeAll()
        AEPServiceProvider.shared.systemInfoService = MockSystemInfoService()
        appIdManager = AppIDManager(dataStore: dataStore)
        configDownloader = MockConfigurationDownloader()
        configState = ConfigurationState(dataStore: dataStore, appIdManager: appIdManager, configDownloader: configDownloader)
    }

    private func putAppIdInPersistence() {
        dataStore.set(key: ConfigurationConstants.Keys.PERSISTED_APPID, value: "some-valid-app-id")
    }

    private func putCachedConfigInPersistence(appId: String? = nil) {
        configDownloader.configFromCache = cachedConfig
    }

    private func putProgrammaticConfigInPersistence() {
        dataStore.setObject(key: ConfigurationConstants.Keys.PERSISTED_OVERRIDDEN_CONFIG, value: programmaticConfig)
    }

    private func putConfigInManifest() {
        configDownloader.configFromManifest = bundledConfig
    }

    private func assertHasProgrammaticConfig() {
        XCTAssertEqual(configState.currentConfiguration["testKey"] as! String, "testVal")
    }

    private func assertHasBundledConfig() {
        XCTAssertEqual(configState.currentConfiguration["bundled.config.key"] as! String, "bundled.config.value")
    }
    
    /// #1, appId present, cached config present, bundled config present, programmatic config present
    func testAppIdAndCachedConfigAndBundledConfigAndProgrammaticConfig() {
        // setup
        putAppIdInPersistence()
        putCachedConfigInPersistence()
        putProgrammaticConfigInPersistence()
        putConfigInManifest()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertHasProgrammaticConfig()
        XCTAssertFalse(configDownloader.calledLoadDefaultConfig) // bundled config should not even be looked at in this case
    }

    /// #2, appId present, cached config present, bundled config present, programmatic config not present
    func testAppIdAndCachedConfigAndBundledConfig() {
        // setup
        putAppIdInPersistence()
        putCachedConfigInPersistence()
        putConfigInManifest()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
        XCTAssertFalse(configDownloader.calledLoadDefaultConfig) // bundled config should not even be looked at in this case
    }

    /// #3, appId present, cached config present, no bundled config, programmatic config present
    func testAppIdAndCachedAndProgrammatic() {
        putAppIdInPersistence()
        putCachedConfigInPersistence()
        putProgrammaticConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertHasProgrammaticConfig()
    }

    /// #4, appId present, cached config present, no bundled config, no programmatic config
    func testAppIdAndCachedConfig() {
        // setup
        putAppIdInPersistence()
        putCachedConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(cachedConfig.count, configState.currentConfiguration.count)
    }

    /// #5, appId present, no cached config, bundled config present, programmatic config present
    func testAppIdAndBundledConfigAndProgrammatic() {
        // setup
        putAppIdInPersistence()
        putProgrammaticConfigInPersistence()
        putConfigInManifest()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertHasProgrammaticConfig()
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
        XCTAssertNotNil(configState.currentConfiguration["bundled.config.key"])
    }

    /// #6, appId present, no cached config, bundled config present, no programmatic
    func testAppIdAndBundledConfig() {
        // setup
        putAppIdInPersistence()
        putConfigInManifest()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count, configState.currentConfiguration.count)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// #7, appId present, no cached config, no bundled config, programmatic config present
    func testAppIdAndProgrammatic() {
        // setup
        putAppIdInPersistence()
        putProgrammaticConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(programmaticConfig.count, configState.currentConfiguration.count)
        assertHasProgrammaticConfig()
    }

    /// #8, appId present, no cached config, no bundled config, no programmatic config
    func testOnlyAppId() {
        // setup
        putAppIdInPersistence()

        // test
        configState.loadInitialConfig()
        
        // verify
        XCTAssertTrue(configState.currentConfiguration.isEmpty)
    }

    /// #9, no appId, cached config present, bundled config present, programmatic config present
    func testCachedConfigAndBundledConfigAndProgrammaticConfig() {
        // verify
        putCachedConfigInPersistence()
        putConfigInManifest()
        putProgrammaticConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertHasProgrammaticConfig()
        assertHasBundledConfig()
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// #10, no appId present, cached config present, bundled config present, no programmatic config
    func testCachedConfigAndBundledConfig() {
        // verify
        putCachedConfigInPersistence()
        putConfigInManifest()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count, configState.currentConfiguration.count)
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
        assertHasBundledConfig()
    }

    /// #11, no appId, cached config present, no bundled config, programmatic config present
    func testCachedConfigAndProgrammatic() {
        // verify
        putCachedConfigInPersistence()
        putProgrammaticConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(programmaticConfig.count, configState.currentConfiguration.count)
        assertHasProgrammaticConfig()
    }

    /// #12, no appId, cached config present, no bundled config, no programmatic config
    func testCachedConfig() {
        // setup
        putCachedConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertTrue(configState.currentConfiguration.isEmpty)
    }

    /// #13, no appId, no cached config, bundled config present, programmatic config present
    func testBundledConfigAndProgrammaticConfig() {
        // setup
        putConfigInManifest()
        putProgrammaticConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count + programmaticConfig.count, configState.currentConfiguration.count)
        assertHasBundledConfig()
        assertHasProgrammaticConfig()
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// #14, no appId, no cached config, bundled config present, no programmatic config
    func testBundledConfig() {
        // setup
        putConfigInManifest()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(bundledConfig.count, configState.currentConfiguration.count)
        assertHasBundledConfig()
        XCTAssertTrue(configDownloader.calledLoadDefaultConfig)
    }

    /// #15, no appId, no cached config, no bundled config, programmatic config present
    func testProgrammaticConfig() {
        // setup
        putProgrammaticConfigInPersistence()

        // test
        configState.loadInitialConfig()

        // verify
        XCTAssertEqual(programmaticConfig.count, configState.currentConfiguration.count)
        assertHasProgrammaticConfig()
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
        configState.updateConfigWith(newConfig: expectedConfig)

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
        configState.updateConfigWith(newConfig: expectedConfig)
        configState.updateConfigWith(newConfig: expectedConfig1)

        // verify
        XCTAssertEqual(2, configState.currentConfiguration.count)
        XCTAssertEqual("overwrittenVal", configState.currentConfiguration["testKey"] as! String)
        XCTAssertEqual("newVal", configState.currentConfiguration["newKey"] as! String)
    }
    
    /// Test that programmatic config and updateConfigWith merge the existing configs together
    func testUpdateConfigNewConfigPersistedConfigPresent() {
        // setup
        putProgrammaticConfigInPersistence()
        let expectedConfig = ["programmaticKey": "programmaticVal"]

        // test
        configState.updateConfigWith(newConfig: expectedConfig)

        // verify
        XCTAssertEqual(2, configState.currentConfiguration.count)
        XCTAssertEqual("programmaticVal", configState.currentConfiguration["programmaticKey"] as! String)
        XCTAssertEqual("testVal", configState.currentConfiguration["testKey"] as! String)
        assertHasProgrammaticConfig()
    }

    // MARK: updateProgrammaticConfig tests

    /// tests that updating programmatic config updates current and programmatic config
    func testUpdateProgrammaticConfig() {
        // setup
        let expectedConfig = ["testKey": "testVal"]

        // test
        configState.updateProgrammaticConfig(updatedConfig: expectedConfig)

        // verify
        XCTAssertEqual(1, configState.currentConfiguration.count)
        XCTAssertEqual("testVal", configState.currentConfiguration["testKey"] as! String)
        XCTAssertEqual(1, configState.programmaticConfig.count)
        XCTAssertEqual("testVal", configState.programmaticConfig["testKey"]?.stringValue)
    }

    // MARK: updateConfigWith(appId) tests

    /// case 1: happy path, app id is valid and can be downloaded from the network
    func testUpdateConfigWithAppIdSimple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true

        configDownloader.configFromUrl = cachedConfig
        
        // test & verify
        configState.updateConfigWith(appId: "valid-app-id") { (config) in
            XCTAssertEqual(16, config?.count)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// case 2: network is down, but cached config exists
    func testUpdateConfigWithAppIdFailedRequestExistsInCache() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true
        let appId = "app-id-not-on-server"
        putCachedConfigInPersistence(appId: appId)

        // test
        configState.updateConfigWith(appId: appId) { (config) in
            XCTAssertEqual(16, config?.count)
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// case 3: network is down or app id is invalid, no cached config
    func testUpdateConfigWithAppIdInvalidId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.assertForOverFulfill = true
        let appId = "app-id-not-on-server"

        // test
        configState.updateConfigWith(appId: appId) { (config) in
            XCTAssertNil(config)
            expectation.fulfill()
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// case 4: can configure with multiple app ids
    func testUpdateConfigWithAppIdMultiple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        
        configDownloader.configFromUrl = cachedConfig
        
        // test
        configState.updateConfigWith(appId: "valid-app-id") { (config) in
            XCTAssertEqual(16, config?.count)
            expectation.fulfill()
            
            self.configState.updateConfigWith(appId: "newAppId") { (newConfig) in
                XCTAssertEqual(16, newConfig?.count)
                expectation.fulfill()
            }
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    /// case 5: valid config is preserved even when an invalid app id is passed
    func testUpdateConfigWithValidThenInvalidId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader closure should be invoked")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true
        
        configDownloader.configFromUrl = cachedConfig
        
        // test
        configState.updateConfigWith(appId: "valid-app-id") { (config) in
            XCTAssertEqual(16, config?.count)
            self.configDownloader.configFromUrl = nil
            expectation.fulfill()
            
            self.configState.updateConfigWith(appId: "invalid-app-id") { (newConfig) in
                XCTAssertNil(newConfig)
                XCTAssertEqual(16, self.configState.currentConfiguration.count)
                expectation.fulfill()
            }
        }
        
        // verify
        wait(for: [expectation], timeout: 0.5)
    }

    // MARK: updateConfigWith(filePath)
    
    /// When an empty path is supplied we return false and don't update the current configuration
    func testUpdateConfigWithFilePathEmpty() {
        XCTAssertFalse(configState.updateConfigWith(filePath: ""))
    }
    
    /// When the configuration downloader returns a nil config we properly update the current configuration
    func testUpdateConfigWithFilePathInvalidPath() {
        XCTAssertFalse(configState.updateConfigWith(filePath: "Invalid/Path/ADBMobile.json"))
    }
    
    /// When the configuration downloader returns a valid config we properly update the current configuration
    func testUpdateConfigWithPathSimple() {
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateConfigWith(filePath: "validPath"))
        XCTAssertEqual(16, configState.currentConfiguration.count)
    }
    
    /// Tests that when we have loaded a config from a file path, then we pass in an invalid path that the previous valid configuration is preserved
    func testUpdateConfigWithValidPathThenInvalid() {
        configDownloader.configFromPath = cachedConfig // simulate file found
        XCTAssertTrue(configState.updateConfigWith(filePath: "validPath"))
        XCTAssertEqual(16, configState.currentConfiguration.count)

        configDownloader.configFromPath = nil // simulate file not found
        XCTAssertFalse(configState.updateConfigWith(filePath: "Invalid/Path/ADBMobile.json"))
        XCTAssertEqual(16, configState.currentConfiguration.count)
    }

}
