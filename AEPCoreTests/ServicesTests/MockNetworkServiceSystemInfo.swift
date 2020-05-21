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
@testable import AEPCore

struct MockNetworkServiceSystemInfo: SystemInfoService {
    static let MOCK_USER_AGENT = "mock-user-agent"
    static let MOCK_LOCALE_NAME = "mock-locale-name"
    
    func getProperty(for key: String) -> String? {
        return nil
    }
    
    func getAsset(fileName: String, fileType: String) -> String? {
        return nil
    }
    
    func getAsset(fileName: String, fileType: String) -> [UInt8]? {
        return nil
    }
    
    func getDefaultUserAgent() -> String {
        return MockNetworkServiceSystemInfo.MOCK_USER_AGENT
    }
    
    func getActiveLocaleName() -> String {
        return MockNetworkServiceSystemInfo.MOCK_LOCALE_NAME
    }
    
    
}
