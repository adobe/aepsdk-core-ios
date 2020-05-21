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

/// This service provides system info as needed and is a WIP
public protocol SystemInfoService {

    /// Gets a system property for the given key
    ///  - Parameter key: The key to be used to get the property value
    ///  - Return: `String` representation of the property
    func getProperty(for key: String) -> String?
    
    /// Gets a system asset for the given path
    ///  - Parameter fileName: The asset's name
    ///  - Parameter fileType: The file's extension e.g "txt", "json"
    ///  - Return: `String?` representation of the asset,
    func getAsset(fileName: String, fileType: String) -> String?
    
    /// Gets a system asset for the given path
    ///  - Parameter fileName: The asset's name
    ///  - Parameter fileType: The file's extension e.g "txt", "json"
    ///  - Return: `[UInt8]?` representation of the asset    
    func getAsset(fileName: String, fileType: String) -> [UInt8]?
    
    /// Gets the default platform/device user agent
    /// - Return: `String` representing the default user agent
    func getDefaultUserAgent() -> String
    
    /// Returns the currently selected / active locale name (as set by the user on the system).
    /// - Return: `String` representation of the locale name
    func getActiveLocaleName() -> String
}
