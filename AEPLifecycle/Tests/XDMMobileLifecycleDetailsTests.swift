//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPLifecycle
import XCTest

class XDMMobileLifecycleDetailsTests: XCTestCase {

    // MARK: Encodable Tests

    func testEncodeLifecycleDetails() throws {
        var lifecycleDetails = XDMMobileLifecycleDetails()
        lifecycleDetails.timestamp = Date(timeIntervalSince1970: 1619827190)
        lifecycleDetails.eventType = "test-event-type"
        lifecycleDetails.application = XDMApplication()
        lifecycleDetails.application?.isInstall = true
        lifecycleDetails.application?.sessionLength = 424394
        lifecycleDetails.application?.isLaunch = true
        lifecycleDetails.application?.isUpgrade = true
        lifecycleDetails.environment = XDMEnvironment()
        lifecycleDetails.environment?.operatingSystem = "test-os"
        lifecycleDetails.environment?.language = XDMLifecycleLanguage(language: "en-US")
        lifecycleDetails.environment?.carrier = "test-carrier"
        lifecycleDetails.environment?.operatingSystemVersion = "test-os-version"
        lifecycleDetails.environment?.operatingSystem = "test-os-name"
        lifecycleDetails.environment?.type = XDMEnvironmentType.application
        lifecycleDetails.device = XDMDevice()
        lifecycleDetails.device?.model = "test-device-name"
        lifecycleDetails.device?.manufacturer = "apple"
        lifecycleDetails.device?.screenHeight = 200
        lifecycleDetails.device?.screenWidth = 100
        lifecycleDetails.device?.type = .mobile

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(lifecycleDetails))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "environment" : {
            "operatingSystemVersion" : "test-os-version",
            "carrier" : "test-carrier",
            "operatingSystem" : "test-os-name",
            "type" : "application",
            "_dc" : {
              "language" : "en-US"
            }
          },
          "device" : {
            "manufacturer" : "apple",
            "model" : "test-device-name",
            "screenHeight" : 200,
            "screenWidth" : 100,
            "type" : "mobile"
          },
          "application" : {
            "isLaunch" : true,
            "isUpgrade" : true,
            "isInstall" : true,
            "sessionLength" : 424394
          },
          "eventType" : "test-event-type",
          "timestamp" : "2021-04-30T23:59:50Z"
        }
        """

        XCTAssertEqual(expected, dataStr)
    }

}
