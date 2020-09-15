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

import Compression
import Foundation

/// The compression method of a `ZipEntry` in a `ZipArchive`
enum CompressionMethod: UInt16 {
    /// Contents were compressed using a zlib compatible Deflate algorithm
    case deflate = 8
}

/// A sequence of uncompressed or compressed ZIP entries.
///
/// You use a `ZipArchive` to read existing ZIP files.
///
/// A `ZipArchive` is a sequence of ZipEntries. You can
/// iterate over an archive using a `for`-`in` loop to get access to individual `ZipEntry` objects
final class ZipArchive: Sequence {

    /// A DataError for the data within a ZipArchive
    enum DataError: Error {
        case unreadableFile
        case unwritableFile
    }

    /// An unsigned 32-Bit Integer representing a checksum.
    typealias CRC32 = UInt32

    /// a custom handler that consumes a `data` object containing partial entry data.
    /// - Parameters:
    ///   - data: a chunk of `data` to consume.
    /// - Throws: can throw to indicate errors during data consumption.
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
        /// Thrown when a `ZipEntry` can't be stored in the archive with the proposed compression method.
        case invalidCompressionMethod
    }

    private let LOG_PREFIX = "ZipArchive"

    /// An error that occurs during decompression
    enum DecompressionError: Error {
        case invalidStream
        case corruptedData
    }

    struct EndOfCentralDirectoryRecord: HeaderDataSerializable {
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
        guard let archiveFile = ZipArchive.getFilePtr(for: url) else {
            Log.warning(label: LOG_PREFIX, "Unable to obtain a file pointer for url \(url)")
            return nil
        }
        guard let endOfCentralDirectoryRecord = ZipArchive.getEndOfCentralDirectoryRecord(for: archiveFile) else {
            Log.warning(label: LOG_PREFIX, "Unable to obtain end of central directory record for archive file at \(archiveFile.debugDescription)")
            return nil
        }

        self.url = url
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
        switch entry.type {
        case .file:
            if fileManager.itemExists(at: url) {
                do {
                    try fileManager.removeItem(at: url)
                } catch {
                    throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: url.path])
                }
            }
            try fileManager.createParentDirectoryStructure(for: url)
            // Get file system representation for C operations
            let destinationRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
            // Get destination file C pointer
            guard let destinationFile: UnsafeMutablePointer<FILE> = fopen(destinationRepresentation, "wb+") else {
                throw CocoaError(.fileNoSuchFile)
            }
            defer { fclose(destinationFile) }
            // Set closure to handle writing data chunks to destination file
            let consumer = { try ZipArchive.write(chunk: $0, to: destinationFile) }
            // Set file pointer position to the given entry's data offset
            fseek(archiveFile, entry.dataOffset, SEEK_SET)
            guard let _ = CompressionMethod(rawValue: entry.localFileHeader.compressionMethod) else {
                throw ArchiveError.invalidCompressionMethod
            }
            checksum = try readCompressed(entry: entry, bufferSize: bufferSize, with: consumer)
        case .directory:
            let consumer = { (_: Data) in
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            fseek(archiveFile, entry.dataOffset, SEEK_SET)
            try consumer(Data())
        }
        let attributes = FileManager.attributes(from: entry)
        try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        return checksum
    }

    ///

    // MARK: - Sequence Protocol makeIterator implementation

    ///
    func makeIterator() -> AnyIterator<ZipEntry> {
        let endOfCentralDirectoryRecord = self.endOfCentralDirectoryRecord
        var directoryIndex = Int(endOfCentralDirectoryRecord.offsetToStartOfCentralDirectory)
        var index = 0
        return AnyIterator {
            guard index < Int(endOfCentralDirectoryRecord.totalNumberOfEntriesInCentralDirectory) else { return nil }
            guard let centralDirStruct: CentralDirectoryStructure = ZipArchive.readStruct(from: self.archiveFile,
                                                                                          at: directoryIndex) else {
                return nil
            }
            let offset = Int(centralDirStruct.relativeOffsetOfLocalHeader)
            guard let localFileHeader: LocalFileHeader = ZipArchive.readStruct(from: self.archiveFile,
                                                                               at: offset) else { return nil }
            var dataDescriptor: DataDescriptor?
            if centralDirStruct.usesDataDescriptor {
                let additionalSize = Int(localFileHeader.fileNameLength + localFileHeader.extraFieldLength)
                let dataSize = centralDirStruct.compressedSize
                let descriptorPosition = offset + LocalFileHeader.size + additionalSize + Int(dataSize)
                dataDescriptor = ZipArchive.readStruct(from: self.archiveFile, at: descriptorPosition)
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

    // MARK: - Helpers

    //

    ///
    /// Decompresses the compressed ZipEntry and returns the checksum
    /// - Parameters:
    ///     - entry: The ZipEntry to be decompressed
    ///     - bufferSize: The bufferSize to be used for the decompression buffer
    ///     - consumer: The consumer closure which handles the data chunks retrieved from decompression
    /// - Returns: The checksum for the decompressed entry
    private func readCompressed(entry: ZipEntry, bufferSize: UInt32, with consumer: EntryDataConsumer) throws -> CRC32 {
        let size = Int(entry.centralDirectoryStructure.compressedSize)
        return try decompress(size: size, bufferSize: Int(bufferSize), provider: { (_, chunkSize) -> Data in
            try ZipArchive.readChunk(of: chunkSize, from: self.archiveFile)
        }, consumer: { data in
            try consumer(data)
        })
    }

    ///
    /// Gets the file pointer for the file at the given url
    /// - Parameter url: The URL to the file
    /// - Returns: The C style pointer to the file at the given url
    private static func getFilePtr(for url: URL) -> UnsafeMutablePointer<FILE>? {
        let fileManager = FileManager()
        let fileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
        return fopen(fileSystemRepresentation, "rb")
    }

    ///
    /// Gets the end of central directory record for the given file
    /// - Parameter file: The c style pointer to the file
    /// - Returns: The EndOfCentralDirectoryRecord for the given file
    private static func getEndOfCentralDirectoryRecord(for file: UnsafeMutablePointer<FILE>)
        -> EndOfCentralDirectoryRecord? {
        var directoryEnd = 0
        var index = FileUnzipperConstants.minDirectoryEndOffset
        // Set file pointer position to end of file
        fseek(file, 0, SEEK_END)
        // Get the length of the file in bytes
        let archiveLength = ftell(file)
        // Find the end of central directory
        while directoryEnd == 0, index < FileUnzipperConstants.maxDirectoryEndOffset, index <= archiveLength {
            fseek(file, archiveLength - index, SEEK_SET)
            var potentialDirectoryEndTag: UInt32 = UInt32()
            fread(&potentialDirectoryEndTag, 1, MemoryLayout<UInt32>.size, file)
            if potentialDirectoryEndTag == UInt32(FileUnzipperConstants.endOfCentralDirectorySignature) {
                directoryEnd = archiveLength - index
                return ZipArchive.readStruct(from: file, at: directoryEnd)
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
                    sourceData = try provider(position, Swift.min(size - position, bufferSize))
                    if let sourceData = sourceData {
                        position += sourceData.count
                        stream.src_size = sourceData.count
                    }
                } catch { throw error }
            }
            if let sourceData = sourceData {
                sourceData.withUnsafeBytes { rawBufferPointer in
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
        let mask = 0xFFFF_FFFF as UInt32
        let bufferSize = data.count / MemoryLayout<UInt8>.size
        var result = checksum ^ mask
        FileUnzipperConstants.crcTable.withUnsafeBufferPointer { crcTablePointer in
            data.withUnsafeBytes { bufferPointer in
                let bytePointer = bufferPointer.bindMemory(to: UInt8.self)
                for bufferIndex in 0 ..< bufferSize {
                    let byte = bytePointer[bufferIndex]
                    let index = Int((result ^ UInt32(byte)) & 0xFF)
                    result = (result >> 8) ^ crcTablePointer[index]
                }
            }
        }
        return result ^ mask
    }
}

// Data helpers for a ZipArchive
extension ZipArchive {
    ///
    /// Scans the range of subdata from start to the size of T
    /// - Parameter start: The start position to start scanning from
    /// - Returns: The scanned subdata as T
    static func scanValue<T>(start: Int, data: Data) -> T {
        let subdata = data.subdata(in: start ..< start + MemoryLayout<T>.size)
        return subdata.withUnsafeBytes { $0.load(as: T.self) }
    }

    ///
    /// Initializes and returns a DataSerializable from a given file pointer and offset
    /// - Parameters:
    ///     - file: The C style file pointer
    ///     - offset: The offset to use to start reading data
    /// - Returns: The initialized DataSerializable
    static func readStruct<T: HeaderDataSerializable>(from file: UnsafeMutablePointer<FILE>, at offset: Int) -> T? {
        fseek(file, offset, SEEK_SET)
        guard let data = try? readChunk(of: T.size, from: file) else {
            return nil
        }
        let structure = T(data: data, additionalDataProvider: { (additionalDataSize) -> Data in
            try self.readChunk(of: additionalDataSize, from: file)
        })
        return structure
    }

    ///
    /// Reads a chunk of data of the given size from the file pointer
    /// - Parameters:
    ///     - size: The size in bytes of the chunk to read as an Int
    ///     - file: The C style file pointer to read the data from
    /// - Returns: The chunk of data read
    static func readChunk(of size: Int, from file: UnsafeMutablePointer<FILE>) throws -> Data {
        let alignment = MemoryLayout<UInt>.alignment
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
        let bytesRead = fread(bytes, 1, size, file)
        let error = ferror(file)
        if error > 0 {
            throw DataError.unreadableFile
        }
        return Data(bytesNoCopy: bytes, count: bytesRead, deallocator: .custom { buf, _ in buf.deallocate() })
    }

    ///
    /// Writes the chunk of data to the given C file pointer
    /// - Parameters:
    ///     - chunk: The chunk of data to write
    ///     - file: The C file pointer to write the data to
    /// - throws an error
    static func write(chunk: Data, to file: UnsafeMutablePointer<FILE>) throws {
        chunk.withUnsafeBytes { rawBufferPointer in
            if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 {
                let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                _ = fwrite(pointer, 1, chunk.count, file)
            }
        }
        let error = ferror(file)
        if error > 0 {
            throw DataError.unwritableFile
        }
    }
}

extension ZipArchive.EndOfCentralDirectoryRecord {
    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipArchive.EndOfCentralDirectoryRecord.size else { return nil }
        guard ZipArchive.scanValue(start: 0, data: data) == endOfCentralDirectorySignature else { return nil }
        numberOfDisk = ZipArchive.scanValue(start: 4, data: data)
        numberOfDiskStart = ZipArchive.scanValue(start: 6, data: data)
        totalNumberOfEntriesOnDisk = ZipArchive.scanValue(start: 8, data: data)
        totalNumberOfEntriesInCentralDirectory = ZipArchive.scanValue(start: 10, data: data)
        sizeOfCentralDirectory = ZipArchive.scanValue(start: 12, data: data)
        offsetToStartOfCentralDirectory = ZipArchive.scanValue(start: 16, data: data)
        zipFileCommentLength = ZipArchive.scanValue(start: 20, data: data)
        guard let commentData = try? provider(Int(zipFileCommentLength)) else { return nil }
        guard commentData.count == Int(zipFileCommentLength) else { return nil }
        zipFileCommentData = commentData
    }
}
