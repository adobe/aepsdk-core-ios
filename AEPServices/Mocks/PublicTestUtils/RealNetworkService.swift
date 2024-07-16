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

@testable import AEPServices
import Foundation
import XCTest

/// Overriding `NetworkService` used for tests that require real outgoing network requests.
public class RealNetworkService: NetworkService {
    private let helper: NetworkRequestHelper = NetworkRequestHelper()
    /// Flag that indicates if the ``connectAsync(networkRequest:completionHandler:)`` method was called.
    /// Note that this property does not await and returns the status immediately.
    public var connectAsyncCalled: Bool {
        // Depends on `helper.orderedNetworkRequests` always being populated by `connectAsync` via
        // `helper.recordSentNetworkRequest`.
        // If this assumption changes, this flag logic will need to be updated.
        !helper.orderedNetworkRequests.isEmpty
    }

    public override init() {}

    public override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        helper.recordSentNetworkRequest(networkRequest)
        super.connectAsync(networkRequest: networkRequest, completionHandler: { (connection: HttpConnection) in
            self.helper.addResponse(for: networkRequest, responseConnection: connection)
            self.helper.countDownExpected(networkRequest: networkRequest)

            // Finally call the original completion handler
            completionHandler?(connection)
        })
    }

    /// Immediately returns the associated responses (if any) for the provided network request **without awaiting**.
    ///
    /// Note: To await network responses for a given request, make sure to set an expectation
    /// using ``setExpectation(for:expectedCount:file:line:)`` then await the expectation using
    /// ``assertAllNetworkRequestExpectations(ignoreUnexpectedRequests:timeout:file:line:)``.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which the response should be returned.
    /// - Returns: The array of `HttpConnection` responses for the given request or `nil` if not found.
    /// - seeAlso: ``assertAllNetworkRequestExpectations(ignoreUnexpectedRequests:timeout:file:line:)``
    public func getResponses(for networkRequest: NetworkRequest) -> [HttpConnection]? {
        return helper.getResponses(for: networkRequest)
    }

    // MARK: - Passthrough for shared helper APIs
    /// Asserts that the correct number of network requests were seen for all previously set network request expectations.
    /// - Parameters:
    ///   - ignoreUnexpectedRequests: A Boolean value indicating whether unexpected requests should be ignored. Defaults to `true`.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - SeeAlso: ``setExpectation(for:expectedCount:file:line:)``
    public func assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: Bool = true, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        helper.assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: ignoreUnexpectedRequests, timeout: timeout, file: file, line: line)
    }

    /// Immediately returns all sent network requests (if any) **without awaiting**.
    ///
    /// Note: To await network responses for a given request, make sure to set an expectation
    /// using ``setExpectation(for:expectedCount:file:line:)``
    /// then await the expectation using ``assertAllNetworkRequestExpectations(ignoreUnexpectedRequests:timeout:file:line:)``.
    ///
    /// - Returns: An array of `NetworkRequest` objects representing all sent network requests.
    public func getNetworkRequests() -> [NetworkRequest] {
        return helper.orderedNetworkRequests
    }

    /// Returns the network request(s) sent through the Core NetworkService, or empty if none was found.
    ///
    /// Use this method after calling ``setExpectation(for:expectedCount:file:line:)`` to wait for expected requests.
    ///
    /// - Parameters:
    ///   - url: The URL `String` of the `NetworkRequest` to get.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` to get.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - Returns: An array of `NetworkRequest`s that match the provided `url` and `httpMethod`. Returns an empty array if no matching requests were dispatched.
    ///
    /// - SeeAlso:
    ///     - ``setExpectation(for:expectedCount:file:line:)``
    public func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        guard let url = URL(string: url) else {
            return []
        }
        return getNetworkRequestsWith(url: url, httpMethod: httpMethod, timeout: timeout, file: file, line: line)
    }

    /// Returns the network request(s) sent through the Core NetworkService, or empty if none was found.
    ///
    /// Use this method after calling ``setExpectation(for:expectedCount:file:line:)`` to wait for expected
    /// requests.
    ///
    /// - Parameters:
    ///   - url: The URL `String` of the `NetworkRequest` to get.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` to get.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - Returns: An array of `NetworkRequest`s that match the provided `url` and `httpMethod`. Returns an empty array if no matching requests were dispatched.
    ///
    /// - SeeAlso:
    ///     - ``setExpectation(for:expectedCount:file:line:)``
    public func getNetworkRequestsWith(url: URL, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        return helper.getNetworkRequestsWith(url: url, httpMethod: httpMethod, timeout: timeout, file: file, line: line)
    }

    /// Resets all stored network request elements and expectations.
    public func reset() {
        helper.reset()
    }

    /// Sets the expected number of times a network request should be sent.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` to set the expectation for.
    ///   - expectedCount: The number of times the request is expected to be sent. The default value is 1.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    public func setExpectation(for networkRequest: NetworkRequest, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        helper.setExpectation(for: networkRequest, expectedCount: expectedCount, file: file, line: line)
    }
}
