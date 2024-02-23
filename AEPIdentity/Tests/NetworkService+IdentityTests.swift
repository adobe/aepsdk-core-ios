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

@testable import AEPIdentity
import AEPServices
import AEPServicesMocks
import AEPTestUtils
import XCTest

class NetworkService_IdentityTests: XCTestCase {
    var mockNetworkService: MockNetworkService!

    override func setUp() {
        mockNetworkService = MockNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
    }

    // MARK: NetworkService.sendOptOutRequest(...) tests

    /// Tests that sending an opt-out request invokes the correct functions on the network service
    func testSendOptOutRequestSimple() {
        // setup
        let orgId = "test-org-id"
        let ecid = ECID()
        let experienceCloudServer = "identityServer.com"

        guard let url = URL.buildOptOutURL(orgId: orgId, ecid: ecid, experienceCloudServer: experienceCloudServer) else {
            XCTFail("Network request was nil")
            return
        }

        // test
        ServiceProvider.shared.networkService.sendOptOutRequest(orgId: orgId, ecid: ecid, experienceCloudServer: experienceCloudServer)

        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        XCTAssertEqual(url, mockNetworkService.getNetworkRequests().first?.url)
    }
}
