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

@testable import AEPIdentity

class URL_IdentityTests: XCTestCase {
    // MARK: URL(experienceCloudServer, orgId, identityProperties, dpids) tests

    /// Tests that the Identity hit url is constructed properly when all properties are nil
    func testIdentityHitURLSimple() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: nil, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], addConsentFlag: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that one custom id is encoded properly into the URL
    func testIdentityHitURLOneCustomId() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid_ic=DSID_20915%01test_ad_id%011"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let customIds = [CustomIdentity(origin: "d_cid_ic", type: "DSID_20915", identifier: "test_ad_id", authenticationState: .authenticated)]
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: customIds, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], addConsentFlag: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that one custom id is encoded properly into the URL and is not double encoded
    func testIdentityHitURLOneCustomIdWithSpecialCharacter() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid_ic=DSID_20915%01test_%25_id%011"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let customIds = [CustomIdentity(origin: "d_cid_ic", type: "DSID_20915", identifier: "test_%_id", authenticationState: .authenticated)]
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: customIds, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], addConsentFlag: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }


    /// Tests that multiple custom ids are encoded into the URL correctly
    func testIdentityHitURLMultipleCustomIds() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid_ic=DSID_20915%01test_ad_id%011&d_cid_ic=DSID_20915_2%01test_ad_id_2%012"
        let experienceCloudServer = "dpm.demdex.net"
        let orgId = "testOrg@AdobeOrg"
        let customIds = [CustomIdentity(origin: "d_cid_ic", type: "DSID_20915", identifier: "test_ad_id", authenticationState: .authenticated),
                         CustomIdentity(origin: "d_cid_ic_2", type: "DSID_20915_2", identifier: "test_ad_id_2", authenticationState: .loggedOut)]
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: customIds, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], addConsentFlag: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that one dpid is encoded into the URL correctly
    func testIdentityHitURLOneDpid() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid=20920%01testPushId"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let dpids = ["20920": "testPushId"]
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: dpids, addConsentFlag: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that one dpid is encoded into the URL correctly and is not double encoded
    func testIdentityHitURLOneDpidWithSpecialCharacter() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_cid=20920%01testPush%25Id"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let dpids = ["20920": "testPush%Id"]
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: dpids, addConsentFlag: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that multiple dpids are encoded into the URL correctly
    func testIdentityHitURLMultipleDpids() {
        // setup
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let dpids = ["20920": "testPushId", "20920_2": "testPushId_2"]
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: nil, pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: dpids, addConsentFlag: false)

        // verify
        XCTAssertTrue(url?.absoluteString.contains("&d_cid=20920%01testPushId") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("&d_cid=20920_2%01testPushId_2") ?? false)
    }

    func testIdentityHitURLWithECIDBlobHint() {
        // setup
        let ecid = ECID()
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&d_mid=\(ecid.ecidString)&d_blob=testBlob&dcs_region=testHint"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(ecid: ecid, advertisingIdentifier: nil, pushIdentifier: nil, blob: "testBlob", locationHint: "testHint", customerIds: [], lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], addConsentFlag: false)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that when the ad id is empty and it is changed that we send a 0 for idfa consent
    func testIdentityHitURLWithChangedAdIEmpty() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&device_consent=0&d_consent_ic=DSID_20915"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: "", pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: nil, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], addConsentFlag: true)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    /// Tests that when the ad id is not empty and it is changed that we send a 1 for idfa consent
    func testIdentityHitURLWithChangedAdIdNotEmpty() {
        // setup
        let expectedUrl = "https://dpm.demdex.net/id?d_rtbd=json&d_ver=2&d_orgid=testOrg@AdobeOrg&device_consent=1"
        let orgId = "testOrg@AdobeOrg"
        let experienceCloudServer = "dpm.demdex.net"
        let properties = IdentityProperties(ecid: nil, advertisingIdentifier: "test-ad-id", pushIdentifier: nil, blob: nil, locationHint: nil, customerIds: nil, lastSync: nil, ttl: 5, privacyStatus: .optedIn)

        // test
        let url = URL.buildIdentityHitURL(experienceCloudServer: experienceCloudServer, orgId: orgId, identityProperties: properties, dpids: [:], addConsentFlag: true)

        // verify
        XCTAssertEqual(expectedUrl, url?.absoluteString)
    }

    // MARK: URL(orgId, ecid, experienceCloudServer) tests

    /// Tests that the URL is built correctly
    func testOptOutURL() {
        // setup
        let orgId = "test-org-id"
        let ecid = ECID()
        let experienceCloudServer = "identityServer.com"
        let expectedUrl = "https://\(experienceCloudServer)/demoptout.jpg?d_orgid=\(orgId)&d_mid=\(ecid.ecidString)"

        // test
        guard let url = URL.buildOptOutURL(orgId: orgId, ecid: ecid, experienceCloudServer: experienceCloudServer) else {
            XCTFail("Network request was nil")
            return
        }

        // verify
        XCTAssertEqual(expectedUrl, url.absoluteString)
    }
}
