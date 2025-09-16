/*
 Copyright 2025 Adobe. All rights reserved.
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
    /// Creates a directory, if needed, at the provided file system URL's path.
    /// - Parameter url: file manager url for the directory to be created.
    /// - Returns `true` if the directory was successfully created, or already existed previously.
    public func createDirectoryIfNeeded(at url: URL) -> Bool {
        let LOG_TAG = "FileManager+Directories"
        
        do {
            Log.debug(label: LOG_TAG, "Attempting to create directory at '\(url.path)'")
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            try setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: url.path)
            Log.debug(label: LOG_TAG, "Successfully created directory.")
            return true
        } catch {
            Log.warning(label: LOG_TAG, "Unable to create directory at '\(url.path)': \(error.localizedDescription)")
            return false
        }
    }
}
