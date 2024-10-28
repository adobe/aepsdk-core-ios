//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import XCTest

@testable import AEPServices

/// `Networking` conforming network service utility used for tests that require mocked network requests and mocked responses.
public class MockNetworkService: Networking {
    private let helper: NetworkRequestHelper = NetworkRequestHelper()
    private var responseDelay: UInt32

    /// Flag that indicates if the ``connectAsync(networkRequest:completionHandler:)`` method was called.
    /// Note that this property does not await and returns the status immediately.
    public var connectAsyncCalled: Bool {
        // Depends on `helper.orderedNetworkRequests` always being populated by `connectAsync` via
        // `helper.recordSentNetworkRequest`.
        // If this assumption changes, this flag logic will need to be updated.
        !helper.orderedNetworkRequests.isEmpty
    }

    /// How many times the ``connectAsync(networkRequest:completionHandler:)`` method was called.
    /// Note that this property does not await and returns the value immediately.
    public var connectAsyncCallCount: Int {
        // Depends on `helper.orderedNetworkRequests` always being populated by `connectAsync` via
        // `helper.recordSentNetworkRequest`.
        // If this assumption changes, this flag logic will need to be updated.
        helper.orderedNetworkRequests.count
    }

    // Public initializer
    public init(responseDelay: UInt32 = 0) {
        self.responseDelay = responseDelay
    }

    public func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        helper.recordSentNetworkRequest(networkRequest)

        if self.responseDelay > 0 {
            sleep(self.responseDelay)
        }

        if let response = self.getMockResponse(for: networkRequest) {
            completionHandler?(response)
        } else {
            // Default mock response
            completionHandler?(
                HttpConnection(
                    data: "".data(using: .utf8),
                    response: HTTPURLResponse(
                        url: networkRequest.url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    ),
                    error: nil
                )
            )
        }

        // Do countdown after notifying completion handler to avoid prematurely ungating awaits
        // before required network logic finishes
        helper.countDownExpected(networkRequest: networkRequest)
    }

    /// Resets all stored network request elements and expectations. Also resets `responseDelay` to 0.
    public func reset() {
        responseDelay = 0
        helper.reset()
    }

    /// Sets the provided delay for all network responses, until reset.
    /// - Parameter delaySec: delay in seconds
    /// - SeeAlso: ``reset()``
    public func enableNetworkResponseDelay(timeInSeconds: UInt32) {
        responseDelay = timeInSeconds
    }

    /// Sets a mock network response for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest`for which the mock response is being set.
    ///   - responseConnection: The `HttpConnection` to set as a response. If `nil` is provided, a default HTTP status code `200` response is used.
    public func setMockResponse(for networkRequest: NetworkRequest, responseConnection: HttpConnection) {
        helper.removeAllResponses(for: networkRequest)
        helper.addResponse(for: networkRequest, responseConnection: responseConnection)
    }

    /// Sets a mock network response for the provided network request.
    ///
    /// - Parameters:
    ///   - url: The URL `String` of the `NetworkRequest` for which the mock response is being set.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` for which the mock response is being set.
    ///   - responseConnection: The `HttpConnection` to set as a response. If `nil` is provided, a default HTTP status code `200` response is used.
    public func setMockResponse(url: String, httpMethod: HttpMethod = .post, responseConnection: HttpConnection) {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return
        }
        setMockResponse(for: networkRequest, responseConnection: responseConnection)
    }

    /// Sets a mock network response for the provided network request.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the `NetworkRequest` for which the mock response is being set.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` for which the mock response is being set.
    ///   - responseConnection: The `HttpConnection` to set as a response. If `nil` is provided, a default HTTP status code `200` response is used.
    public func setMockResponse(url: URL, httpMethod: HttpMethod = .post, responseConnection: HttpConnection) {
        setMockResponse(for: NetworkRequest(url: url, httpMethod: httpMethod), responseConnection: responseConnection)
    }

    /// Immediately returns all sent network requests (if any) **without awaiting**.
    ///
    /// Note: To await network responses for a given request, make sure to set an expectation
    /// using ``setExpectationForNetworkRequest(url:httpMethod:expectedCount:file:line:)``
    /// then await the expectation using ``assertAllNetworkRequestExpectations(ignoreUnexpectedRequests:timeout:file:line:)``.
    ///
    /// - Returns: An array of ``NetworkRequest`` objects representing all sent network requests.
    public func getNetworkRequests() -> [NetworkRequest] {
        return helper.orderedNetworkRequests
    }

    /// Returns all network requests that match the provided network request using ``TestableNetworkRequest/isEqual(_:)``.
    ///
    /// This method waits for the specified network request to be fulfilled within the provided timeout interval,
    /// ensuring that any expected requests are received. If no expectation exists for the provided request,
    /// the method will perform a regular wait for the specified timeout duration.
    ///
    /// - Parameters:
    ///   - url: The URL ``String`` of the ``NetworkRequest`` to get.
    ///   - httpMethod: The HTTP method of the ``NetworkRequest`` to get.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - Returns: An array of ``NetworkRequest``s that match the provided ``url`` and ``httpMethod``. Returns an empty array if no matching requests were dispatched.
    ///
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(url:httpMethod:expectedCount:file:line:)``
    public func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        guard let url = URL(string: url) else {
            return []
        }
        return getNetworkRequestsWith(url: url, httpMethod: httpMethod, timeout: timeout, file: file, line: line)
    }

    /// Returns all network requests that match the provided network request using ``TestableNetworkRequest/isEqual(_:)``.
    ///
    /// This method waits for the specified network request to be fulfilled within the provided timeout interval,
    /// ensuring that any expected requests are received. If no expectation exists for the provided request,
    /// the method will perform a regular wait for the specified timeout duration.
    ///
    /// - Parameters:
    ///   - url: The ``URL`` of the ``NetworkRequest`` to get.
    ///   - httpMethod: The HTTP method of the ``NetworkRequest`` to get.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - Returns: An array of ``NetworkRequest``s that match the provided ``url`` and ``httpMethod``. Returns an empty array if no matching requests were dispatched.
    ///
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(url:httpMethod:expectedCount:file:line:)``
    public func getNetworkRequestsWith(url: URL, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        return helper.getNetworkRequestsWith(url: url, httpMethod: httpMethod, timeout: timeout, file: file, line: line)
    }

    /// Sets the expected number of times a network request should be sent.
    ///
    /// - Parameters:
    ///   - url: The URL ``String`` of the ``NetworkRequest`` for which the expectation is set.
    ///   - httpMethod: The HTTP method of the ``NetworkRequest`` for which the expectation is set.
    ///   - expectedCount: The number of times the request is expected to be sent. The default value is 1.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    public func setExpectationForNetworkRequest(url: String, httpMethod: HttpMethod, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return
        }
        helper.setExpectation(for: networkRequest, expectedCount: expectedCount, file: file, line: line)
    }

    /// Asserts that the correct number of network requests were seen for all previously set network request expectations.
    ///
    /// - Parameters:
    ///   - ignoreUnexpectedRequests: A Boolean value indicating whether unexpected requests should be ignored. Defaults to `true`.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(url:httpMethod:expectedCount:file:line:)``
    public func assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: Bool = true, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        helper.assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: ignoreUnexpectedRequests, timeout: timeout, file: file, line: line)
    }

    // MARK: - Private helpers
    // MARK: Network request response helpers
    private func getMockResponse(for networkRequest: NetworkRequest) -> HttpConnection? {
        return helper.getResponses(for: networkRequest)?.first
    }
}
