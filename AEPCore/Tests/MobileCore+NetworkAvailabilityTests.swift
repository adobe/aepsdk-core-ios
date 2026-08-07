/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPCore
@testable import AEPServices
import XCTest

class MobileCoreNetworkAvailabilityTests: XCTestCase {
    /// A customer's custom `Networking` override implementing their own availability logic — the
    /// documented pattern for customizing this (see: overriding `NetworkService`).
    private class MockNetworking: Networking {
        var isAvailable = true

        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {}

        func isNetworkAvailable() -> Bool {
            return isAvailable
        }
    }

    private var mockNetworking: MockNetworking!

    override func setUp() {
        mockNetworking = MockNetworking()
        ServiceProvider.shared.networkService = mockNetworking
    }

    override func tearDown() {
        ServiceProvider.shared.reset()
    }

    func testIsNetworkAvailable_delegatesToServiceProviderNetworkService() {
        mockNetworking.isAvailable = false
        XCTAssertFalse(MobileCore.isNetworkAvailable())

        mockNetworking.isAvailable = true
        XCTAssertTrue(MobileCore.isNetworkAvailable())
    }
}
