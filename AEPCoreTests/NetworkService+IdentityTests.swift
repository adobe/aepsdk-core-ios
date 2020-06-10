//
//  NetworkService+IdentityTests.swift
//  AEPCoreTests
//
//  Created by Nick Porter on 6/10/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import XCTest
@testable import AEPCore

class NetworkService_IdentityTests: XCTestCase {
    
    var mockNetworkService: MockNetworkServiceOverrider!
    
    override func setUp() {
        mockNetworkService = MockNetworkServiceOverrider()
        AEPServiceProvider.shared.networkService = mockNetworkService
    }
    
    // MARK: NetworkRequest(orgId, mid, experienceCloudServer) tests
    
    /// Tests that the URL and network request are configured correctly
    func testOptOutNetworkRequest() {
        // setup
        let orgId = "test-org-id"
        let mid = "test-mid"
        let experienceCloudServer = "identityServer.com"
        // https://identityServer.com/demoptout.jpg?d_orgid=test-org-id&d_mid=test-mid
        let expectedUrl = "https://\(experienceCloudServer)/demoptout.jpg?d_orgid=\(orgId)&d_mid=\(mid)"
        
        // test
        guard let networkRequest = NetworkRequest(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer) else {
            XCTFail("Network request was nil")
            return
        }
        
        // verify
        print(networkRequest.url)
        XCTAssertEqual(expectedUrl, networkRequest.url.absoluteString)
        XCTAssertEqual(HttpMethod.get, networkRequest.httpMethod)
        XCTAssertTrue(networkRequest.connectPayload.isEmpty)
        XCTAssertEqual(2, networkRequest.httpHeaders.count)
        XCTAssertEqual(5, networkRequest.connectTimeout)
        XCTAssertEqual(5, networkRequest.readTimeout)
    }
    
    // MARK: NetworkService.sendOptOutRequest(...) tests
    
    /// Tests that sending an opt-out request invokes the correct functions on the network service
    func testSendOptOutRequestSimple() {
        // setup
        let orgId = "test-org-id"
        let mid = "test-mid"
        let experienceCloudServer = "identityServer.com"
        
        guard let networkRequest = NetworkRequest(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer) else {
            XCTFail("Network request was nil")
            return
        }
        
        // test
        AEPServiceProvider.shared.networkService.sendOptOutRequest(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer)
        
        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        XCTAssertEqual(networkRequest.url, mockNetworkService.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNil(mockNetworkService.connectAsyncCalledWithCompletionHandler)
    }

}
