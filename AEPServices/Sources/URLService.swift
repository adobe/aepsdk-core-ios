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
import UIKit

/// A concrete implementation of protocol `URLOpening`
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
class URLService: URLOpening {
    private let LOG_PREFIX = "URLService"

    ///  Open the resource at the specified URL asynchronously.
    /// - Parameter url: the url to open
    /// - Returns: true if have processed the open url action; otherwise you can override the `URLService` and return false for specific urls which not allowed to open
    @discardableResult func openUrl(_ url: URL) -> Bool {
        DispatchQueue.main.async {
            Log.trace(label: self.LOG_PREFIX, "Attempting to open URL: \(url)")
            UIApplication.shared.open(url) { success in
                if !success {
                    Log.warning(label: self.LOG_PREFIX, "Unable to open URL: \(url)")
                }
            }
        }
        return true
    }
}
