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

extension Data {
    enum CompressionError: Error {
        case invalidStream
        case corruptedData
    }

    /// Calculate the `CRC32` checksum of the receiver.
    ///
    /// - Parameter checksum: The starting seed.
    /// - Returns: The checksum calcualted from the bytes of the receiver and the starting seed.
    func crc32(checksum: CRC32) -> CRC32 {
        // The typecast is necessary on 32-bit platforms because of
        // https://bugs.swift.org/browse/SR-1774
        let mask = 0xffffffff as UInt32
        let bufferSize = self.count/MemoryLayout<UInt8>.size
        var result = checksum ^ mask
        RulesUnzipperConstants.crcTable.withUnsafeBufferPointer { crcTablePointer in
            self.withUnsafeBytes { bufferPointer in
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

    /// Decompress the output of `provider` and pass it to `consumer`.
    /// - Parameters:
    ///   - size: The compressed size of the data to be decompressed.
    ///   - bufferSize: The maximum size of the decompression buffer.
    ///   - provider: A closure that accepts a position and a chunk size. Returns a `Data` chunk.
    ///   - consumer: A closure that processes the result of the decompress operation.
    /// - Returns: The checksum of the processed content.
    static func decompress(size: Int, bufferSize: Int, provider: Provider, consumer: EntryDataConsumer) throws -> CRC32 {
        var crc32 = CRC32(0)
        let destPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destPointer.deallocate() }
        let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { streamPointer.deallocate() }
        var stream = streamPointer.pointee
        var status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
        guard status != COMPRESSION_STATUS_ERROR else { throw CompressionError.invalidStream }
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
                crc32 = outputData.crc32(checksum: crc32)
                stream.dst_ptr = destPointer
                stream.dst_size = bufferSize
            default: throw CompressionError.corruptedData
            }
        } while status == COMPRESSION_STATUS_OK
        return crc32
    }
}
