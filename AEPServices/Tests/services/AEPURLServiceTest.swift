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

@testable import AEPServices
import XCTest

class AEPURLServiceTest: XCTestCase {
    private let urlService = AEPServiceProvider.shared.urlService

    override func setUp() {
        AEPServiceProvider.shared.urlService = AEPURLService()
    }

    public class URLServiceReturnFalse: URLOpening {
        public func openUrl(_ url: URL) -> Bool {
            return false
        }
    }

    public class URLServiceReturnTrue: URLOpening {
        public func openUrl(_ url: URL) -> Bool {
            return true
        }
    }

    func testOpenUrl() throws {
        if let url = URL(string: "adobe.com") {
            XCTAssertTrue(urlService.openUrl(url))
        }
    }

    func testOverrideUrlHandlerReturnFalse() throws {
        AEPServiceProvider.shared.urlService = URLServiceReturnFalse()
        if let url = URL(string: "adobe.com") {
            XCTAssertFalse(AEPServiceProvider.shared.urlService.openUrl(url))
        }
    }

    func testOverrideUrlHandlerReturnTrue() throws {
        AEPServiceProvider.shared.urlService = URLServiceReturnTrue()
        if let url = URL(string: "adobe.com") {
            XCTAssertTrue(AEPServiceProvider.shared.urlService.openUrl(url))
        }
    }
}
