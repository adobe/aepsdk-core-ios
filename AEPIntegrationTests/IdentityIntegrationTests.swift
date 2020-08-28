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
import AEPServices
import AEPIdentity
import AEPLifecycle
import AEPSignal

class IdentityIntegrationTests: XCTestCase {

    override func setUp() {
        UserDefaults.clear()
        EventHub.reset()
    }

    override func tearDown() {
    }

    func initExtensionsAndWait() {
        let initExpection = XCTestExpectation()
        MobileCore.setLogLevel(level: .trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
            initExpection.fulfill()
        }
        wait(for: [initExpection], timeout: 0.5)
    }

    func testIdentity() {
        initExtensionsAndWait()

        let requestExpection = XCTestExpectation()
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.resolver = { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%2501value1%25010") {
                XCTAssertTrue(request.url.absoluteString.contains("https://test.com/id"))
                XCTAssertTrue(request.url.absoluteString.contains("d_orgid=orgid"))
                requestExpection.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.lifecycleStart(additionalContextData: ["key": "value"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpection], timeout: 1)
    }

    func testIdentityOptout() {
        initExtensionsAndWait()

        let requestExpection = XCTestExpectation()
        requestExpection.isInverted = true
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.resolver = { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%2501value1%25010") {
                requestExpection.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedout"])
        MobileCore.lifecycleStart(additionalContextData: ["key": "value"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpection], timeout: 1)
    }

    func testIdentityOptout1() {
        initExtensionsAndWait()

        let ecidExpection = XCTestExpectation()

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getExperienceCloudId { ecid in
            XCTAssertTrue(!ecid!.isEmpty)
            ecidExpection.fulfill()
        }

        wait(for: [ecidExpection], timeout: 1)
    }

    func testIdentityOptout2() {
        initExtensionsAndWait()

        let variablesExpection = XCTestExpectation()

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.lifecycleStart(additionalContextData: ["key": "value"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])
        Identity.getUrlVariables { (_, _) in

            variablesExpection.fulfill()
        }

        wait(for: [variablesExpection], timeout: 1)
    }

    func testIdentityOptout3() {
        initExtensionsAndWait()

        let urlExpection = XCTestExpectation()

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.lifecycleStart(additionalContextData: ["key": "value"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])
        let url2 = URL(string: "https://adobe.com")
        let a = url2?.absoluteString

        Identity.appendTo(url: URL(string: "https://adobe.com")) { (url, _) in

            let c = url?.absoluteString
            urlExpection.fulfill()
        }

        wait(for: [urlExpection], timeout: 1)
    }

}
