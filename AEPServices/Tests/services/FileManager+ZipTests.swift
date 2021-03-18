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

class FileManagerZipTests: XCTestCase {

    func testDirectoryCreation() {
        var tempZipDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        tempZipDirectory.appendPathComponent("ZipTempDirectory")
        do {
            try FileManager().createParentDirectoryStructure(for: tempZipDirectory)
        } catch {
            XCTFail("Failed to created parent directory")
        }
    }

    func testFileAttribute() {
        let centralDirectoryStrBytes: [UInt8] = [0x50, 0x4b, 0x01, 0x02, 0x1e, 0x15, 0x14, 0x00,
                                                 0x08, 0x08, 0x08, 0x00, 0xab, 0x85, 0x77, 0x47,
                                                 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00,
                                                 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
                                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                 0xb0, 0x11, 0x00, 0x00, 0x00, 0x00]
        guard let centralDirectoryStructure = ZipEntry.CentralDirectoryStructure(data: Data(centralDirectoryStrBytes),
                                                                                 additionalDataProvider: { count -> Data in
                                                                                     guard let pathData = "/".data(using: .utf8) else {
                                                                                         throw AdditionalDataError.encodingError
                                                                                     }
                                                                                     XCTAssert(count == pathData.count)
                                                                                     return pathData
                                                                                 }) else {
            XCTFail("Failed to read central directory structure."); return
        }
        let localFileHeaderBytes: [UInt8] = [0x50, 0x4b, 0x03, 0x04, 0x14, 0x00, 0x08, 0x08,
                                             0x08, 0x00, 0xab, 0x85, 0x77, 0x47, 0x00, 0x00,
                                             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                             0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        guard let localFileHeader = ZipEntry.LocalFileHeader(data: Data(localFileHeaderBytes),
                                                             additionalDataProvider: { _ -> Data in
                                                                 return Data()
                                                             }) else {
            XCTFail("Failed to read local file header."); return
        }
        guard let entry = ZipEntry(centralDirectoryStructure: centralDirectoryStructure, localFileHeader: localFileHeader, dataDescriptor: nil) else {
            XCTFail("Failed to create test entry."); return
        }
        let attributes = FileManager.attributes(from: entry)
        guard let permissions = attributes[.posixPermissions] as? UInt16 else {
            XCTFail("Failed to read file attributes."); return
        }
        XCTAssert(permissions == FileUnzipperConstants.defaultFilePermissions)
    }

    func testFilePermission() {
        var permissions = FileManager.permissions(for: UInt32(777), osType: .unix, entryType: .file)
        XCTAssert(permissions == FileUnzipperConstants.defaultFilePermissions)
        permissions = FileManager.permissions(for: UInt32(0), osType: .msdos, entryType: .file)
        XCTAssert(permissions == FileUnzipperConstants.defaultFilePermissions)
        permissions = FileManager.permissions(for: UInt32(0), osType: .msdos, entryType: .directory)
        XCTAssert(permissions == FileUnzipperConstants.defaultDirectoryPermissions)
    }

    func testGetCacheDirectoryPath() {
        let fileManager = FileManager()
        guard let url = fileManager.getCacheDirectoryPath() else {
            XCTFail("Failed to read central directory structure."); return
        }
        XCTAssertNotNil(url)
    }
}
