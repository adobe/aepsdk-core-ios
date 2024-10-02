/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest

import AEPCoreMocks
@testable import AEPLifecycle
import AEPServices

class XDMApplicationTests: XCTestCase, AnyCodableAsserts {

    private func buildAndSetMockInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.appId = "test-app-id"
        mockSystemInfoService.applicationName = "test-app-name"
        mockSystemInfoService.appVersion = "test-version"
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }

    // MARK: Encodable Tests
    func testEncodeXDMApplication() throws {
        // setup
        buildAndSetMockInfoService()

        var application = XDMApplication()
        application.isInstall = true
        application.sessionLength = 424394
        application.isLaunch = true
        application.isUpgrade = true

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(application))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "isLaunch" : true,
          "isUpgrade" : true,
          "isInstall" : true,
          "sessionLength" : 424394
        }
        """

        assertEqual(expected: expected, actual: dataStr)
    }
}
