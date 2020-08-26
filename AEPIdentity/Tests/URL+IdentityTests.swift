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
import XCTest

class URL_IdentityTests: XCTestCase {
    // MARK: URL(experienceCloudServer, orgId, identityProperties, dpids) tests

    /// Tests that the Identity hit url is constructed properly when all properties are nil
    func testIdentityHitURLSimple() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: nil, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], adIdChanged: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that one custom id is encoded properly into the URL
    func testIdentityHitURLOneCustomId() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid_ic=DSID_20915%2501test_ad_id%25011"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let customIds = [CustomIdentity(origin: "d_cid_ic", type: "DSID_20915", identifier: "test_ad_id", authenticationState: .authenticated)]
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: customIds, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], adIdChanged: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that multiple custom ids are encoded into the URL correctly
    func testIdentityHitURLMultipleCustomIds() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid_ic=DSID_20915%2501test_ad_id%25011&d_cid_ic=DSID_20915_2%2501test_ad_id_2%25012"
        let experienceCloudServer = "dpm.demdex.net"
        let orgId = "testOrg@AdobeOrg"
        let customIds = [CustomIdentity(origin: "d_cid_ic", type: "DSID_20915", identifier: "test_ad_id", authenticationState: .authenticated),
                         CustomIdentity(origin: "d_cid_ic_2", type: "DSID_20915_2", identifier: "test_ad_id_2", authenticationState: .loggedOut)]
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: customIds, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], adIdChanged: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that one dpid is encoded into the URL correctly
    func testIdentityHitURLOneDpid() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid=20920%2501testPushId"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let dpids = ["20920": "testPushId"]
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: dpids, adIdChanged: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that multiple dpids are encoded into the URL correctly
    func testIdentityHitURLMultipleDpids() {
        // setup
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let dpids = ["20920": "testPushId", "20920_2": "testPushId_2"]
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: dpids, adIdChanged: false)

        // verify
        XCTAssertTrue(url?.absoluteString.contains("&d_cid=20920%2501testPushId") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("&d_cid=20920_2%2501testPushId_2") ?? false)
    }

    func testIdentityHitURLWithMidBlobHint() {
        // setup
        let mid = MID()
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_mid=\(mid.midString)&d_blob=testBlob&dcs_region=testHint"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(mid: mid, advertisingIdentifier: nil, pushIdentifier: nil, blob: "testBlob", locationHint: "testHint", customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], adIdChanged: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that when the ad id is empty and it is changed that we send a 0 for idfa consent
    func testIdentityHitURLWithChangedAdIEmpty() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&device_consent=0"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: "", pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: nil, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], adIdChanged: true)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that when the ad id is not empty and it is changed that we send a 1 for idfa consent
    func testIdentityHitURLWithChangedAdIdNotEmpty() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&device_consent=1"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(mid: nil, advertisingIdentifier: "test-ad-id", pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: nil, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], adIdChanged: true)

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
        let expectedUrl = "https://\(experienceCloudServer)/demoptout.jpg?d_orgid=\(orgId)&d_mid=\(mid.midString)"

        // test
        guard let url = URL.buildOptOutURL(orgId: orgId, mid: mid, experienceCloudServer: experienceCloudServer) else {
            XCTFail("Network request was nil")
            return
        }

        // verify
        XCTAssertEqual(expectedUrl, url.absoluteString)
    }
}
