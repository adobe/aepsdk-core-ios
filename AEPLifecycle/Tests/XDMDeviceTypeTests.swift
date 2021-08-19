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
import XCTest

class XDMDeviceTypeTests: XCTestCase {

    func testFromServicesDeviceTypePhone() {
        XCTAssertEqual(XDMDeviceType.mobile, XDMDeviceType.from(servicesDeviceType: AEPServices.DeviceType.PHONE))
    }

    func testFromServicesDeviceTypePad() {
        XCTAssertEqual(XDMDeviceType.tablet, XDMDeviceType.from(servicesDeviceType: AEPServices.DeviceType.PAD))
    }

    func testFromServicesDeviceTypeCarplay() {
        XCTAssertEqual(XDMDeviceType.mobile, XDMDeviceType.from(servicesDeviceType: AEPServices.DeviceType.CARPLAY))
    }

    // MARK: Encodable Tests
    func testEncodeMobile() throws {
        // setup
        let device = XDMDeviceType.mobile

        // test
        let data = try XCTUnwrap(JSONEncoder().encode(device))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        XCTAssertEqual("\"mobile\"", dataStr)
    }

    func testEncodeTablet() throws {
        // setup
        let device = XDMDeviceType.tablet

        // test
        let data = try XCTUnwrap(JSONEncoder().encode(device))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        XCTAssertEqual("\"tablet\"", dataStr)
    }

}
