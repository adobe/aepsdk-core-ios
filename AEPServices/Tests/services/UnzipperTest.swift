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
@testable import AEPServices

class FileUnzipperTest: XCTestCase {
    let unzipper = FileUnzipper()
    let testDataFileName = "TestRules"

    enum TestFileNames: String {
        case testDataSubFolderRulesName = "rules"
        case testDataSubFolderRulesItem = "testRules.txt"
        case testDataSubFolderRulesItem2 = "testRules2.txt"
        case testDataImageFileName = "TestImage.png"
    }

    class var bundle: Bundle {
        return Bundle(for: self)
    }

    override func setUp() {
        do {
            let fileManager = FileManager()
            guard let path = FileUnzipperTest.bundle.url(forResource: testDataFileName, withExtension: "zip")?.deletingLastPathComponent().appendingPathComponent(testDataFileName) else {
                return
            }
            try fileManager.removeItem(at: path)
        } catch {
            return
        }
    }
    
    func testUnzippingRulesSuccessSimple() {
        guard let sourceURL = FileUnzipperTest.bundle.url(forResource: testDataFileName, withExtension: "zip") else {
            XCTFail()
            return
        }
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testDataFileName)
        let success = unzipper.unzipItem(at: sourceURL, to: destinationURL)
        XCTAssertTrue(success)
    }

    func testUnzippingRulesSuccessFilesExist() {
        let fileManager = FileManager()
        guard let sourceURL = FileUnzipperTest.bundle.url(forResource: testDataFileName, withExtension: "zip") else {
            XCTFail()
            return
        }
        guard let zipFile = ZipArchive(url: sourceURL) else {
            XCTFail("Failed to create archive")
            return
        }
        
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testDataFileName)
        guard unzipper.unzipItem(at: sourceURL, to: destinationURL) else {
            XCTFail("Unzipping failed")
            return
        }
        var itemExists = false
        var subFolderExists = false
        var subFolderRulesEntryExists = false
        var subFolderRulesEntry2Exists = false
        var imageFileExists = false
        for entry in zipFile {
            let directoryURL = destinationURL.appendingPathComponent(entry.path)
            // When using MacOS to compress folders a hidden directory is created. We should ignore it here for testing purposes
            if directoryURL.pathComponents.contains("__MACOSX") { continue }
            let testFileName = TestFileNames(rawValue: directoryURL.lastPathComponent)
            switch testFileName {
            case .testDataSubFolderRulesName:
                subFolderExists = true
            case .testDataSubFolderRulesItem:
                subFolderRulesEntryExists = true
            case .testDataSubFolderRulesItem2:
                subFolderRulesEntry2Exists = true
            case .testDataImageFileName:
                imageFileExists = true
            default:
                XCTFail("Unknown entry found: \(String(describing: testFileName?.rawValue))")
            }
            itemExists = fileManager.itemExists(at: directoryURL)
            if !itemExists { break }
        }
        XCTAssert(itemExists)
        XCTAssert(subFolderExists)
        XCTAssert(subFolderRulesEntryExists)
        XCTAssert(subFolderRulesEntry2Exists)
        XCTAssert(imageFileExists)
    }
    
    func testUnzippingRulesDoesntExist() {
        let testFileName = "doesntExist"
        let testFileExt = ".zip"
        let sourceURL = FileUnzipperTest.bundle.bundleURL.appendingPathComponent(testFileName+testFileExt)
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testFileName)
        let success = unzipper.unzipItem(at: sourceURL, to: destinationURL)
        XCTAssertFalse(success)
    }
}
