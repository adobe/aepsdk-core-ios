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

protocol DataSerializable {
    static var size: Int { get }
    init?(data: Data, additionalDataProvider: (Int) throws -> Data)
}

extension Data {
    enum DataError: Error {
        case unreadableFile
        case unwritableFile
    }
    
    ///
    /// Scans the range of subdata from start to the size of T
    /// - Parameter start: The start position to start scanning from
    /// - Returns: The scanned subdata as T
    func scanValue<T>(start: Int) -> T {
        let subdata = self.subdata(in: start..<start+MemoryLayout<T>.size)
        return subdata.withUnsafeBytes { $0.load(as: T.self) }
    }
    
    ///
    /// Initializes and returns a DataSerializable from a given file pointer and offset
    /// - Parameters:
    ///     - file: The C style file pointer
    ///     - offset: The offset to use to start reading data
    /// - Returns: The initialized DataSerializable
    static func readStruct<T>(from file: UnsafeMutablePointer<FILE>, at offset: Int) -> T? where T: DataSerializable {
        fseek(file, offset, SEEK_SET)
        guard let data = try? self.readChunk(of: T.size, from: file) else {
            return nil
        }
        let structure = T(data: data, additionalDataProvider: { (additionalDataSize) -> Data in
            return try self.readChunk(of: additionalDataSize, from: file)
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
        return Data(bytesNoCopy: bytes, count: bytesRead, deallocator: .custom({ buf, _ in buf.deallocate() }))
    }
    
    ///
    /// Writes the chunk of data to the given C file pointer
    /// - Parameters:
    ///     - chunk: The chunk of data to write
    ///     - file: The C file pointer to write the data to
    /// - throws an error
    static func write(chunk: Data, to file: UnsafeMutablePointer<FILE>) throws {
        chunk.withUnsafeBytes { (rawBufferPointer) in
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
