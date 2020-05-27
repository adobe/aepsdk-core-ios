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

class ConfigurationDownloaderTests: XCTestCase {

    let dataStore = NamedKeyValueStore(name: ConfigurationConstants.DATA_STORE_NAME)
    let validAppId = "valid-app-id"
    let invalidAppId = "invalid-app-id"
    
    override func setUp() {
        AEPServiceProvider.shared.networkService = AEPNetworkService()
        AEPServiceProvider.shared.systemInfoService = ApplicationSystemInfoService()
        dataStore.removeAll()
    }
    
    /// Tests that we can load a bundled config from the bundle
    func testLoadConfigFromFilePathSimple() {
        // setup
        let path = Bundle(for: type(of: self)).path(forResource: "ADBMobileConfig", ofType: "json")!

        // test
        let config = ConfigurationDownloader().loadConfigFrom(filePath: path)

        // verify
        XCTAssertEqual(16, config?.count)
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
        dataStore.setObject(key: "\(ConfigurationConstants.Keys.CONFIG_CACHE_PREFIX)\(appId)", value: CachedConfiguration(config: expectedConfig, lastModified: "test-last-modified", eTag: "test-etag"))

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
        dataStore.set(key: "\(ConfigurationConstants.Keys.CONFIG_CACHE_PREFIX)\(appId)", value: invalidConfig)

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
        AEPServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(shouldReturnValidResponse: true)
        let expectedConfigSize = 16

        var remoteConfig: [String: Any]? = nil
        
        // test
        ConfigurationDownloader().loadConfigFromUrl(appId: validAppId, dataStore: dataStore, completion: { (loadedConfig) in
            remoteConfig = loadedConfig
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(expectedConfigSize, remoteConfig?.count)
        XCTAssertEqual(expectedConfigSize, ConfigurationDownloader().loadConfigFromCache(appId: validAppId, dataStore: dataStore)?.count) // ensure downloaded config is cached
    }
    
    /// When the network service returns an invalid response that we do not return a config
    func testLoadConfigFromUrlInvalid() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader invokes callback with config")
        expectation.assertForOverFulfill = true
        AEPServiceProvider.shared.networkService = MockConfigurationDownloaderNetworkService(shouldReturnValidResponse: false)
        
        var remoteConfig: [String: Any]? = nil
        
        // test
        ConfigurationDownloader().loadConfigFromUrl(appId: validAppId, dataStore: dataStore, completion: { (loadedConfig) in
            remoteConfig = loadedConfig
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNil(remoteConfig)
    }
    
    /// Tests that a nil configuration is returned when an empty appId is passed
    func testLoadConfigFromUrlEmptyAppId() {
        // setup
        let expectation = XCTestExpectation(description: "ConfigurationDownloader invokes callback with config")
        expectation.assertForOverFulfill = true
        let appId = ""

        var remoteConfig: [String: Any]? = nil
        
        // test
        ConfigurationDownloader().loadConfigFromUrl(appId: appId, dataStore: dataStore, completion: { (loadedConfig) in
            remoteConfig = loadedConfig
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNil(remoteConfig)
    }
    
    /// Ensures that when a config is present in the manifest it can be loaded.
    func testLoadDefaultBundledConfig() {
        // setup
        AEPServiceProvider.shared.systemInfoService = ApplicationSystemInfoService(bundle: Bundle(for: type(of: self)))

        // test
        let config = ConfigurationDownloader().loadDefaultConfigFromManifest()

        // verify
        XCTAssertEqual(16, config?.count)
    }

}

private struct MockConfigurationDownloaderNetworkService: NetworkService {
    let shouldReturnValidResponse: Bool
    
    let expectedData = """
                        {
                          "target.timeout": 5,
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
                          "analytics.rsids": "mobile5adobe.store.sprint.demo",
                          "analytics.batchLimit": 3,
                          "property.id": "PR3dd64c475eb747339f0319676d56b1df",
                          "global.ssl": true,
                          "analytics.aamForwardingEnabled": true
                        }
                        """.data(using: .utf8)
    
    let expectedValidHttpUrlResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])
    let expectedInValidHttpUrlResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 500, httpVersion: nil, headerFields: [:])
    
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        if shouldReturnValidResponse {
            let httpConnection = HttpConnection(data: expectedData, response: expectedValidHttpUrlResponse, error: nil)
            completionHandler!(httpConnection)
        } else {
            let httpConnection = HttpConnection(data: nil, response: expectedInValidHttpUrlResponse, error: NetworkServiceError.invalidUrl)
            completionHandler!(httpConnection)
        }
    }
    
}
