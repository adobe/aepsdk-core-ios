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

@testable import AEPServices
import AEPServicesMocks
import XCTest

class NetworkServiceAvailabilityTests: XCTestCase {
    private class MockPathProvider: NetworkPathAvailabilityProviding {
        var isAvailable = true
        func isPathAvailable() -> Bool { isAvailable }
    }

    private class MockHealthProvider: NetworkHealthCheckProviding {
        var isHealthy = true
        var callCount = 0
        func performHealthCheck(completion: @escaping (Bool) -> Void) {
            callCount += 1
            completion(isHealthy)
        }
    }

    func testIsNetworkAvailable_returnsFalseWhenPathUnavailable() {
        let pathProvider = MockPathProvider()
        pathProvider.isAvailable = false
        let service = NetworkService(pathProvider: pathProvider)

        XCTAssertFalse(service.isNetworkAvailable())
    }

    func testIsNetworkAvailable_usesCachedHealthWhenRequired() {
        let pathProvider = MockPathProvider()
        let healthProvider = MockHealthProvider()
        healthProvider.isHealthy = true

        let endpoint = URL(string: "https://health.example.com/ping")!
        let configuration = NetworkAvailabilityConfiguration(
            healthCheck: NetworkHealthCheckConfiguration(endpoint: endpoint, cacheTTL: 60),
            requireHealthCheckWhenConfigured: true
        )

        let service = NetworkService(pathProvider: pathProvider)
        service.configuration = configuration
        service.setHealthCheckProvider(healthProvider)

        XCTAssertFalse(service.isNetworkAvailable())

        let expectation = expectation(description: "health check")
        service.checkNetworkAvailability { result in
            XCTAssertTrue(result.isAvailable)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(service.isNetworkAvailable())
        XCTAssertEqual(1, healthProvider.callCount)
    }

    func testCheckNetworkAvailability_returnsPathOnlyWithoutHealthCheck() {
        let pathProvider = MockPathProvider()
        let service = NetworkService(pathProvider: pathProvider)
        let expectation = expectation(description: "path only")

        service.checkNetworkAvailability { result in
            XCTAssertEqual(.pathOnly, result.status)
            XCTAssertTrue(result.isAvailable)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    /// A customer who overrides `ServiceProvider.shared.networkService` (the documented Networking override point)
    /// expects that override to apply to *all* outbound SDK traffic, not just extension hits. The default health
    /// check must route through it too, instead of silently escaping through the SDK's own internal transport.
    func testCheckNetworkAvailability_defaultHealthCheckUsesOverriddenNetworkService() {
        let endpoint = URL(string: "https://health.example.com/ping")!
        let mockNetworkService = MockNetworkService()
        mockNetworkService.setMockResponse(
            url: endpoint.absoluteString,
            httpMethod: .get,
            responseConnection: HttpConnection(
                data: nil,
                response: HTTPURLResponse(url: endpoint, statusCode: 200, httpVersion: nil, headerFields: nil),
                error: nil
            )
        )
        ServiceProvider.shared.networkService = mockNetworkService
        defer { ServiceProvider.shared.reset() }

        let pathProvider = MockPathProvider()
        let service = NetworkService(pathProvider: pathProvider)
        service.configuration = NetworkAvailabilityConfiguration(
            healthCheck: NetworkHealthCheckConfiguration(endpoint: endpoint),
            requireHealthCheckWhenConfigured: true
        )

        let expectation = expectation(description: "health check via overridden networkService")
        service.checkNetworkAvailability { result in
            XCTAssertTrue(result.isAvailable)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }
}
