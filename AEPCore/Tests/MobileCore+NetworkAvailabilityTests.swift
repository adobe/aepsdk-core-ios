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
import AEPServices
import AEPServicesMocks
import XCTest

class MobileCoreNetworkAvailabilityTests: XCTestCase {
    private var mockService: MockNetworkAvailabilityService!

    override func setUp() {
        mockService = MockNetworkAvailabilityService(isAvailable: true)
        ServiceProvider.shared.networkAvailabilityService = mockService
    }

    override func tearDown() {
        MobileCore.resetNetworkAvailabilityProvider()
    }

    func testIsNetworkAvailable_delegatesToServiceProvider() {
        mockService.isAvailable = false
        XCTAssertFalse(MobileCore.isNetworkAvailable())
    }

    func testSetNetworkAvailabilityConfiguration_updatesServiceConfiguration() {
        let endpoint = URL(string: "https://health.example.com/ping")!
        let healthCheck = NetworkHealthCheckConfiguration(endpoint: endpoint)
        let configuration = NetworkAvailabilityConfiguration(healthCheck: healthCheck, requireHealthCheckWhenConfigured: true)

        MobileCore.setNetworkAvailabilityConfiguration(configuration)

        XCTAssertEqual(endpoint, mockService.configuration.healthCheck?.endpoint)
        XCTAssertTrue(mockService.configuration.requireHealthCheckWhenConfigured)
    }

    func testCheckNetworkAvailability_delegatesToServiceProvider() {
        let expectation = expectation(description: "checkNetworkAvailability completion")
        mockService.checkResult = NetworkAvailabilityResult(status: .healthCheckFailed)

        MobileCore.checkNetworkAvailability { result in
            XCTAssertEqual(.healthCheckFailed, result.status)
            XCTAssertFalse(result.isAvailable)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(1, mockService.checkCallCount)
    }
}
