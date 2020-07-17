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
@testable import AEPServices

let testBody = "{\"test\": \"json\"\"}"
let jsonData = testBody.data(using: .utf8)
var mockSession : MockURLSession = MockURLSession(data: jsonData, urlResponse: nil, error: nil)

class StubACPNetworkService : AEPNetworkService {
    
    override func createURLSession(networkRequest: NetworkRequest) -> URLSession {
        return mockSession
    }
}

class NetworkServiceTests: XCTestCase {
    private var networkStub = StubACPNetworkService()
    private var systemInfoService: MockSystemInfoService?
    override func setUp() {
        self.systemInfoService = MockSystemInfoService()
        AEPServiceProvider.shared.systemInfoService = self.systemInfoService!
    }
    
    override func tearDown() {
        // reset the mock session after previous test
        mockSession = MockURLSession(data: jsonData, urlResponse: nil, error: nil)
    }
    
    // MARK: NetworkService tests

    func testConnectAsync_returnsError_whenIncompleteUrl() {
        let defaultNetworkService = AEPNetworkService()
        let expectation = XCTestExpectation(description: "Completion handler called")

        let testUrl = URL(string: "https://")!
        let testBody = "test body"
        let networkRequest = NetworkRequest(url: testUrl, httpMethod: HttpMethod.post, connectPayload: testBody, httpHeaders: ["Accept": "text/html"])
        defaultNetworkService.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            XCTAssertEqual("Could not connect to the server.", connection.error?.localizedDescription)
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectAsync_returnsError_whenInsecureUrl() {
        let defaultNetworkService = AEPNetworkService()
        let expectation = XCTestExpectation(description: "Completion handler called")
        let testUrl = URL(string: "http://www.adobe.com")!
        let networkRequest = NetworkRequest(url: testUrl)
        // test&verify
        defaultNetworkService.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            guard let resultError = connection.error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            guard case NetworkServiceError.invalidUrl = resultError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectAsync_returnsError_whenInvalidUrl() {
        let defaultNetworkService = AEPNetworkService()
        let expectation = XCTestExpectation(description: "Completion handler called")
        let testUrl = URL(string: "invalid.url")!
        let networkRequest = NetworkRequest(url: testUrl)
        // test&verify
        defaultNetworkService.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            guard let resultError = connection.error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            guard case NetworkServiceError.invalidUrl = resultError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectAsync_initiatesConnection_whenValidNetworkRequest() {
        let mockUserAgent = "mock-user-agent"
        let mockLocaleName = "mock-locale-name"
        self.systemInfoService?.defaultUserAgent = mockUserAgent
        self.systemInfoService?.activeLocaleName = mockLocaleName
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        let testUrl = URL(string: "https://test.com")!
        let networkRequest = NetworkRequest(url: testUrl, httpMethod: HttpMethod.post, connectPayload: testBody, httpHeaders: ["Accept": "text/html"], connectTimeout: 2.0, readTimeout: 3.0)
        networkStub.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertEqual(jsonData, connection.data)
            XCTAssertNil(connection.response)
            XCTAssertNil(connection.error)
            
            expectation.fulfill()
        })
        
        // verify
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockSession.dataTaskWithCompletionHandlerCalled)
        XCTAssertEqual(URLRequest.CachePolicy.reloadIgnoringCacheData, mockSession.calledWithUrlRequest?.cachePolicy)
        XCTAssertEqual(jsonData, mockSession.calledWithUrlRequest?.httpBody)
        XCTAssertEqual(["Accept": "text/html", "User-Agent": mockUserAgent, "Accept-Language": mockLocaleName], mockSession.calledWithUrlRequest?.allHTTPHeaderFields)
        XCTAssertEqual("POST", mockSession.calledWithUrlRequest?.httpMethod)
        XCTAssertEqual(testUrl, mockSession.calledWithUrlRequest?.url)
    }
    
    func testConnectAsync_returnsTimeoutError_whenConnectionTimesOut() {
        let defaultNetworkService = AEPNetworkService()
        let expectation = XCTestExpectation(description: "Completion handler called")

        let testUrl = URL(string: "https://example.com:81")!
        let networkRequest = NetworkRequest(url: testUrl, httpMethod: HttpMethod.post, connectPayload: testBody, httpHeaders: ["Accept": "text/html"], connectTimeout: 0.25, readTimeout: 0.25)
        defaultNetworkService.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            XCTAssertEqual("The request timed out.", connection.error?.localizedDescription)
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 0.6)
    }
    
    func testConnectAsync_initiatesConnection_whenValidUrl_noCompletionHandler() {
        let testUrl = URL(string: "https://test.com")!
        let networkRequest = NetworkRequest(url: testUrl)
        
        // test
        networkStub.connectAsync(networkRequest: networkRequest)
        
        // verify
        XCTAssertTrue(mockSession.dataTaskWithCompletionHandlerCalled)
    }
    
    // MARK: NetworkService overrider tests
    
    func testOverridenConnectAsync_called_whenMultipleRequests() {
        let testNetworkService = MockNetworkServiceOverrider();
        AEPServiceProvider.shared.networkService = testNetworkService
        
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!, httpMethod: HttpMethod.post, connectPayload: "test body", httpHeaders: ["Accept": "text/html"], connectTimeout: 2.0, readTimeout: 3.0)
        let request2 = NetworkRequest(url: URL(string: "https://test2.com")!, httpMethod: HttpMethod.get, httpHeaders: ["Accept": "text/html"])
        let request3 = NetworkRequest(url: URL(string: "https://test3.com")!)
        let completionHandler : ((HttpConnection) -> Void) = { connection in
           print("say hi")
        }
    
        // test&verify
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: request1, completionHandler: completionHandler)
        XCTAssertEqual(request1.url, testNetworkService.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNotNil(testNetworkService.connectAsyncCalledWithCompletionHandler)
        testNetworkService.reset()
        
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: request2, completionHandler: nil)
        XCTAssertEqual(request2.url, testNetworkService.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNil(testNetworkService.connectAsyncCalledWithCompletionHandler)
        testNetworkService.reset()
        
        testNetworkService.connectAsync(networkRequest: request3)
        XCTAssertEqual(request3.url, testNetworkService.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNil(testNetworkService.connectAsyncCalledWithCompletionHandler)
    }

    func testOverridenConnectAsync_addsDefaultHeaders_whenCalledWithHeaders() {
        let testNetworkService = MockNetworkServiceOverrider()
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!, httpMethod: HttpMethod.post, connectPayload: "test body", httpHeaders: ["Accept": "text/html"], connectTimeout: 2.0, readTimeout: 3.0)
        
        // test&verify
        testNetworkService.connectAsync(networkRequest: request1)
        XCTAssertTrue(testNetworkService.connectAsyncCalled)
        XCTAssertEqual(3, testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
        XCTAssertNotNil(testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept"])
        XCTAssertNotNil(testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders["User-Agent"])
        XCTAssertNotNil(testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept-Language"])
    }
    
    func testOverridenConnectAsync_addsDefaultHeaders_whenCalledWithoutHeaders() {
        let testNetworkService = MockNetworkServiceOverrider()
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!)
        
        // test&verify
        testNetworkService.connectAsync(networkRequest: request1)
        XCTAssertTrue(testNetworkService.connectAsyncCalled)
        XCTAssertEqual(2, testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
        XCTAssertNotNil(testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders["User-Agent"])
        XCTAssertNotNil(testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept-Language"])
    }
    
    func testOverridenConnectAsync_doesNotOverrideHeaders_whenCalledWithDefaultHeaders() {
        let testNetworkService = MockNetworkServiceOverrider()
        AEPServiceProvider.shared.networkService = testNetworkService
        
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!, httpMethod: HttpMethod.get, httpHeaders: ["User-Agent": "test", "Accept-Language": "ro-RO"], connectTimeout: 2.0, readTimeout: 3.0)
        
        // test&verify
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: request1, completionHandler: nil)
        XCTAssertTrue(testNetworkService.connectAsyncCalled)
        XCTAssertEqual(2, testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
        XCTAssertEqual("test", testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders["User-Agent"])
        XCTAssertEqual("ro-RO", testNetworkService.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept-Language"])
    }
    
    func testEnableOverride_work_whenCalledWithMultipleOverriders() {
        let testNetworkServiceOverrider1 = MockNetworkServiceOverrider()
        let testNetworkServiceOverrider2 = MockNetworkServiceOverrider()
        let testNetworkServiceOverrider3 = MockNetworkServiceOverrider()
        
        // test&verify
        // set first overrider
        AEPServiceProvider.shared.networkService = testNetworkServiceOverrider1
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!), completionHandler: nil)
        XCTAssertTrue(testNetworkServiceOverrider1.connectAsyncCalled)
        testNetworkServiceOverrider1.reset()
        
        // set second overrider, the first one should not be called anymore
        AEPServiceProvider.shared.networkService = testNetworkServiceOverrider2
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test12.com")!), completionHandler: nil)
        XCTAssertFalse(testNetworkServiceOverrider1.connectAsyncCalled)
        XCTAssertTrue(testNetworkServiceOverrider2.connectAsyncCalled)
        testNetworkServiceOverrider1.reset()
        testNetworkServiceOverrider2.reset()
        
        // set third overrider, the other two should not be called anymore
        AEPServiceProvider.shared.networkService = testNetworkServiceOverrider3
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test123.com")!), completionHandler: nil)
        XCTAssertFalse(testNetworkServiceOverrider1.connectAsyncCalled)
        XCTAssertFalse(testNetworkServiceOverrider2.connectAsyncCalled)
        XCTAssertTrue(testNetworkServiceOverrider3.connectAsyncCalled)
    }
}
