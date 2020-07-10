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
import Compression

/// A sequence of uncompressed or compressed ZIP entries.
///
/// You use a `ZipArchive` to read existing ZIP files.
///
/// A `ZipArchive` is a sequence of ZipEntries. You can
/// iterate over an archive using a `for`-`in` loop to get access to individual `ZipEntry` objects:
///
///     for entry in archive {
///         print(entry.path)
///     }
final class ZipArchive: Sequence {
    
    /// An unsigned 32-Bit Integer representing a checksum.
    typealias CRC32 = UInt32
    
    /// a custom handler that consumes a `data` object containing partial entry data.
    /// - parameters:
    ///   - data: a chunk of `data` to consume.
    /// - throws: can throw to indicate errors during data consumption.
    typealias EntryDataConsumer = (_ data: Data) throws -> Void
    
    /// A custom handler that receives a position and a size that can be used to provide data from an arbitrary source.
    /// - Parameters:
    ///   - position: The current read position.
    ///   - size: The size of the chunk to provide.
    /// - Returns: A chunk of `Data`.
    /// - Throws: Can throw to indicate errors in the data source.
    typealias Provider = (_ position: Int, _ size: Int) throws -> Data
    
    typealias LocalFileHeader = ZipEntry.LocalFileHeader
    typealias DataDescriptor = ZipEntry.DataDescriptor
    typealias CentralDirectoryStructure = ZipEntry.CentralDirectoryStructure

    /// An error that occurs during reading, creating or updating a ZIP file.
    enum ArchiveError: Error {
        /// Thrown when an archive file is either damaged or inaccessible.
        case unreadableArchive
        /// Thrown when a `ZipEntry` can't be stored in the archive with the proposed compression method.
        case invalidCompressionMethod
        /// Thrown when the start of the central directory exceeds `UINT32_MAX`
        case invalidStartOfCentralDirectoryOffset
        /// Thrown when an archive does not contain the required End of Central Directory Record.
        case missingEndOfCentralDirectoryRecord
        /// Thrown when an extract operation was canceled.
        case cancelledOperation
    }
    
    /// An error that occurs during decompression
    enum DecompressionError: Error {
        case invalidStream
        case corruptedData
    }
    
    struct EndOfCentralDirectoryRecord: DataSerializable {

        let endOfCentralDirectorySignature = UInt32(FileUnzipperConstants.endOfCentralDirectorySignature)
        let numberOfDisk: UInt16
        let numberOfDiskStart: UInt16
        let totalNumberOfEntriesOnDisk: UInt16
        let totalNumberOfEntriesInCentralDirectory: UInt16
        let sizeOfCentralDirectory: UInt32
        let offsetToStartOfCentralDirectory: UInt32
        let zipFileCommentLength: UInt16
        let zipFileCommentData: Data
        static let size = 22
    }

    /// URL of a ZipArchive's backing file.
    let url: URL
    /// Unsafe pointer to archive file for C operations
    var archiveFile: UnsafeMutablePointer<FILE>
    var endOfCentralDirectoryRecord: EndOfCentralDirectoryRecord

    /// Initializes a new `ZipArchive`.
    ///
    /// used to create new archive files or to read existing ones.
    /// - Parameter: `url`: File URL to the receivers backing file.
    init?(url: URL) {
        self.url = url
        guard let (archiveFile, endOfCentralDirectoryRecord) = ZipArchive.configureFileBacking(for: url) else {
            return nil
        }
        self.archiveFile = archiveFile
        self.endOfCentralDirectoryRecord = endOfCentralDirectoryRecord
    }

    deinit {
        fclose(self.archiveFile)
    }
    
    /// Read a `ZipEntry` from the receiver and write it to `url`.
    ///
    /// - Parameters:
    ///   - entry: The ZIP `Entry` to read.
    ///   - url: The destination file URL.
    /// - Returns: The checksum of the processed content.
    /// - Throws: An error if the destination file cannot be written or the entry contains malformed content.
    @discardableResult
    func extract(_ entry: ZipEntry, to url: URL) throws -> CRC32 {
        let bufferSize = FileUnzipperConstants.defaultReadChunkSize
        let fileManager = FileManager()
        var checksum = CRC32(0)
        guard !fileManager.itemExists(at: url) else {
            throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: url.path])
        }
        try fileManager.createParentDirectoryStructure(for: url)
        let destinationRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
        guard let destinationFile: UnsafeMutablePointer<FILE> = fopen(destinationRepresentation, "wb+") else {
            throw CocoaError(.fileNoSuchFile)
        }
        defer { fclose(destinationFile) }
        let consumer = { _ = try Data.write(chunk: $0, to: destinationFile) }
        fseek(self.archiveFile, entry.dataOffset, SEEK_SET)
        checksum = try self.readCompressed(entry: entry, bufferSize: bufferSize, with: consumer)
        let attributes = FileManager.attributes(from: entry)
        try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        return checksum
    }
    
    ///
    /// MARK: - Sequence Protocol makeIterator implementation
    ///
    func makeIterator() -> AnyIterator<ZipEntry> {
        let endOfCentralDirectoryRecord = self.endOfCentralDirectoryRecord
        var directoryIndex = Int(endOfCentralDirectoryRecord.offsetToStartOfCentralDirectory)
        var index = 0
        return AnyIterator {
            guard index < Int(endOfCentralDirectoryRecord.totalNumberOfEntriesInCentralDirectory) else { return nil }
            guard let centralDirStruct: CentralDirectoryStructure = Data.readStruct(from: self.archiveFile,
                                                                                    at: directoryIndex) else {
                                                                                        return nil
            }
            let offset = Int(centralDirStruct.relativeOffsetOfLocalHeader)
            guard let localFileHeader: LocalFileHeader = Data.readStruct(from: self.archiveFile,
                                                                         at: offset) else { return nil }
            var dataDescriptor: DataDescriptor?
            if centralDirStruct.usesDataDescriptor {
                let additionalSize = Int(localFileHeader.fileNameLength + localFileHeader.extraFieldLength)
                let dataSize = centralDirStruct.compressedSize
                let descriptorPosition = offset + LocalFileHeader.size + additionalSize + Int(dataSize)
                dataDescriptor = Data.readStruct(from: self.archiveFile, at: descriptorPosition)
            }
            defer {
                directoryIndex += CentralDirectoryStructure.size
                directoryIndex += Int(centralDirStruct.fileNameLength)
                directoryIndex += Int(centralDirStruct.extraFieldLength)
                directoryIndex += Int(centralDirStruct.fileCommentLength)
                index += 1
            }
            return ZipEntry(centralDirectoryStructure: centralDirStruct,
                            localFileHeader: localFileHeader, dataDescriptor: dataDescriptor)
        }
    }
    
    //
    //    MARK: - Helpers
    //
    private func readCompressed(entry: ZipEntry, bufferSize: UInt32, with consumer: EntryDataConsumer) throws -> CRC32 {
        let size = Int(entry.centralDirectoryStructure.compressedSize)
        return try decompress(size: size, bufferSize: Int(bufferSize), provider: { (_, chunkSize) -> Data in
                                    return try Data.readChunk(of: chunkSize, from: self.archiveFile)
        }, consumer: { (data) in
            try consumer(data)
        })
    }


    private static func configureFileBacking(for url: URL)
        -> (UnsafeMutablePointer<FILE>, EndOfCentralDirectoryRecord)? {
        let fileManager = FileManager()
        let fileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
        guard let archiveFile = fopen(fileSystemRepresentation, "rb"),
            let endOfCentralDirectoryRecord = ZipArchive.scanForEndOfCentralDirectoryRecord(in: archiveFile) else {
                return nil
        }
        return (archiveFile, endOfCentralDirectoryRecord)
    }

    private static func scanForEndOfCentralDirectoryRecord(in file: UnsafeMutablePointer<FILE>)
        -> EndOfCentralDirectoryRecord? {
        var directoryEnd = 0
        var index = FileUnzipperConstants.minDirectoryEndOffset
        fseek(file, 0, SEEK_END)
        let archiveLength = ftell(file)
        while directoryEnd == 0 && index < FileUnzipperConstants.maxDirectoryEndOffset && index <= archiveLength {
            fseek(file, archiveLength - index, SEEK_SET)
            var potentialDirectoryEndTag: UInt32 = UInt32()
            fread(&potentialDirectoryEndTag, 1, MemoryLayout<UInt32>.size, file)
            if potentialDirectoryEndTag == UInt32(FileUnzipperConstants.endOfCentralDirectorySignature) {
                directoryEnd = archiveLength - index
                return Data.readStruct(from: file, at: directoryEnd)
            }
            index += 1
        }
        return nil
    }
    
    /// Decompress the output of `provider` and pass it to `consumer`.
    /// - Parameters:
    ///   - size: The compressed size of the data to be decompressed.
    ///   - bufferSize: The maximum size of the decompression buffer.
    ///   - provider: A closure that accepts a position and a chunk size. Returns a `Data` chunk.
    ///   - consumer: A closure that processes the result of the decompress operation.
    /// - Returns: The checksum of the processed content.
    private func decompress(size: Int, bufferSize: Int, provider: Provider, consumer: EntryDataConsumer) throws -> CRC32 {
        var crc32 = CRC32(0)
        let destPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destPointer.deallocate() }
        let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { streamPointer.deallocate() }
        var stream = streamPointer.pointee
        var status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
        guard status != COMPRESSION_STATUS_ERROR else { throw DecompressionError.invalidStream }
        defer { compression_stream_destroy(&stream) }
        stream.src_size = 0
        stream.dst_ptr = destPointer
        stream.dst_size = bufferSize
        var position = 0
        var sourceData: Data?
        repeat {
            if stream.src_size == 0 {
                do {
                    sourceData = try provider(position, Swift.min((size - position), bufferSize))
                    if let sourceData = sourceData {
                        position += sourceData.count
                        stream.src_size = sourceData.count
                    }
                } catch { throw error }
            }
            if let sourceData = sourceData {
                sourceData.withUnsafeBytes { (rawBufferPointer) in
                    if let baseAddress = rawBufferPointer.baseAddress {
                        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                        stream.src_ptr = pointer.advanced(by: sourceData.count - stream.src_size)
                        let flags = sourceData.count < bufferSize ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
                        status = compression_stream_process(&stream, flags)
                    }
                }
            }
            switch status {
            case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                let outputData = Data(bytesNoCopy: destPointer, count: bufferSize - stream.dst_size, deallocator: .none)
                try consumer(outputData)
                crc32 = calcChecksum(data: outputData, checksum: crc32)
                stream.dst_ptr = destPointer
                stream.dst_size = bufferSize
            default: throw DecompressionError.corruptedData
            }
        } while status == COMPRESSION_STATUS_OK
        return crc32
    }
    
    /// Calculate the `CRC32` checksum of the receiver.
    ///
    /// - Parameter checksum: The starting seed.
    /// - Returns: The checksum calculated from the bytes of the receiver and the starting seed.
    private func calcChecksum(data: Data, checksum: CRC32) -> CRC32 {
        // The typecast is necessary on 32-bit platforms because of
        // https://bugs.swift.org/browse/SR-1774
        let mask = 0xffffffff as UInt32
        let bufferSize = data.count/MemoryLayout<UInt8>.size
        var result = checksum ^ mask
        FileUnzipperConstants.crcTable.withUnsafeBufferPointer { crcTablePointer in
            data.withUnsafeBytes { bufferPointer in
                let bytePointer = bufferPointer.bindMemory(to: UInt8.self)
                for bufferIndex in 0..<bufferSize {
                    let byte = bytePointer[bufferIndex]
                    let index = Int((result ^ UInt32(byte)) & 0xff)
                    result = (result >> 8) ^ crcTablePointer[index]
                }
            }
        }
        return result ^ mask
    }
}

extension ZipArchive.EndOfCentralDirectoryRecord {
    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipArchive.EndOfCentralDirectoryRecord.size else { return nil }
        guard data.scanValue(start: 0) == endOfCentralDirectorySignature else { return nil }
        self.numberOfDisk = data.scanValue(start: 4)
        self.numberOfDiskStart = data.scanValue(start: 6)
        self.totalNumberOfEntriesOnDisk = data.scanValue(start: 8)
        self.totalNumberOfEntriesInCentralDirectory = data.scanValue(start: 10)
        self.sizeOfCentralDirectory = data.scanValue(start: 12)
        self.offsetToStartOfCentralDirectory = data.scanValue(start: 16)
        self.zipFileCommentLength = data.scanValue(start: 20)
        guard let commentData = try? provider(Int(self.zipFileCommentLength)) else { return nil }
        guard commentData.count == Int(self.zipFileCommentLength) else { return nil }
        self.zipFileCommentData = commentData
    }
}
