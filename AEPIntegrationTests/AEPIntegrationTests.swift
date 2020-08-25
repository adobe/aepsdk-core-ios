//
//  AEPIntegrationTests.swift
//  AEPIntegrationTests
//
//  Created by Jiabin Geng on 8/24/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import XCTest
import AEPCore
import AEPServices
import AEPIdentity
import AEPLifecycle
import AEPSignal


extension UserDefaults {
    public static func clear() {
        for _ in 0 ... 5 {
            for key in UserDefaults.standard.dictionaryRepresentation().keys {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}



class AEPIntegrationTests: XCTestCase {

    override func setUp() {
        UserDefaults.clear()
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
    
    func testLifecycle() {
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

}
