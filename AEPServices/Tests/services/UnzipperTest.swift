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

class FileUnzipperTest: XCTestCase {
    let unzipper = FileUnzipper()
    let testDataFileName = "TestRules"
    let testLargeFileName = "TestLarge"
    let testCorruptFileName = "TestCorruptFile"
    let testInvalidCompressionMethodFileName = "TestInvalidCompressionMethod"
    let testZipSlipFileName = "TestZipSlip"

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

    ///
    /// Test a simple unzip of a sample zip file which holds a rules.txt file
    ///
    func testUnzippingRulesSuccessSimple() {
        removeResourceWith(name: testDataFileName)
        guard let sourceURL = getResourceURLWith(name: testDataFileName) else {
            XCTFail()
            return
        }
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testDataFileName)
        let unzippedItems = unzipper.unzipItem(at: sourceURL, to: destinationURL)
        XCTAssertFalse(unzippedItems.isEmpty)
    }

    ///
    /// Test to make sure that when unzipping the archive, the correct entries are found at the destination
    ///
    func testUnzippingRulesSuccessFilesExist() {
        removeResourceWith(name: testDataFileName)
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

    ///
    /// Test to make sure correct behavior when unzipping a file which doesn't exist
    ///
    func testUnzippingRulesDoesntExist() {
        let testFileName = "doesntExist"
        let testFileExt = ".zip"
        let sourceURL = FileUnzipperTest.bundle.bundleURL.appendingPathComponent(testFileName + testFileExt)
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testFileName)
        let unzippedItems = unzipper.unzipItem(at: sourceURL, to: destinationURL)
        XCTAssertTrue(unzippedItems.isEmpty)
    }

    ///
    /// Test that correct errors are thrown when extracting a corrupt file
    ///
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

    ///
    /// Test that correct error is thrown when invalid compression method is used for zip file
    ///
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

    ///
    /// Test large unzip file performance
    ///
    func testLargeUnzipPerformance() {
        guard let sourceUrl = getResourceURLWith(name: testLargeFileName) else {
            XCTFail()
            return
        }
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("performanceTestFiles")

        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 1
        if #available(iOS 13.0, tvOS 13.0, *) {
            measure(options: measureOptions, block: {
                let unzippedItems = self.unzipper.unzipItem(at: sourceUrl, to: temporaryDirectory)
                XCTAssertEqual(unzippedItems.count, 2)

            })
        } else {
            let unzippedItems = self.unzipper.unzipItem(at: sourceUrl, to: temporaryDirectory)
            XCTAssertEqual(unzippedItems.count, 2)
        }
    }

    ///
    /// Test small unzip file performance
    ///
    func testSmallUnzipPerformance() {
        removeResourceWith(name: testDataFileName)
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

    ///
    /// Test Zip Slip attempt does not succeed
    ///
    func testZipSlipCatchWithExploitedZip() {
        removeResourceWith(name: testZipSlipFileName)
        guard let sourceURL = getResourceURLWith(name: testZipSlipFileName) else {
            XCTFail()
            return
        }

        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(testZipSlipFileName)
        let unzippedItems = unzipper.unzipItem(at: sourceURL, to: destinationURL)
        XCTAssertTrue(unzippedItems.isEmpty)
    }


    func testIsValidUrlWithInvalidUrl() {
        let invalidUrl1 = URL(string: "/var/mobile/Containers/Data/Application/A87F42D1-3EFE-4F4D-A22D-233F184684BB/Library/Caches/com.adobe.edge/../../../")
        let invalidUrl2 = URL(string: "/var/../mobile/Containers/Data/Application/A87F42D1-3EFE-4F4D-A22D-233F184684BB/Library/Caches/com.adobe.edge/")
        let validUrl1 = URL(string: "/var/mobile/Containers/Data/Application/A87F42D1-3EFE-4F4D-A22D-233F184684BB/Library/Caches/com.adobe.edge/")
        XCTAssertFalse(invalidUrl1!.isSafeUrl())
        XCTAssertFalse(invalidUrl2!.isSafeUrl())
        XCTAssertTrue(validUrl1!.isSafeUrl())
    }

    // MARK: - Helpers
    private func getResourceURLWith(name: String) -> URL? {
        return FileUnzipperTest.bundle.url(forResource: name, withExtension: "zip")
    }

    private func removeResourceWith(name: String) {
        do {
            let fileManager = FileManager()
            guard let path = FileUnzipperTest.bundle.url(forResource: name, withExtension: "zip")?.deletingLastPathComponent().appendingPathComponent(name) else {
                return
            }
            try fileManager.removeItem(at: path)
        } catch {
            return
        }
    }
}


