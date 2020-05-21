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

class SystemInfoServiceTest: XCTestCase {
    
    var systemInfoService: SystemInfoService!
    
    var bundle: Bundle!
 
    // Keep name and content up to date with TestConfig.json and TestImage.png files in test resources group
    let testStringFileName = "TestConfig"
    let testStringFileContents = "testing\n"
    let testDataFileName = "TestImage"

    override func setUp() {
        self.bundle = Bundle(for: type(of: self))
        self.systemInfoService = ApplicationSystemInfoService(bundle: bundle)
        
    }

    func testGetProperty() {
        // This is set in the test's info.plist
        let testKey = "test"
        let testValue = "testValue"
        XCTAssert(systemInfoService.getProperty(for: testKey) == testValue)
    }
    
    func testGetPropertyNotString() {
        // This is set in the Test's info.plist
        let testKey = "testFail"
        XCTAssertNil(systemInfoService.getProperty(for: testKey))
    }
    
    func testGetStringAssetEmptyPath() {
        let stringAsset: String? = systemInfoService.getAsset(fileName: "", fileType: "")
        XCTAssertNil(stringAsset)
    }
    
    func testGetStringAssetWhenFileExists() {
        // TestConfig.json is located in the tests root directory, in the 'test resources' group. Edit that file for testing.
        XCTAssertEqual(systemInfoService.getAsset(fileName: testStringFileName, fileType: "json"), testStringFileContents)
    }
    
    func testGetStringAssetWhenFileDoesNotExist() {
        let stringAsset: String? = systemInfoService.getAsset(fileName: "RandomFile", fileType: ".json")
        XCTAssertNil(stringAsset)
    }
    
    func testGetDataAssetEmptyPath() {
        let dataAsset: [UInt8]? = systemInfoService.getAsset(fileName: "", fileType: "")
        XCTAssertNil(dataAsset)
    }
    
    func testGetDataAssetWhenFileExists() {
        // TestImage.png is located in the tests root directory, in the 'test resources' group. Edit that file for testing.
        let data: [UInt8]? = systemInfoService.getAsset(fileName: testDataFileName, fileType: "png")
        XCTAssertNotNil(data)
    }
    
    func testGetDefaultUserAgent() {
        // setup
        let pattern = "Mozilla/5.0 (.+?; CPU OS .+? like Mac OS X; .+)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        // test
        let userAgent = systemInfoService.getDefaultUserAgent()
        
        // verify
        let matches = regex.matches(in: userAgent, options: [], range: NSRange(location: 0, length: userAgent.count))
        XCTAssertFalse(matches.isEmpty)
    }
    
    func testGetActiveLocaleName() {
        XCTAssertFalse(systemInfoService.getActiveLocaleName().isEmpty)
    }
    
    func testGetDeviceName() {
        XCTAssertFalse(systemInfoService.getDeviceName().isEmpty)
    }
    
    func testGetRunMode() {
        XCTAssertNotNil(systemInfoService.getRunMode())
    }
    
    func testGetApplicationName() {
        XCTAssertNotNil(systemInfoService.getApplicationName())
    }
    
    func testGetApplicationVersion() {
        XCTAssertNotNil(systemInfoService.getApplicationVersion())
    }
    
    func testGetApplicationVersionCode() {
        XCTAssertNotNil(systemInfoService.getApplicationVersionCode())
    }
    
    func testGetOperatinSystemName() {
        XCTAssertNotNil(systemInfoService.getOperatingSystemName())
    }
    
    func testGetDisplayInformation() {
        let displayInfo = NativeDisplayInformation()
        let testDisplayInfo = systemInfoService.getDisplayInformation()
        XCTAssertEqual(displayInfo.heightPixels, testDisplayInfo.heightPixels)
        XCTAssertEqual(displayInfo.widthPixels, testDisplayInfo.widthPixels)
    }
}
