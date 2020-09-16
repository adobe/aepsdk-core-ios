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

enum AdditionalDataError: Error {
    case encodingError
    case invalidDataError
}

class ZipArchiveTest: XCTestCase {

    func testArchiveReadErrorNonExistent() {
        let nonExistentURL = URL(fileURLWithPath: "/nonExistent")
        let nonExistentZipArchive = ZipArchive(url: nonExistentURL)
        XCTAssertNil(nonExistentZipArchive)
    }
    
    func testArchiveReadErrorNoReadPermissions() {
        let unreadableArchiveURL = FileUnzipperTest.tempZipDirectoryURL
        let noPermissionAttributes = [FileAttributeKey.posixPermissions: NSNumber(value: Int16(0o000))]
        let fileManager = FileManager()
        let result = fileManager.createFile(atPath: unreadableArchiveURL.path, contents: nil, attributes: noPermissionAttributes)
        XCTAssertTrue(result)
        let unreadableArchive = ZipArchive(url: unreadableArchiveURL)
        XCTAssertNil(unreadableArchive)
    }
    
    func testNoEndOfCentralDirectoryArchiveReadError() {
        let noEndOfCentralDirectoryArchiveUrl = FileUnzipperTest.tempZipDirectoryURL
        let fullPermissionAttributes = [FileAttributeKey.posixPermissions: NSNumber(value: Int16(0o777))]
        let fileManager = FileManager()
        let result = fileManager.createFile(atPath: noEndOfCentralDirectoryArchiveUrl.path, contents: nil, attributes: fullPermissionAttributes)
        XCTAssertTrue(result)
        let noEndOfCentralDirectoryArchive = ZipArchive(url: noEndOfCentralDirectoryArchiveUrl)
        XCTAssertNil(noEndOfCentralDirectoryArchive)
    }
    
    func testArchiveIteratorError() {
        // Construct an archive that only contains an EndOfCentralDirectoryRecord
        // with a number of entries > 00
        // Although the initializer should succeed, iterator creation should fail
        let invalidCentralDir: [UInt8] = [0x50, 0x4B, 0x05, 0x06, 0x00, 0x00, 0x00, 0x00,
                                          0x01, 0x00, 0x01, 0x00, 0x5A, 0x00, 0x00, 0x00,
                                          0x2A, 0x00, 0x00, 0x00, 0x00, 0x00]
        let invalidCentralDirData = Data(invalidCentralDir)
        let invalidCentralDirArchiveUrl = FileUnzipperTest.tempZipDirectoryURL
        let fileManager = FileManager()
        let result = fileManager.createFile(atPath: invalidCentralDirArchiveUrl.path, contents: invalidCentralDirData, attributes: nil)
        XCTAssertTrue(result)
        guard let invalidCentralDirArchive = ZipArchive(url: invalidCentralDirArchiveUrl) else {
            XCTFail("Failed to create archive")
            return
        }
        
        var iteratorFailed = true
        for _ in invalidCentralDirArchive {
            iteratorFailed = false
        }
        XCTAssertTrue(iteratorFailed)
    }
    
    func testZipArchiveWithInvalidData() {
        // Test with an empty ECDR
        let emptyECDR = ZipArchive.EndOfCentralDirectoryRecord(data: Data(), additionalDataProvider: { _ -> Data in
            return Data()
        })
        
        XCTAssertNil(emptyECDR)
        
        // Test with a 22 byte ECDR with zeroed out bytes
        let invalidECDRData = Data(count: 22)
        let invalidECDR = ZipArchive.EndOfCentralDirectoryRecord(data: invalidECDRData, additionalDataProvider: { _ -> Data in
            return Data()
        })
        
        XCTAssertNil(invalidECDR)
        
        // Test with invalid comment bytes
        let invalidECDRCommentBytes: [UInt8] = [0x50, 0x4B, 0x05, 0x06, 0x00, 0x00, 0x00, 0x00,
                                                0x01, 0x00, 0x01, 0x00, 0x5A, 0x00, 0x00, 0x00,
                                                0x2A, 0x00, 0x00, 0x00, 0x00, 0x00]
        let invalidECDRCommentData = Data(invalidECDRCommentBytes)
        let ECDRWithInvalidComment = ZipArchive.EndOfCentralDirectoryRecord(data: invalidECDRCommentData, additionalDataProvider: { _ -> Data in
            throw AdditionalDataError.invalidDataError
        })
        
        XCTAssertNil(ECDRWithInvalidComment)
        
        // Test with invalid comment length
        let invalidECDRCommentLengthBytes: [UInt8] = [0x50, 0x4B, 0x05, 0x06, 0x00, 0x00, 0x00, 0x00,
                                                      0x01, 0x00, 0x01, 0x00, 0x5A, 0x00, 0x00, 0x00,
                                                      0x2A, 0x00, 0x00, 0x00, 0x00, 0x01]
        let invalidECDRCommentLengthData = Data(invalidECDRCommentLengthBytes)
        let ECDRWithInvalidCommentLength = ZipArchive.EndOfCentralDirectoryRecord(data: invalidECDRCommentLengthData, additionalDataProvider: { _ -> Data in
            return Data()
        })
        XCTAssertNil(ECDRWithInvalidCommentLength)
    }
    
    func testReadStructureError() {
        let fileManager = FileManager()
        let fileURL = FileUnzipperTest.tempZipDirectoryURL
        let result = fileManager.createFile(atPath: fileURL.path, contents: Data(),
                                            attributes: nil)
        XCTAssert(result == true)
        let fileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: fileURL.path)
        let file: UnsafeMutablePointer<FILE> = fopen(fileSystemRepresentation, "rb")
        // Close the file to simulate the error condition for unreadable file data
        fclose(file)
        let centralDirectoryStructure: ZipEntry.CentralDirectoryStructure? = ZipArchive.readStruct(from: file, at: 0)
        XCTAssertNil(centralDirectoryStructure)
    }
    
    func testReadChunkError() {
        let fileManager = FileManager()
        let fileURL = FileUnzipperTest.tempZipDirectoryURL
        let result = fileManager.createFile(atPath: fileURL.path, contents: Data(),
                                            attributes: nil)
        XCTAssert(result == true)
        let fileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: fileURL.path)
        let file: UnsafeMutablePointer<FILE> = fopen(fileSystemRepresentation, "rb")
        // Close the file to simulate the error condition for unreadable file data
        fclose(file)
        do {
            _ = try ZipArchive.readChunk(of: 10, from: file)
        } catch let error as ZipArchive.DataError {
            XCTAssert(error == .unreadableFile)
        } catch {
            XCTFail("Unexpected error while testing to read from a closed file.")
        }
    }
}
