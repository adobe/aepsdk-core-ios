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
@testable import AEPServices

class RulesDownloaderTests: XCTestCase {
    
    private static let zipTestFileName = "testRulesDownloader"
    private let cache = MockDiskCache()
    private var mockUnzipper = MockUnzipper()
    var rulesDownloader: RulesDownloader {
        get {
            return RulesDownloader(fileUnzipper: mockUnzipper)
        }
    }
    // The number of items in the rules.json for verifying in tests
    private let numOfRuleDictionaryItems = 23

    static var bundle: Bundle {
        return Bundle(for: self)
    }
    
    static var rulesUrl: URL? {
        return RulesDownloaderTests.bundle.url(forResource: RulesDownloaderTests.zipTestFileName, withExtension: ".zip")
    }
    
    override func setUp() {
        AEPServiceProvider.shared.cacheService = cache
    }
    
    func testLoadRulesFromCacheSimple() {
        let testKey = "testKey"
        let testValue: AnyCodable = "testValue"
        let testRulesDict = [testKey: testValue]
        let testRules: CachedRules = CachedRules(rules: testRulesDict, lastModified: nil, eTag: nil)
        let data = try! JSONEncoder().encode(testRules)
        let testEntry = CacheEntry(data: data, expiry: .never, metadata: nil)
        cache.mockCache[RulesDownloaderConstants.Keys.RULES_CACHE_PREFIX.rawValue + RulesDownloaderTests.rulesUrl!.absoluteString] = testEntry
        guard let rules = rulesDownloader.loadRulesFromCache(rulesUrl: RulesDownloaderTests.rulesUrl!.absoluteString) else {
            XCTFail("Rules not loaded from cache")
            return
        }
        XCTAssertEqual(testRules.rules[testKey]?.stringValue, rules[testKey] as? String)
    }
    
    func testLoadRulesFromCacheNotInCache() {
        XCTAssertNil(rulesDownloader.loadRulesFromCache(rulesUrl: RulesDownloaderTests.rulesUrl!.absoluteString))
    }

    func testLoadRulesFromUrlWithCacheNotModified() {
        AEPServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .notModified)
        let testKey = "testKey"
        let testValue: AnyCodable = "testValue"
        let testRulesDict = [testKey: testValue]
        let testRules: CachedRules = CachedRules(rules: testRulesDict, lastModified: nil, eTag: nil)
        let data = try! JSONEncoder().encode(testRules)
        let testEntry = CacheEntry(data: data, expiry: .never, metadata: nil)
        cache.mockCache[RulesDownloaderConstants.Keys.RULES_CACHE_PREFIX.rawValue + RulesDownloaderTests.rulesUrl!.absoluteString] = testEntry
        let expectation = XCTestExpectation(description: "RulesDownloader invokes callback with cached rules")
        var rulesResult: [String: Any]? = nil
        
        rulesDownloader.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            rulesResult = loadedRules
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(testRules.rules[testKey]?.stringValue, rulesResult![testKey] as? String)
    }
    
    func testLoadRulesFromUrlUnzipFail() {
        AEPServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .success)
        rulesDownloader.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            XCTAssertNil(loadedRules)
        })
    }
    
    func testLoadRulesFromUrlSetCacheFail() {
        cache.shouldThrow = true
        mockUnzipper.unzippedResults = ["testResult"]
        AEPServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .success)
        rulesDownloader.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            
        })
    }
    
    // This serves as a functional test right now which uses the actual unzipping and temporary directory work
    func testLoadRulesFromUrlNoCache() {
        // Use the actual rules unzipper for integration testing purposes
        let rulesDownloaderReal = RulesDownloader(fileUnzipper: FileUnzipper())
        AEPServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(response: .success)
        let expectation = XCTestExpectation(description: "RulesDownloader invokes callback with rules")
        var rules: [String: Any]? = nil
        
        rulesDownloaderReal.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            rules = loadedRules
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(numOfRuleDictionaryItems, rules?.count)
    }
}
