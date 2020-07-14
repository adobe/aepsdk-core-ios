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

extension FileManager {
    typealias CentralDirectoryStructure = ZipEntry.CentralDirectoryStructure


    // MARK: - Helpers
    
    ///
    /// Checks if an item exists at the given url
    /// - Parameter url: The url to check
    /// - Returns: a boolean indicating if an item exists or not
    func itemExists(at url: URL) -> Bool {
        return (try? url.checkResourceIsReachable()) == true
    }
    
    ///
    /// Creates a parent directory structure for a given url
    /// - Parameter url: The url to create the parent directory for
    /// - Throws: throws if unable to create the parent directory
    func createParentDirectoryStructure(for url: URL) throws {
        let parentDirectoryURL = url.deletingLastPathComponent()
        try self.createDirectory(at: parentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    ///
    /// Returns the File attributes for the given ZipEntry
    /// - Parameter entry: The ZipEntry to get the attributes for
    /// - Returns: The attributes as a dictionary
    class func attributes(from entry: ZipEntry) -> [FileAttributeKey: Any] {
        let centralDirectoryStructure = entry.centralDirectoryStructure
        let fileTime = centralDirectoryStructure.lastModFileTime
        let fileDate = centralDirectoryStructure.lastModFileDate
        let defaultPermissions = FileUnzipperConstants.defaultFilePermissions
        var attributes = [.posixPermissions: defaultPermissions] as [FileAttributeKey: Any]
        attributes[.modificationDate] = Date(dateTime: (fileDate, fileTime))
        let versionMadeBy = centralDirectoryStructure.versionMadeBy
        guard let osType = ZipEntry.OSType(rawValue: UInt(versionMadeBy >> 8)) else { return attributes }

        let externalFileAttributes = centralDirectoryStructure.externalFileAttributes
        let permissions = self.permissions(for: externalFileAttributes, osType: osType)
        attributes[.posixPermissions] = NSNumber(value: permissions)
        return attributes
    }
    
    ///
    /// Gets the posix permissions for the ZipEntry
    /// - Parameters
    ///     - externalFileAttributes: The external file attributes from teh central directory structure
    ///     - osType: The OS type
    /// - Returns: The permissions for the ZipEntry as UInt16
    class func permissions(for externalFileAttributes: UInt32, osType: ZipEntry.OSType) -> UInt16 {
        switch osType {
        case .unix, .osx:
            let permissions = mode_t(externalFileAttributes >> 16) & (~S_IFMT)
            let defaultPermissions = FileUnzipperConstants.defaultFilePermissions
            return permissions == 0 ? defaultPermissions : UInt16(permissions)
        default:
            return FileUnzipperConstants.defaultFilePermissions
        }
    }
}

extension Date {
    init(dateTime: (UInt16, UInt16)) {
        var msdosDateTime = Int(dateTime.0)
        msdosDateTime <<= 16
        msdosDateTime |= Int(dateTime.1)
        var unixTime = tm()
        unixTime.tm_sec = Int32((msdosDateTime&31)*2)
        unixTime.tm_min = Int32((msdosDateTime>>5)&63)
        unixTime.tm_hour = Int32((Int(dateTime.1)>>11)&31)
        unixTime.tm_mday = Int32((msdosDateTime>>16)&31)
        unixTime.tm_mon = Int32((msdosDateTime>>21)&15)
        unixTime.tm_mon -= 1 // UNIX time struct month entries are zero based.
        unixTime.tm_year = Int32(1980+(msdosDateTime>>25))
        unixTime.tm_year -= 1900 // UNIX time structs count in "years since 1900".
        let time = timegm(&unixTime)
        self = Date(timeIntervalSince1970: TimeInterval(time))
    }

}

extension URL {
    func isContained(in parentDirectoryURL: URL) -> Bool {
        // Ensure this URL is contained in the passed in URL
        let parentDirectoryURL = URL(fileURLWithPath: parentDirectoryURL.path, isDirectory: true).standardized
        return self.standardized.absoluteString.hasPrefix(parentDirectoryURL.absoluteString)
    }
}
