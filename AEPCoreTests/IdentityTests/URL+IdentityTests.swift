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

class URL_IdentityTests: XCTestCase {
    
    // MARK: URL(experienceCloudServer, orgId, identityProperties, dpids) tests
    
    func testIdentityHitURLSimple() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: nil, lastSync: nil, ttl: 5, privacyStatus: .optedIn)
        
        // test
        let url = URL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:])
        
        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }
    
    func testIdentityHitURLOneCustomId() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid_ic=DSID_20915%2501test_ad_id%25011"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let customIds = [CustomIdentity(origin: "d_cid_ic", type: "DSID_20915", identifier: "test_ad_id", authenticationState: .authenticated)]
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: customIds, lastSync: nil, ttl: 5, privacyStatus: .optedIn)
        
        // test
        let url = URL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:])
        
        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }
    
    func testIdentityHitURLOneDpid() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid=20920%2501testPushId"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let dpids = ["20920": "testPushId"]
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)
        
        // test
        let url = URL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: dpids)
        
        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }
    
    func testIdentityHitURLWithMidBlobHint() {
        // setup
        let mid = MID()
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_mid=\(mid.midString)&d_blob=testBlob&dcs_region=testHint"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(mid: mid, advertisingIdentifier: nil, pushIdentifier: nil, blob: "testBlob", locationHint: "testHint", customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)
        
        // test
        let url = URL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:])
        
        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
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
}
