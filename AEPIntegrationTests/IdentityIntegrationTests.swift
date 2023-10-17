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
@testable import AEPIdentity
@testable import AEPServicesMocks
import AEPLifecycle
import AEPSignal

@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
class IdentityIntegrationTests: XCTestCase {

    override func setUp() {
        NamedCollectionDataStore.clear()
    }

    override func tearDown() {
        unregisterExtensionsAndReset()
    }

    func unregisterExtensionsAndReset() {
        let unregisterExpectation = XCTestExpectation(description: "unregister extensions")
        unregisterExpectation.expectedFulfillmentCount = 3
        MobileCore.unregisterExtension(Identity.self) {
            unregisterExpectation.fulfill()
        }

        MobileCore.unregisterExtension(Signal.self) {
            unregisterExpectation.fulfill()
        }

        MobileCore.unregisterExtension(Lifecycle.self) {
            unregisterExpectation.fulfill()
        }

        wait(for: [unregisterExpectation], timeout: 3)
        EventHub.shared.shutdown()

        ServiceProvider.shared.reset()
        EventHub.reset()
    }

    func initExtensionsAndWait() {
        let initExpectation = XCTestExpectation(description: "init extensions")
        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Signal.self]) {
            initExpectation.fulfill()
        }
        wait(for: [initExpectation], timeout: 1)
    }

    func extractECIDFrom(urlString: String) -> String? {
        var ecid: String?
        let regex = try! NSRegularExpression(pattern: "d_mid=(\\d{32})", options: .caseInsensitive)

        if let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) {
            ecid = String(urlString[Range(match.range(at: 1), in: urlString)!])
        }

        return ecid
    }

    func testSyncIdentifiers() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "syncIdentifiers request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%01value1%011") {
                XCTAssertTrue(request.url.absoluteString.contains("https://test.com/id"))
                XCTAssertTrue(request.url.absoluteString.contains("d_orgid=orgid"))
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"], authenticationState: .authenticated)

        wait(for: [requestExpectation], timeout: 1)
    }

    func testIdentitySendsForceSyncRequestOnEveryLaunch() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "syncIdentifiers request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        var extractedECID = ""

        mockNetworkService.mock { request in
            let urlString = request.url.absoluteString
            if urlString.contains("d_cid_ic=id1%01value1%011") {
                XCTAssertTrue(urlString.contains("https://test.com/id"))
                XCTAssertTrue(urlString.contains("d_orgid=orgid"))
                XCTAssertTrue(urlString.contains("d_mid="))
                extractedECID = self.extractECIDFrom(urlString: urlString) ?? "ecid-not-found"
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"], authenticationState: .authenticated)

        wait(for: [requestExpectation], timeout: 1)

        //Relaunch app
        unregisterExtensionsAndReset()
        initExtensionsAndWait()

        let secondLaunchRequestExpectation = XCTestExpectation(description: "syncIdentifiers request in new launch")
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            let urlString = request.url.absoluteString
            if urlString.contains("d_cid_ic=id1%01value1%011") {
                XCTAssertTrue(urlString.contains("https://test.com/id"))
                XCTAssertTrue(urlString.contains("d_orgid=orgid"))
                XCTAssertTrue(urlString.contains("d_mid=" + extractedECID))
                secondLaunchRequestExpectation.fulfill()
            }
            return nil
        }

        // we should get config shared state update from cache which would forceSync and sendHit
        wait(for: [secondLaunchRequestExpectation], timeout: 1)
    }


    func testOptedout() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "expect no syncIdentifiers request")
        requestExpectation.isInverted = true
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%01value1%010") {
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedout"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpectation], timeout: 2)
    }

    func testGetUrlVariables() {
        initExtensionsAndWait()

        let variablesExpectation = XCTestExpectation(description: "getUrlVariables callback")

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getUrlVariables { variables, _ in
            XCTAssertTrue(variables?.contains("TS") ?? false)
            XCTAssertTrue(variables?.contains("MCMID") ?? false)
            XCTAssertTrue(variables?.contains("MCORGID") ?? false)
            variablesExpectation.fulfill()
        }

        wait(for: [variablesExpectation], timeout: 1)
    }

    func testAppendTo() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "appendTo callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.appendTo(url: URL(string: "https://adobe.com")) { (url, _) in

            XCTAssertTrue(url?.absoluteString.contains("TS") ?? false)
            XCTAssertTrue(url?.absoluteString.contains("MCMID") ?? false)
            XCTAssertTrue(url?.absoluteString.contains("MCORGID") ?? false)
            urlExpectation.fulfill()
        }

        wait(for: [urlExpectation], timeout: 1)
    }

    func testGetExperienceCloudId() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "getExperienceCloudId callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getExperienceCloudId { ecid, error in
            XCTAssertFalse(ecid!.isEmpty)
            XCTAssertNil(error)
            urlExpectation.fulfill()
        }
        wait(for: [urlExpectation], timeout: 1)
    }

    func testGetExperienceCloudIdWithinPermissibleTimeOnInstall() {
        initExtensionsAndWait()

        let getECIDExpectation = XCTestExpectation(description: "getExperienceCloudId should return within 1 seconds when Configuration is available on Install")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getExperienceCloudId { ecid, error in
            XCTAssertFalse(ecid!.isEmpty)
            XCTAssertNil(error)
            getECIDExpectation.fulfill()
        }
        // getExperienceCloudId returns within 0.5 sec when config is bundled with the app. 
        // Increasing timeout to 1 sec to avoid race conditions
        wait(for: [getECIDExpectation], timeout: 1)
    }

    func testGetExperienceCloudIdWithinPermissibleTimeOnLaunch() {
        persistECIDInUserDefaults()
        initExtensionsAndWait()

        let getECIDExpectation = XCTestExpectation(description: "getExperienceCloudId should return within 0.5 seconds when ECID is cached on Launch")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getExperienceCloudId { ecid, error in
            XCTAssertFalse(ecid!.isEmpty)
            XCTAssertNil(error)
            getECIDExpectation.fulfill()
        }
        wait(for: [getECIDExpectation], timeout: 0.5)
    }

    func testGetExperienceCloudIdInvalidConfigThenValid() {
        MobileCore.updateConfigurationWith(configDict: ["invalid": "config"])
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "getExperienceCloudId callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getExperienceCloudId { ecid, error in
            XCTAssertFalse(ecid!.isEmpty)
            XCTAssertNil(error)
            urlExpectation.fulfill()
        }
        wait(for: [urlExpectation], timeout: 1)
    }

    func testGetSdkIdentities() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "getSdkIdentities callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setAdvertisingIdentifier("adid")
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])
        MobileCore.getSdkIdentities { identityString, error in
            XCTAssertTrue(identityString?.contains("DSID_20915") ?? false)
            XCTAssertTrue(identityString?.contains("id1") ?? false)
            XCTAssertTrue(identityString?.contains("imsOrgID") ?? false)
            urlExpectation.fulfill()
        }
        wait(for: [urlExpectation], timeout: 2)
    }

    func testGetIdentifiers() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "getSdkIdentities callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.syncIdentifier(identifierType: "type1", identifier: "id1", authenticationState: .authenticated)
        Identity.getIdentifiers { identifiers, error in
            XCTAssertNotNil(identifiers)
            XCTAssertEqual(1, identifiers?.count)
            let customId = identifiers?.first
            XCTAssertEqual("id1", customId?.identifier)
            XCTAssertEqual("type1", customId?.type)
            XCTAssertEqual(MobileVisitorAuthenticationState.authenticated, customId?.authenticationState)
            XCTAssertEqual("d_cid_ic", customId?.origin)
            XCTAssertNil(error)
            urlExpectation.fulfill()
        }
        wait(for: [urlExpectation], timeout: 2)
    }

    func testGetIdentifiers_returnsEmptyList_whenNoIds() {
        initExtensionsAndWait()

        let urlExpectation = XCTestExpectation(description: "getSdkIdentities callback")
        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.getIdentifiers { identifiers, error in
            XCTAssertNotNil(identifiers)
            XCTAssertEqual(true, identifiers?.isEmpty)
            XCTAssertNil(error)
            urlExpectation.fulfill()
        }
        wait(for: [urlExpectation], timeout: 2)
    }

    func testSetPushIdentifier() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "push identifier sync request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("20920") {
                XCTAssertTrue(request.url.absoluteString.contains("d_cid=20920%013935313632353862363233306166646439336366306364303762386464383435"))
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setPushIdentifier("9516258b6230afdd93cf0cd07b8dd845".data(using: .utf8))

        wait(for: [requestExpectation], timeout: 1)
    }

    func testSetAdvertisingIdentifier() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "advertising identifier sync request")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("20915") {
                XCTAssertTrue(request.url.absoluteString.contains("d_cid_ic=DSID_20915%01adid%011"))
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        MobileCore.setAdvertisingIdentifier("adid")
        wait(for: [requestExpectation], timeout: 2)
    }

    /// Tests that when we reset the identities we generate a new ECID and send it out
    func testResetIdentities() {
        // set first ecid
        var props = IdentityProperties()
        let firstEcid = ECID()
        props.ecid = firstEcid
        props.saveToPersistence()

        initExtensionsAndWait()
        waitForBootupHit(initialConfig: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])

        let resetHitExpectation = XCTestExpectation(description: "new sync from reset identities")
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            resetHitExpectation.fulfill()
            return nil
        }

        // test
        MobileCore.resetIdentities()

        wait(for: [resetHitExpectation], timeout: 2)
        
        // Wait for 500ms so that the new ECID gets persisted and to avoid race conditions
        usleep(500)
        
        // assert new ECID on last hit
        props.loadFromPersistence()
        guard let newEcid = props.ecid else {
            XCTFail("New ECID is not generated")
            return
        }
        
        XCTAssertNotEqual(firstEcid.ecidString, newEcid.ecidString)
        XCTAssertTrue(mockNetworkService.requests[0].url.absoluteString.contains(newEcid.ecidString))
        XCTAssertFalse(mockNetworkService.requests[0].url.absoluteString.contains(firstEcid.ecidString))
    }

    private func waitForBootupHit(initialConfig: [String: String]) {
        let bootupExpectation = XCTestExpectation(description: "bootup hit goes out")

        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService

        mockNetworkService.mock { request in
            mockNetworkService.resolvers.removeAll()
            bootupExpectation.fulfill()
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: initialConfig)
        wait(for: [bootupExpectation], timeout: 2)
    }

    private func persistECIDInUserDefaults() {
        let dataStore = NamedCollectionDataStore(name: "com.adobe.module.identity")
        var properties = IdentityProperties()
        properties.ecid = ECID()
        dataStore.setObject(key: "identity.properties", value: properties)
    }

}
