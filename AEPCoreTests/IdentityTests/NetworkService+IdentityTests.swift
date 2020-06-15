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
    
    // MARK: URL(experienceCloudServer, orgId, identityProperties, dpids) tests
    func testIdentityHitURL() {
        // setup
        
    }
    
    // MARK: URL(orgId, mid, experienceCloudServer) tests
    
    /// Tests that the URL is built correctly
    func testOptOutURL() {
        // setup
        let orgId = "test-org-id"
        let mid = MID()
        let experienceCloudServer = "identityServer.com"
        // https://identityServer.com/demoptout.jpg?d_orgid=test-org-id&d_mid=test-mid
        let expectedUrl = "https://\(experienceCloudServer)/demoptout.jpg?d_orgid=\(orgId)&d_mid=\(mid.midString)"
        
        // test
        guard let url = URL(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer) else {
            XCTFail("Network request was nil")
            return
        }
        
        // verify
        XCTAssertEqual(expectedUrl, url.absoluteString)
    }
    
    // MARK: NetworkService.sendOptOutRequest(...) tests
    
    /// Tests that sending an opt-out request invokes the correct functions on the network service
    func testSendOptOutRequestSimple() {
        // setup
        let orgId = "test-org-id"
        let mid = MID()
        let experienceCloudServer = "identityServer.com"
        
        guard let url = URL(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer) else {
            XCTFail("Network request was nil")
            return
        }
        
        // test
        AEPServiceProvider.shared.networkService.sendOptOutRequest(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer)
        
        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        XCTAssertEqual(url, mockNetworkService.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNil(mockNetworkService.connectAsyncCalledWithCompletionHandler)
    }

}
