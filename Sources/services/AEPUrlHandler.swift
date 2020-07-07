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

/// Opens the resource specified by the URL.
class AEPUrlHandler {
    public typealias URLHandler = (String) -> Bool
    /// Set the provided callback with a url string and call this callback function before SDK extension open url action
    static var urlHandler: URLHandler?

    /// Open the resource at the specified URL asynchronously
    /// - Parameter url: the url to open
    static func openUrl(_ url: URL) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url) { success in
                if !success {
                    print("Fail to open url: \(url)")
                }
            }
        }
    }
}
