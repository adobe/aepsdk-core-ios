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
    private let rulesDownloader = RulesDownloader(fileUnzipper: FileUnzipper())

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
    
    func testLoadRulesFromUrlNoCache() {
        AEPServiceProvider.shared.networkService = MockRulesDownloaderNetworkService(shouldReturnValidResponse: true)
        let expectation = XCTestExpectation(description: "RulesDownloader invokes callback with rules")
        var rules: [String: Any]? = nil
        
        rulesDownloader.loadRulesFromUrl(rulesUrl: RulesDownloaderTests.rulesUrl!, completion: { loadedRules in
            rules = loadedRules
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotNil(rules)
    }
}

class MockUnzipper: Unzipper {
    
    var shouldSucceed: Bool = false
    var unzippedData: Data? = nil
    func unzipItem(at sourceURL: URL, to destinationURL: URL) -> Bool {
        if shouldSucceed {
            if let _ = try? unzippedData?.write(to: destinationURL) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}

class MockDiskCache: CacheService {
    
    var mockCache: [String: CacheEntry] = [:]
    
    enum MockDiskCacheError: Error {
        case setFailure
    }
    
    var shouldThrow: Bool = false
    func set(cacheName: String, key: String, entry: CacheEntry) throws {
        if shouldThrow {
            throw MockDiskCacheError.setFailure
        }
        mockCache[key] = entry
    }
    
    func get(cacheName: String, key: String) -> CacheEntry? {
        return mockCache[key]
    }
    
    func remove(cacheName: String, key: String) throws {
        
    }
}

struct MockRulesDownloaderNetworkService: NetworkService {
    var shouldReturnValidResponse: Bool
    
    let expectedData = try? Data(contentsOf: RulesDownloaderTests.rulesUrl!)
    
    let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
    let invalidResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
    
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        if shouldReturnValidResponse {
            let httpConnection = HttpConnection(data: expectedData, response: validResponse, error: nil)
            completionHandler!(httpConnection)
        } else {
            let httpConnection = HttpConnection(data: nil, response: invalidResponse, error: NetworkServiceError.invalidUrl)
            completionHandler!(httpConnection)
        }
    }
}
