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
/// File Unzipper protocol
///
public protocol Unzipper {
    ///
    /// Unzips a file at a given source url to a destination url
    /// - Paramaters:
    ///     - sourceURL: The URL pointing to the file to be unzipped
    ///     - destinationURL: The URL pointing to the destination where the unzipped contents will go
    /// - Returns: Boolean indicating if unzipping succeeded or failed
    func unzipItem(at sourceURL: URL, to destinationURL: URL) -> Bool
}

public class FileUnzipper: Unzipper {

    public func unzipItem(at sourceURL: URL, to destinationURL: URL) -> Bool {
        let fileManager = FileManager()
        // Create directory at destination path
        guard let _ = try? fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil) else { return false
        }
        guard fileManager.itemExists(at: sourceURL) else {
            return false
        }
        // Create the ZipArchive structure to iterate through the zip entries and extract them
        guard let archive = ZipArchive(url: sourceURL) else {
            return false
        }
        
        // Iterate through the archive entries and extract them individually
        for entry in archive {
            let path = entry.path
            let destinationEntryURL = destinationURL.appendingPathComponent(path)
            guard destinationEntryURL.isContained(in: destinationURL) else {
                return false
            }
            
            guard let _  = try? archive.extract(entry, to: destinationEntryURL) else { return false }
        }
        
        return true
    }
}
