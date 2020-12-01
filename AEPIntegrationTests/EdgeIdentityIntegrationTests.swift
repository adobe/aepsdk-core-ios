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

class EdgeIdentityIntegrationTests: XCTestCase {

    override func setUp() {
        UserDefaults.clear()
        FileManager.default.clearCache()
        ServiceProvider.shared.reset()
        EventHub.reset()
    }

    func initExtensionsAndWait() {
        let initExpectation = XCTestExpectation(description: "init extensions")
        MobileCore.setLogLevel(.trace)
        let extensions = [Identity.self, Lifecycle.self, Signal.self, MockEdgeExtension.self] as! [Extension.Type]
        MobileCore.registerExtensions(extensions) {
            initExpectation.fulfill()
        }
        wait(for: [initExpectation], timeout: 1)
    }

    /// No network request should be made since the Edge extension is registered
    func testSyncIdentifiersEdgeIsRegistered() {
        initExtensionsAndWait()

        let requestExpectation = XCTestExpectation(description: "syncIdentifiers request")
        requestExpectation.isInverted = true
        let mockNetworkService = TestableNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.mock { request in
            if request.url.absoluteString.contains("d_cid_ic=id1%2501value1%25010") {
                XCTAssertTrue(request.url.absoluteString.contains("https://test.com/id"))
                XCTAssertTrue(request.url.absoluteString.contains("d_orgid=orgid"))
                requestExpectation.fulfill()
            }
            return nil
        }

        MobileCore.updateConfigurationWith(configDict: ["experienceCloud.org": "orgid", "experienceCloud.server": "test.com", "global.privacy": "optedin"])
        Identity.syncIdentifiers(identifiers: ["id1": "value1"])

        wait(for: [requestExpectation], timeout: 1)
    }

}

@objc private class MockEdgeExtension: NSObject, Extension {
    var name = "com.adobe.edge"

    var friendlyName = "Edge"

    static var extensionVersion = "1.0.0-test"

    var metadata: [String : String]?

    var runtime: ExtensionRuntime

    func onRegistered() {}

    func onUnregistered() {}

    required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    func readyForEvent(_ event: Event) -> Bool {
        return true
    }
}
