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

///
/// A File Unzipper utility class which unzips a zip file at a given source url to a destination url
///
public class FileUnzipper {
    
    ///
    /// Unzips a file at a given source url to a destination url
    /// - Paramaters:
    ///     - sourceURL: The URL pointing to the file to be unzipped
    ///     - destinationURL: The URL pointing to the destination where the unzipped contents will go
    /// - Throws: Throws when an error occurs during unzipping
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager()
        // Create directory at destination path
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        guard fileManager.itemExists(at: sourceURL) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: sourceURL.path])
        }
        // Create the ZipArchive structure to iterate through the zip entries and extract them
        guard let archive = ZipArchive(url: sourceURL) else {
            throw ZipArchive.ArchiveError.unreadableArchive
        }
        
        // Iterate through the archive entries and extract them individually
        for entry in archive {
            let path = entry.path
            let destinationEntryURL = destinationURL.appendingPathComponent(path)
            guard destinationEntryURL.isContained(in: destinationURL) else {
                throw CocoaError(.fileReadInvalidFileName,
                                 userInfo: [NSFilePathErrorKey: destinationEntryURL.path])
            }
            
            try archive.extract(entry, to: destinationEntryURL)
        }
    }
}
