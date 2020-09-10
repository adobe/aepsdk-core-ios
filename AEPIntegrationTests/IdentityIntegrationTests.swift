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
import AEPIdentity
import AEPLifecycle
import AEPSignal

class IdentityIntegrationTests: XCTestCase {

    override func setUp() {
        UserDefaults.clear()
        FileManager.default.clearCache()
        ServiceProvider.shared.reset()
        EventHub.reset()
    }

    func initExtensionsAndWait() {
        let initExpection = XCTestExpectation(description: "init extensions")
        MobileCore.setLogLevel(level: .trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
            initExpection.fulfill()
        }
        wait(for: [initExpection], timeout: 0.5)
    }

    func testSyncIdentifiers() {
        initExtensionsAndWait()

        let requestExpection = XCTestExpectation(description: "syncIdentifiers request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%2501value1%25010") {
                XCTAssertTrue(request.url.absoluteString.contains("https://test.com/id"))
                XCTAssertTrue(request.url.absoluteString.contains("d_orgid=orgid"))
                requestExpection.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpection], timeout: 1)
    }

    func testOptedout() {
        initExtensionsAndWait()

        let requestExpection = XCTestExpectation(description: "expect no syncIdentifiers request")
        requestExpection.isInverted = true
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%2501value1%25010") {
                requestExpection.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedout"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpection], timeout: 1)
    }

    func testGetUrlVariables() {
        initExtensionsAndWait()

        let variablesExpection = XCTestExpectation(description: "getUrlVariables callback")

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getUrlVariables { variables, _ in
            XCTAssertTrue(variables?.contains("TS") ?? false)
            XCTAssertTrue(variables?.contains("MCMID") ?? false)
            XCTAssertTrue(variables?.contains("MCORGID") ?? false)
            variablesExpection.fulfill()
        }

        wait(for: [variablesExpection], timeout: 1)
    }

    func testAppendTo() {
        initExtensionsAndWait()

        let urlExpection = XCTestExpectation(description: "appendTo callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.appendTo(url: URL(string: "https://adobe.com")) { (url, _) in

            XCTAssertTrue(url?.absoluteString.contains("TS") ?? false)
            XCTAssertTrue(url?.absoluteString.contains("MCMID") ?? false)
            XCTAssertTrue(url?.absoluteString.contains("MCORGID") ?? false)
            urlExpection.fulfill()
        }

        wait(for: [urlExpection], timeout: 1)
    }

    func testGetExperienceCloudId() {
        initExtensionsAndWait()

        let urlExpection = XCTestExpectation(description: "getExperienceCloudId callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getExperienceCloudId { ecid in
            XCTAssertFalse(ecid!.isEmpty)
            urlExpection.fulfill()
        }
        wait(for: [urlExpection], timeout: 1)
    }

    func testGetSdkIdentities() {
        initExtensionsAndWait()

        let urlExpection = XCTestExpectation(description: "getSdkIdentities callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setAdvertisingIdentifier(adId: "adid")
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])
        MobileCore.getSdkIdentities { identityString, _ in
            XCTAssertTrue(identityString?.contains("DSID_20915") ?? false)
            XCTAssertTrue(identityString?.contains("id1") ?? false)
            XCTAssertTrue(identityString?.contains("imsOrgID") ?? false)
            urlExpection.fulfill()
        }
        wait(for: [urlExpection], timeout: 1)
    }

    func testSetPushIdentifier() {
        initExtensionsAndWait()

        let requestExpection = XCTestExpectation(description: "push identifier sync request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("20920") {
                XCTAssertTrue(request.url.absoluteString.contains("d_cid=20920%25013935313632353862363233306166646439336366306364303762386464383435"))
                requestExpection.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setPushIdentifier(deviceToken: "9516258b6230afdd93cf0cd07b8dd845".data(using: .utf8))

        wait(for: [requestExpection], timeout: 1)
    }

    func testSetAdvertisingIdentifier() {
        initExtensionsAndWait()

        let requestExpection = XCTestExpectation(description: "advertising identifier sync request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("20915") {
                XCTAssertTrue(request.url.absoluteString.contains("d_cid_ic=DSID_20915%2501adid%25011"))
                requestExpection.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setAdvertisingIdentifier(adId: "adid")
        wait(for: [requestExpection], timeout: 1)
    }

}
