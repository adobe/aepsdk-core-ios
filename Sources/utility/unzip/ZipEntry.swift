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

import Foundation
import CoreFoundation

/// An object which represents a serializable Header data structure for Zip Entries
protocol HeaderDataSerializable {
    /// The size of the header data
    static var size: Int { get }
    /// required failable initializer for the given header
    init?(data: Data, additionalDataProvider: (Int) throws -> Data)
}

/// A value that represents a file, a directory or a symbolic link within a `ZipArchive`.
///
/// You can retrieve instances of `ZipEntry` from a `ZipArchive` via subscripting or iteration.
/// Entries are identified by their `path`.
struct ZipEntry {
    enum OSType: UInt {
        case msdos = 0
        case unix = 3
        case osx = 19
        case unused = 20
    }
    
    /// The type of a ZipEntry
    enum EntryType: Int {
        case file
        case directory
        
        init(mode: mode_t) {
            switch mode & S_IFMT {
            case S_IFDIR:
                self = .directory
            default:
                self = .file
            }
        }
    }

    struct LocalFileHeader: HeaderDataSerializable {

        let localFileHeaderSignature = UInt32(FileUnzipperConstants.localFileHeaderSignature)
        let versionNeededToExtract: UInt16
        let generalPurposeBitFlag: UInt16
        let compressionMethod: UInt16
        let lastModFileTime: UInt16
        let lastModFileDate: UInt16
        let crc32: UInt32
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let fileNameLength: UInt16
        let extraFieldLength: UInt16
        static let size = 30
        let fileNameData: Data
        let extraFieldData: Data
    }

    struct DataDescriptor: HeaderDataSerializable {
        let data: Data
        let dataDescriptorSignature = UInt32(FileUnzipperConstants.dataDescriptorSignature)
        let crc32: UInt32
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        static let size = 16
    }

    struct CentralDirectoryStructure: HeaderDataSerializable {
        let centralDirectorySignature = UInt32(FileUnzipperConstants.centralDirectorySignature)
        let versionMadeBy: UInt16
        let versionNeededToExtract: UInt16
        let generalPurposeBitFlag: UInt16
        let compressionMethod: UInt16
        let lastModFileTime: UInt16
        let lastModFileDate: UInt16
        let crc32: UInt32
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let fileNameLength: UInt16
        let extraFieldLength: UInt16
        let fileCommentLength: UInt16
        let diskNumberStart: UInt16
        let internalFileAttributes: UInt16
        let externalFileAttributes: UInt32
        let relativeOffsetOfLocalHeader: UInt32
        static let size = 46
        let fileNameData: Data
        let extraFieldData: Data
        let fileCommentData: Data
        var usesDataDescriptor: Bool { return (self.generalPurposeBitFlag & (1 << 3 )) != 0 }
        var usesUTF8PathEncoding: Bool { return (self.generalPurposeBitFlag & (1 << 11 )) != 0 }
        var isEncrypted: Bool { return (self.generalPurposeBitFlag & (1 << 0)) != 0 }
        var isZIP64: Bool { return self.versionNeededToExtract >= 45 }
    }
    /// Returns the `path` of the receiver within a `ZipArchive`
    ///
    /// - Parameters:
    ///   - encoding: `String.Encoding`
    func path(using encoding: String.Encoding) -> String {
        return String(data: self.centralDirectoryStructure.fileNameData, encoding: encoding) ?? ""
    }
    /// The `path` of the receiver within a `ZipArchive`.
    var path: String {
        let dosLatinUS = 0x400
        let dosLatinUSEncoding = CFStringEncoding(dosLatinUS)
        let dosLatinUSStringEncoding = CFStringConvertEncodingToNSStringEncoding(dosLatinUSEncoding)
        let codepage437 = String.Encoding(rawValue: dosLatinUSStringEncoding)
        let encoding = self.centralDirectoryStructure.usesUTF8PathEncoding ? .utf8 : codepage437
        return self.path(using: encoding)
    }
    
    var type: EntryType {
        let mode = mode_t(self.centralDirectoryStructure.externalFileAttributes >> 16) & S_IFMT
        switch mode {
        case S_IFREG:
            return .file
        case S_IFDIR:
            return .directory
        default:
            return .file
        }
    }
    
    var dataOffset: Int {
        var dataOffset = Int(self.centralDirectoryStructure.relativeOffsetOfLocalHeader)
        dataOffset += LocalFileHeader.size
        dataOffset += Int(self.localFileHeader.fileNameLength)
        dataOffset += Int(self.localFileHeader.extraFieldLength)
        return dataOffset
    }
    let centralDirectoryStructure: CentralDirectoryStructure
    let localFileHeader: LocalFileHeader
    let dataDescriptor: DataDescriptor?

    init?(centralDirectoryStructure: CentralDirectoryStructure,
          localFileHeader: LocalFileHeader,
          dataDescriptor: DataDescriptor?) {
        // We currently don't support ZIP64 or encrypted archives
        guard !centralDirectoryStructure.isZIP64 else { return nil }
        guard !centralDirectoryStructure.isEncrypted else { return nil }
        self.centralDirectoryStructure = centralDirectoryStructure
        self.localFileHeader = localFileHeader
        self.dataDescriptor = dataDescriptor
    }
}

extension ZipEntry.LocalFileHeader {

    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipEntry.LocalFileHeader.size else { return nil }
        guard ZipArchive.scanValue(start: 0, data: data) == localFileHeaderSignature else { return nil }
        self.versionNeededToExtract = ZipArchive.scanValue(start: 4, data: data)
        self.generalPurposeBitFlag = ZipArchive.scanValue(start: 6, data: data)
        self.compressionMethod = ZipArchive.scanValue(start: 8, data: data)
        self.lastModFileTime = ZipArchive.scanValue(start: 10, data: data)
        self.lastModFileDate = ZipArchive.scanValue(start: 12, data: data)
        self.crc32 = ZipArchive.scanValue(start: 14, data: data)
        self.compressedSize = ZipArchive.scanValue(start: 18, data: data)
        self.uncompressedSize = ZipArchive.scanValue(start: 22, data: data)
        self.fileNameLength = ZipArchive.scanValue(start: 26, data: data)
        self.extraFieldLength = ZipArchive.scanValue(start: 28, data: data)
        let additionalDataLength = Int(self.fileNameLength + self.extraFieldLength)
        guard let additionalData = try? provider(additionalDataLength) else { return nil }
        guard additionalData.count == additionalDataLength else { return nil }
        var subRangeStart = 0
        var subRangeEnd = Int(self.fileNameLength)
        self.fileNameData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
        subRangeStart += Int(self.fileNameLength)
        subRangeEnd = subRangeStart + Int(self.extraFieldLength)
        self.extraFieldData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
    }
}

extension ZipEntry.CentralDirectoryStructure {

    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipEntry.CentralDirectoryStructure.size else { return nil }
        guard ZipArchive.scanValue(start: 0, data: data) == centralDirectorySignature else { return nil }
        self.versionMadeBy = ZipArchive.scanValue(start: 4, data: data)
        self.versionNeededToExtract = ZipArchive.scanValue(start: 6, data: data)
        self.generalPurposeBitFlag = ZipArchive.scanValue(start: 8, data: data)
        self.compressionMethod = ZipArchive.scanValue(start: 10, data: data)
        self.lastModFileTime = ZipArchive.scanValue(start: 12, data: data)
        self.lastModFileDate = ZipArchive.scanValue(start: 14, data: data)
        self.crc32 = ZipArchive.scanValue(start: 16, data: data)
        self.compressedSize = ZipArchive.scanValue(start: 20, data: data)
        self.uncompressedSize = ZipArchive.scanValue(start: 24, data: data)
        self.fileNameLength = ZipArchive.scanValue(start: 28, data: data)
        self.extraFieldLength = ZipArchive.scanValue(start: 30, data: data)
        self.fileCommentLength = ZipArchive.scanValue(start: 32, data: data)
        self.diskNumberStart = ZipArchive.scanValue(start: 34, data: data)
        self.internalFileAttributes = ZipArchive.scanValue(start: 36, data: data)
        self.externalFileAttributes = ZipArchive.scanValue(start: 38, data: data)
        self.relativeOffsetOfLocalHeader = ZipArchive.scanValue(start: 42, data: data)
        let additionalDataLength = Int(self.fileNameLength + self.extraFieldLength + self.fileCommentLength)
        guard let additionalData = try? provider(additionalDataLength) else { return nil }
        guard additionalData.count == additionalDataLength else { return nil }
        var subRangeStart = 0
        var subRangeEnd = Int(self.fileNameLength)
        self.fileNameData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
        subRangeStart += Int(self.fileNameLength)
        subRangeEnd = subRangeStart + Int(self.extraFieldLength)
        self.extraFieldData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
        subRangeStart += Int(self.extraFieldLength)
        subRangeEnd = subRangeStart + Int(self.fileCommentLength)
        self.fileCommentData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
    }

}

extension ZipEntry.DataDescriptor {
    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipEntry.DataDescriptor.size else { return nil }
        let signature: UInt32 = ZipArchive.scanValue(start: 0, data: data)
        // The DataDescriptor signature is not mandatory so we have to re-arrange the input data if it is missing.
        var readOffset = 0
        if signature == self.dataDescriptorSignature { readOffset = 4 }
        self.crc32 = ZipArchive.scanValue(start: readOffset, data: data)
        self.compressedSize = ZipArchive.scanValue(start: readOffset + 4, data: data)
        self.uncompressedSize = ZipArchive.scanValue(start: readOffset + 8, data: data)
        self.data = Data()
    }
}
