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

@testable import AEPServices
import XCTest


// TODO: - Add more robust testing. Also make sure to make use of the new return type for the unzip api in the tests
class FileUnzipperTest: XCTestCase {
    let unzipper = FileUnzipper()
    let testDataFileName = "TestRules"
    let testLargeFileName = "TestLarge"
    let testCorruptFileName = "TestCorruptFile"
    let testInvalidCompressionMethodFileName = "TestInvalidCompressionMethod"

    enum TestFileNames: String {
        case testDataSubFolderRulesName = "rules"
        case testDataSubFolderRulesItem = "testRules.txt"
        case testDataSubFolderRulesItem2 = "testRules2.txt"
        case testDataImageFileName = "TestImage.png"
    }

    class var bundle: Bundle {
        return Bundle(for: self)
    }

    static var tempZipDirectoryURL: URL = {
        var tempZipDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        tempZipDirectory.appendPathComponent("ZipTempDirectory")
        return tempZipDirectory
    }()

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
        guard let sourceURL = getResourceURLWith(name: testDataFileName) else {
            XCTFail()
            return
        }
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testDataFileName)
        let unzippedItems = unzipper.unzipItem(at: sourceURL, to: destinationURL)
        XCTAssertFalse(unzippedItems.isEmpty)
    }

    func testUnzippingRulesSuccessFilesExist() {
        let fileManager = FileManager()
        guard let sourceURL = getResourceURLWith(name: testDataFileName) else {
            XCTFail()
            return
        }
        guard let zipFile = ZipArchive(url: sourceURL) else {
            XCTFail("Failed to create archive")
            return
        }

        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testDataFileName)
        guard !unzipper.unzipItem(at: sourceURL, to: destinationURL).isEmpty else {
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
        let sourceURL = FileUnzipperTest.bundle.bundleURL.appendingPathComponent(testFileName + testFileExt)
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testFileName)
        let unzippedItems = unzipper.unzipItem(at: sourceURL, to: destinationURL)
        XCTAssertTrue(unzippedItems.isEmpty)
    }

    func testExtractCorruptFile() {
        guard let sourceUrl = getResourceURLWith(name: testCorruptFileName) else {
            XCTFail()
            return
        }

        let fileManager = FileManager()
        let destinationFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: sourceUrl.path)
        let destinationFile: UnsafeMutablePointer<FILE> = fopen(destinationFileSystemRepresentation, "r+b")

        do {
            fseek(destinationFile, 64, SEEK_SET)
            // Inject large enough zeroes block to make sure that libcompression detects failure when reading the stream
            try ZipArchive.write(chunk: Data(count: 512*1024), to: destinationFile)
            fclose(destinationFile)
            guard let zipArchive = ZipArchive(url: sourceUrl) else {
                XCTFail("Failed to read archive")
                return
            }
            guard let entry = zipArchive.filter({ $0.path == "data.random"}).first else {
                XCTFail("Failed to read entry")
                return
            }
            _ = try zipArchive.extract(entry, to: FileUnzipperTest.tempZipDirectoryURL)
        } catch let error as ZipArchive.DecompressionError {
            XCTAssert(error == ZipArchive.DecompressionError.corruptedData)
        } catch {
            XCTFail("Unexpected error while testing unzip corrupted file")
        }
    }

    func testExtractInvalidCompressionMethod() {
        guard let sourceUrl = getResourceURLWith(name: testInvalidCompressionMethodFileName) else {
            XCTFail()
            return
        }

        guard let zipArchive = ZipArchive(url: sourceUrl) else {
            XCTFail("Unable to create zip archive")
            return
        }

        for entry in zipArchive {
            do {
                var tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
                tempFileURL.appendPathComponent(entry.path)
                _ = try zipArchive.extract(entry, to: tempFileURL)
            } catch let error as ZipArchive.ArchiveError {
                XCTAssert(error == .invalidCompressionMethod)
            } catch {
                XCTFail("Unexpected error while trying to extract zip entry with invalid compression method")
            }
        }
    }

    func testLargeUnzipPerformance() {
        guard let sourceUrl = getResourceURLWith(name: testLargeFileName) else {
            XCTFail()
            return
        }
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("performanceTestFiles")
        measure {
            let unzippedItems = self.unzipper.unzipItem(at: sourceUrl, to: temporaryDirectory)
            XCTAssertEqual(unzippedItems.count, 2)
        }
    }

    func testSmallUnzipPerformance() {

        guard let sourceURL = getResourceURLWith(name: testDataFileName) else {
            XCTFail()
            return
        }
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testDataFileName)
        measure {
            let unzippedItems = unzipper.unzipItem(at: sourceURL, to: destinationURL)
            XCTAssertFalse(unzippedItems.isEmpty)
        }
    }

    // MARK: - Helpers
    func getResourceURLWith(name: String) -> URL? {
        return FileUnzipperTest.bundle.url(forResource: name, withExtension: "zip")
    }
}
