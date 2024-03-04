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
import XCTest
import AEPServicesMocks

class XDMEnvironmentTests: XCTestCase, AnyCodableAsserts {

    // MARK: Encodable tests

    func testEncodeEnvironment() throws {
        // setup
        var env = XDMEnvironment()
        env.operatingSystem = "test-os"
        env.language = XDMLanguage(language: "en-US")
        env.carrier = "test-carrier"
        env.operatingSystemVersion = "test-os-version"
        env.operatingSystem = "test-os-name"
        env.type = XDMEnvironmentType.application

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(env))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "operatingSystemVersion" : "test-os-version",
          "carrier" : "test-carrier",
          "operatingSystem" : "test-os-name",
          "type" : "application",
          "_dc" : {
            "language" : "en-US"
          }
        }
        """

        assertEqual(expected: expected, actual: dataStr)
    }

}
