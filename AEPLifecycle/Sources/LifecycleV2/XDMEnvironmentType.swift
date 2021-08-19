/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Represents an XDM environment type
enum XDMEnvironmentType: String, Encodable {
    case application

    /// Creates an `XDMEnvironmentType` from a run mode `String`
    /// - Parameter runMode: The current run mode for the system as described by the `SystemInfoService`
    /// - Returns: The matching `XDMEnvironmentType` for the run mode, nil if no matches found
    static func from(runMode: String?) -> XDMEnvironmentType? {
        guard let runMode = runMode else { return nil }
        if runMode.caseInsensitiveCompare("Application") == .orderedSame {
            return .application
        }

        return nil
    }
}
