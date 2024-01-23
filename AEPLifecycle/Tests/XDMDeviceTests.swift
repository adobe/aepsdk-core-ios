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

@testable import AEPLifecycle
import AEPServices
import AEPServicesMocks
import AEPTestUtils
import XCTest

class XDMDeviceTests: XCTestCase, AnyCodableAsserts {

    private func buildAndSetMockInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.deviceName = "test-device-name"
        mockSystemInfoService.displayInformation = (100, 200)
        mockSystemInfoService.deviceType = .PHONE
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }

    // MARK: Encodable Tests

    func testEncodeEnvironment() throws {
        // setup
        buildAndSetMockInfoService()
        var device = XDMDevice()
        device.model = "test-device-name"
        device.manufacturer = "apple"
        device.screenHeight = 200
        device.screenWidth = 100
        device.type = .mobile

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(device))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "manufacturer" : "apple",
          "model" : "test-device-name",
          "screenHeight" : 200,
          "screenWidth" : 100,
          "type" : "mobile"
        }
        """

        assertEqual(expected: expected, actual: dataStr)
    }
}
