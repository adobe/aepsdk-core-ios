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

/// A sequence of uncompressed or compressed ZIP entries.
///
/// You use an `Archive` to create, read or update ZIP files.
/// To read an existing ZIP file, you have to pass in an existing file `URL` and `AccessMode.read`:
///
///     var archiveURL = URL(fileURLWithPath: "/path/file.zip")
///     var archive = Archive(url: archiveURL, accessMode: .read)
///
/// An `Archive` is a sequence of entries. You can
/// iterate over an archive using a `for`-`in` loop to get access to individual `Entry` objects:
///
///     for entry in archive {
///         print(entry.path)
///     }
///
/// Each `Entry` in an `Archive` is represented by its `path`. You can
/// use `path` to retrieve the corresponding `Entry` from an `Archive` via subscripting:
///
///     let entry = archive['/path/file.txt']
///
/// To create a new `Archive`, pass in a non-existing file URL and `AccessMode.create`. To modify an
/// existing `Archive` use `AccessMode.update`:
///
///     var archiveURL = URL(fileURLWithPath: "/path/file.zip")
///     var archive = Archive(url: archiveURL, accessMode: .update)
///     try archive?.addEntry("test.txt", relativeTo: baseURL, compressionMethod: .deflate)
final class ZipArchive: Sequence {
    
    typealias LocalFileHeader = ZipEntry.LocalFileHeader
    typealias DataDescriptor = ZipEntry.DataDescriptor
    typealias CentralDirectoryStructure = ZipEntry.CentralDirectoryStructure

    /// An error that occurs during reading, creating or updating a ZIP file.
    public enum ArchiveError: Error {
        /// Thrown when an archive file is either damaged or inaccessible.
        case unreadableArchive
        /// Thrown when an archive is either opened with AccessMode.read or the destination file is unwritable.
        case unwritableArchive
        /// Thrown when the path of an `Entry` cannot be stored in an archive.
        case invalidEntryPath
        /// Thrown when an `Entry` can't be stored in the archive with the proposed compression method.
        case invalidCompressionMethod
        /// Thrown when the start of the central directory exceeds `UINT32_MAX`
        case invalidStartOfCentralDirectoryOffset
        /// Thrown when an archive does not contain the required End of Central Directory Record.
        case missingEndOfCentralDirectoryRecord
        /// Thrown when an extract, add or remove operation was canceled.
        case cancelledOperation
    }

    struct EndOfCentralDirectoryRecord: DataSerializable {

        let endOfCentralDirectorySignature = UInt32(RulesUnzipperConstants.endOfCentralDirectorySignature)
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

    /// URL of an Archive's backing file.
    public let url: URL
    /// Access mode for an archive file.
    var archiveFile: UnsafeMutablePointer<FILE>
    var endOfCentralDirectoryRecord: EndOfCentralDirectoryRecord

    /// Initializes a new ZIP `Archive`.
    ///
    /// You can use this initalizer to create new archive files or to read and update existing ones.
    /// The `mode` parameter indicates the intended usage of the archive: `.read`, `.create` or `.update`.
    /// - Parameters:
    ///   - url: File URL to the receivers backing file.
    ///   - mode: Access mode of the receiver.
    ///   - preferredEncoding: Encoding for entry paths. Overrides the encoding specified in the archive.
    ///                        This encoding is only used when _decoding_ paths from the receiver.
    ///                        Paths of entries added with `addEntry` are always UTF-8 encoded.
    /// - Returns: An archive initialized with a backing file at the passed in file URL and the given access mode
    ///   or `nil` if the following criteria are not met:
    /// - Note:
    ///   - The file URL _must_ point to an existing file for `AccessMode.read`.
    ///   - The file URL _must_ point to a non-existing file for `AccessMode.create`.
    ///   - The file URL _must_ point to an existing file for `AccessMode.update`.
    public init?(url: URL) {
        self.url = url
        guard let (archiveFile, endOfCentralDirectoryRecord) = ZipArchive.configureFileBacking(for: url) else {
            return nil
        }
        self.archiveFile = archiveFile
        self.endOfCentralDirectoryRecord = endOfCentralDirectoryRecord
        // TODO: - Test if this is needed or not. As of now, doesn't seem like it is.
//        setvbuf(self.archiveFile, nil, _IOFBF, Int(RulesUnzipperConstants.defaultPOSIXBufferSize))
    }

    deinit {
        fclose(self.archiveFile)
    }
    
    /// Read a ZIP `Entry` from the receiver and write it to `url`.
    ///
    /// - Parameters:
    ///   - entry: The ZIP `Entry` to read.
    ///   - url: The destination file URL.
    ///   - bufferSize: The maximum size of the read buffer and the decompression buffer (if needed).
    ///   - skipCRC32: Optional flag to skip calculation of the CRC32 checksum to improve performance.
    ///   - progress: A progress object that can be used to track or cancel the extract operation.
    /// - Returns: The checksum of the processed content or 0 if the `skipCRC32` flag was set to `true`.
    /// - Throws: An error if the destination file cannot be written or the entry contains malformed content.
    @discardableResult
    func extract(_ entry: ZipEntry, to url: URL, bufferSize: UInt32 = RulesUnzipperConstants.defaultReadChunkSize, skipCRC32: Bool = false,
                 progress: Progress? = nil) throws -> CRC32 {
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
        checksum = try self.extract(entry, bufferSize: bufferSize, skipCRC32: skipCRC32,
                                    progress: progress, consumer: consumer)
        let attributes = FileManager.attributes(from: entry)
        try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        return checksum
    }
    
    /// Read a ZIP `Entry` from the receiver and forward its contents to a `Consumer` closure.
    ///
    /// - Parameters:
    ///   - entry: The ZIP `Entry` to read.
    ///   - bufferSize: The maximum size of the read buffer and the decompression buffer (if needed).
    ///   - skipCRC32: Optional flag to skip calculation of the CRC32 checksum to improve performance.
    ///   - progress: A progress object that can be used to track or cancel the extract operation.
    ///   - consumer: A closure that consumes contents of `Entry` as `Data` chunks.
    /// - Returns: The checksum of the processed content or 0 if the `skipCRC32` flag was set to `true`..
    /// - Throws: An error if the destination file cannot be written or the entry contains malformed content.
    func extract(_ entry: ZipEntry, bufferSize: UInt32 = RulesUnzipperConstants.defaultReadChunkSize, skipCRC32: Bool = false,
                 progress: Progress? = nil, consumer: Consumer) throws -> CRC32 {
        var checksum = CRC32(0)
        fseek(self.archiveFile, entry.dataOffset, SEEK_SET)
        //progress?.totalUnitCount = self.totalUnitCountForReading(entry)
        checksum = try self.readCompressed(entry: entry, bufferSize: bufferSize,
                                           skipCRC32: skipCRC32, progress: progress, with: consumer)
        return checksum
    }
    //
    //    // MARK: - Helpers
    //
    private func readCompressed(entry: ZipEntry, bufferSize: UInt32, skipCRC32: Bool,
                                progress: Progress? = nil, with consumer: Consumer) throws -> CRC32 {
        let size = Int(entry.centralDirectoryStructure.compressedSize)
        return try Data.decompress(size: size, bufferSize: Int(bufferSize), skipCRC32: skipCRC32,
                                   provider: { (_, chunkSize) -> Data in
                                    return try Data.readChunk(of: chunkSize, from: self.archiveFile)
        }, consumer: { (data) in
            if progress?.isCancelled == true { throw ArchiveError.cancelledOperation }
            try consumer(data)
            progress?.completedUnitCount += Int64(data.count)
        })
    }

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

    // MARK: - Helpers

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
        var index = RulesUnzipperConstants.minDirectoryEndOffset
        fseek(file, 0, SEEK_END)
        let archiveLength = ftell(file)
        while directoryEnd == 0 && index < RulesUnzipperConstants.maxDirectoryEndOffset && index <= archiveLength {
            fseek(file, archiveLength - index, SEEK_SET)
            var potentialDirectoryEndTag: UInt32 = UInt32()
            fread(&potentialDirectoryEndTag, 1, MemoryLayout<UInt32>.size, file)
            if potentialDirectoryEndTag == UInt32(RulesUnzipperConstants.endOfCentralDirectorySignature) {
                directoryEnd = archiveLength - index
                return Data.readStruct(from: file, at: directoryEnd)
            }
            index += 1
        }
        return nil
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
