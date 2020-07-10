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

class UnzipperServiceTest: XCTestCase {
    let unzipper = FileUnzipper()
    let testDataFileName = "TestRules"
    
    class var bundle: Bundle {
        return Bundle(for: self)
    }

    override func setUp() {
        do {
            let fileManager = FileManager()
            guard let path = UnzipperServiceTest.bundle.url(forResource: testDataFileName, withExtension: "zip")?.deletingLastPathComponent().appendingPathComponent(testDataFileName) else {
                return
            }
            try fileManager.removeItem(at: path)
        } catch {
            return
        }
    }

    func testUnzippingRulesSuccess() {
        let fileManager = FileManager()
        guard let sourceURL = UnzipperServiceTest.bundle.url(forResource: testDataFileName, withExtension: "zip") else {
            XCTFail()
            return
        }
        guard let zipFile = ZipArchive(url: sourceURL) else {
            XCTFail("Failed to create archive")
            return
        }
        
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testDataFileName)
        
        do {
            try unzipper.unzipItem(at: sourceURL, to: destinationURL)
        } catch {
            XCTFail("unzip item threw with error: \(error)")
        }
        var itemExists = false
        for entry in zipFile {
            let directoryURL = destinationURL.appendingPathComponent(entry.path)
            itemExists = fileManager.itemExists(at: directoryURL)
            if !itemExists { break }
        }
        XCTAssert(itemExists)
    }
    
    func testUnzippingRulesDoesntExist() {
        let testFileName = "doesntExist"
        let testFileExt = ".zip"
        let sourceURL = UnzipperServiceTest.bundle.bundleURL.appendingPathComponent(testFileName+testFileExt)
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testFileName)
        
        do {
            try unzipper.unzipItem(at: sourceURL, to: destinationURL)
            XCTFail("Expected throw with item not existing at source url")
        } catch {
            let e = error as NSError
            if e.userInfo[NSFilePathErrorKey] as? String != sourceURL.path {
                XCTFail("unexpected error thrown")
            }
        }
    }
}
