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
@testable import AEPServices
import XCTest

class ConfigurationDownloaderTests: XCTestCase {
    let dataStore = NamedCollectionDataStore(name: ConfigurationConstants.DATA_STORE_NAME)
    let validAppId = "valid-app-id"
    let invalidAppId = "invalid-app-id"

    override func setUp() {
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override class func tearDown() {
        ServiceProvider.shared.reset()
    }

    /// Tests that we can load a bundled config from the bundle
    func testLoadConfigFromFilePathSimple() {
        // setup
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!

        // test
        let config = ConfigurationDownloader().loadConfigFrom(filePath: path)

        // verify
        XCTAssertEqual(18, config?.count)
    }

    /// Tests that no config is loaded when an invalid file path is given
    func testLoadConfigFromFilePathInvalid() {
        // test
        let config = ConfigurationDownloader().loadConfigFrom(filePath: "Invalid/path/ADBMobileConfig.json")

        // verify
        XCTAssertNil(config)
    }

    /// Stores a config into the cache then attempts to load from the cache
    func testLoadConfigFromCacheSimple() {
        // setup
        let appId = "test-app-id"
        let expectedConfig: [String: AnyCodable] = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
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
                                                    "rules.url": "https://link.to.rules/test.zip"]
        dataStore.setObject(key: "\(ConfigurationConstants.DataStoreKeys.CONFIG_CACHE_PREFIX)\(appId)", value: CachedConfiguration(cacheable: expectedConfig, lastModified: "test-last-modified", eTag: "test-etag"))

        // test
        let cachedConfig = ConfigurationDownloader().loadConfigFromCache(appId: appId, dataStore: dataStore)

        // verify
        XCTAssertEqual(14, cachedConfig?.count)
    }

    /// Ensures that different appId's do not load other appId's cached configuration
    func testLoadConfigFromCacheInvalid() {
        // setup
        let appId = "test-app-id"
        let invalidConfig = "not-a-valid-config"
        dataStore.set(key: "\(ConfigurationConstants.DataStoreKeys.CONFIG_CACHE_PREFIX)\(appId)", value: invalidConfig)

        // test
        let cachedConfig = ConfigurationDownloader().loadConfigFromCache(appId: appId, dataStore: dataStore)

        // verify
        XCTAssertNil(cachedConfig)
    }

    /// Ensures that when the network service returns a valid response that the configuration is loaded and cached properly
    func testLoadConfigFromUrlSimple() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader invokes callback with config")
        expectation.assertForOverFulfill = true
        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .success)
        let expectedConfigSize = 16

        var remoteConfig: [String: Any]?

        // test
        ConfigurationDownloader().loadConfigFromUrl(appId: validAppId, dataStore: dataStore, completion: { loadedConfig in
            remoteConfig = loadedConfig
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(expectedConfigSize, remoteConfig?.count)
        XCTAssertEqual(expectedConfigSize, ConfigurationDownloader().loadConfigFromCache(appId: validAppId, dataStore: dataStore)?.count) // ensure downloaded config is cached
    }

    /// When the network service returns an invalid response that we do not return a config
    func testLoadConfigFromUrlInvalid() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader invokes callback with config")
        expectation.assertForOverFulfill = true
        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .error)

        var remoteConfig: [String: Any]?

        // test
        ConfigurationDownloader().loadConfigFromUrl(appId: validAppId, dataStore: dataStore, completion: { loadedConfig in
            remoteConfig = loadedConfig
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertNil(remoteConfig)
    }

    /// Ensures that when the network service returns a 304 response that the cached config is used
    func testLoadConfigFromUrlNotModified() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader invokes callback with config")
        expectation.assertForOverFulfill = true
        ServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(responseType: .notModified)

        let appId = "test-app-id"
        let expectedConfig: [String: AnyCodable] = ["experienceCloud.org": "3CE342C75100435B0A490D4C@AdobeOrg",
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
                                                    "rules.url": "https://link.to.rules/test.zip"]
        dataStore.setObject(key: "\(ConfigurationConstants.DataStoreKeys.CONFIG_CACHE_PREFIX)\(appId)", value: CachedConfiguration(cacheable: expectedConfig, lastModified: "test-last-modified", eTag: "test-etag"))

        var remoteConfig: [String: Any]?

        // test
        ConfigurationDownloader().loadConfigFromUrl(appId: appId, dataStore: dataStore, completion: { loadedConfig in
            remoteConfig = loadedConfig
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(expectedConfig.count, remoteConfig?.count)
    }

    /// Tests that a nil configuration is returned when an empty appId is passed
    func testLoadConfigFromUrlEmptyAppId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader invokes callback with config")
        expectation.assertForOverFulfill = true
        let appId = ""

        var remoteConfig: [String: Any]?

        // test
        ConfigurationDownloader().loadConfigFromUrl(appId: appId, dataStore: dataStore, completion: { loadedConfig in
            remoteConfig = loadedConfig
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertNil(remoteConfig)
    }

    /// Ensures that when a config is present in the manifest it can be loaded.
    func testLoadDefaultBundledConfig() {
        // setup
        ServiceProvider.shared.systemInfoService = ApplicationSystemInfoService(bundle: Bundle(for: type(of: self)))

        // test
        let config = ConfigurationDownloader().loadDefaultConfigFromManifest()

        // verify
        XCTAssertEqual(18, config?.count)
    }
}
