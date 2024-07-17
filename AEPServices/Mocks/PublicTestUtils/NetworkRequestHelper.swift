//
// Copyright 2020 Adobe. All rights reserved.
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

/// Implements shared utilities and logic for `NetworkService`/`Networking` class implementations
/// used for testing.
///
/// - See also:
///    - ``MockNetworkService``
///    - ``RealNetworkService``
class NetworkRequestHelper {
    private var _orderedNetworkRequests: ThreadSafeArray<NetworkRequest> = ThreadSafeArray()
    /// Matches sent `NetworkRequest`s with their corresponding `HttpConnection` responses.
    private var _networkResponses: ThreadSafeDictionary<TestableNetworkRequest, ThreadSafeArray<HttpConnection>> = ThreadSafeDictionary()

    private var networkRequests: ThreadSafeDictionary<TestableNetworkRequest, ThreadSafeArray<NetworkRequest>> = ThreadSafeDictionary()
    private var expectedNetworkRequests: ThreadSafeDictionary<TestableNetworkRequest, CountDownLatch> = ThreadSafeDictionary()

    var orderedNetworkRequests: [NetworkRequest] {
        return _orderedNetworkRequests.shallowCopy.map { $0.deepCopy() }
    }

    var networkResponses: [TestableNetworkRequest: [HttpConnection]] {
        return _networkResponses.shallowCopy.mapValues { value in
            return value.shallowCopy.map { $0.deepCopy() }
        }
    }

    func recordSentNetworkRequest(_ networkRequest: NetworkRequest) {
        print("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")

        _orderedNetworkRequests.append(networkRequest)

        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        if networkRequests[testableNetworkRequest] == nil {
            networkRequests[testableNetworkRequest] = ThreadSafeArray()
        }
        networkRequests[testableNetworkRequest]?.append(networkRequest)
    }

    func reset() {
        _orderedNetworkRequests.clear()
        _networkResponses = ThreadSafeDictionary()
        expectedNetworkRequests = ThreadSafeDictionary()
        networkRequests = ThreadSafeDictionary()
    }

    /// Decrements the expectation count for a given network request.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which the expectation count should be decremented.
    func countDownExpected(networkRequest: NetworkRequest) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        if let expectedRequest = expectedNetworkRequests.first(where: { key, _ in key == testableNetworkRequest }) {
            expectedRequest.value.countDown()
        }
    }

    /// Starts the expectation timer for the given network request, validating that all expected responses are received within
    /// the provided `timeout` duration.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` for which the expectation timer should be started.
    ///   - timeout: The maximum duration (in seconds) to wait for the expected responses before timing out.
    ///
    /// - Returns: A `DispatchTimeoutResult` with the result of the wait operation, or `nil` if the `NetworkRequest` does not match any expected request.
    private func awaitFor(networkRequest: NetworkRequest, timeout: TimeInterval) -> DispatchTimeoutResult? {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        if let expectedRequest = expectedNetworkRequests.first(where: { key, _ in key == testableNetworkRequest }) {
            return expectedRequest.value.await(timeout: timeout)
        }
        return nil
    }

    ///  Returns all sent network requests that match the provided network request using the
    ///  `TestableNetworkRequest.isEqual(_:)` method.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which to get matching requests.
    ///
    /// - Returns: An array of `NetworkRequest`s that match the specified `networkRequest`. If no matches are found, an empty array is returned.
    func getSentRequests(matching networkRequest: NetworkRequest) -> [NetworkRequest] {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        return networkRequests[testableNetworkRequest]?.shallowCopy ?? []
    }

    // MARK: - Network response helpers
    /// Adds a network response for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest`for which the response is being set.
    ///   - responseConnection: The `HttpConnection` to set as a response.
    func addResponse(for networkRequest: NetworkRequest, responseConnection: HttpConnection) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        if _networkResponses[testableNetworkRequest] == nil {
            _networkResponses[testableNetworkRequest] = ThreadSafeArray()
        }
        _networkResponses[testableNetworkRequest]?.append(responseConnection)
    }

    /// Removes all network responses for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` for which to remove all responses.
    func removeAllResponses(for networkRequest: NetworkRequest) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        _ = _networkResponses.removeValue(forKey: testableNetworkRequest)
    }

    /// Returns the network responses associated with the given network request.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which the response should be retrieved.
    /// - Returns: The array of `HttpConnection` responses associated with the provided `NetworkRequest`, or `nil` if no response was found.
    func getResponses(for networkRequest: NetworkRequest) -> [HttpConnection]? {
        return _networkResponses[TestableNetworkRequest(from: networkRequest)]?.shallowCopy.map { $0.deepCopy() }
    }

    // MARK: Assertion helpers

    /// Sets the expected number of times a network request should be sent.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` for which the expectation is set.
    ///   - expectedCount: The number of times the request is expected to be sent. The default value is 1.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func setExpectation(for networkRequest: NetworkRequest, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard expectedCount > 0 else {
            assertionFailure("Expected event count should be greater than 0", file: file, line: line)
            return
        }

        expectedNetworkRequests[TestableNetworkRequest(from: networkRequest)] = CountDownLatch(expectedCount)
    }

    /// Asserts that the correct number of network requests were seen for all previously set network request expectations.
    /// - Parameters:
    ///   - ignoreUnexpectedRequests: A Boolean value indicating whether unexpected requests should be ignored. Defaults to `true`.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - SeeAlso: ``setExpectation(for:expectedCount:file:line:)``
    func assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: Bool = true, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        if expectedNetworkRequests.isEmpty {
            if !ignoreUnexpectedRequests {
                assertUnexpectedRequests(file: file, line: line)
            }
            return
        }

        for expectedRequest in expectedNetworkRequests {
            let waitResult = expectedRequest.value.await(timeout: timeout)
            let expectedCount: Int32 = expectedRequest.value.getInitialCount()
            let receivedCount: Int32 = expectedRequest.value.getInitialCount() - expectedRequest.value.getCurrentCount()

            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut,
                           """
                           Timed out waiting for network request(s) with URL \(expectedRequest.key.url.absoluteString) and HTTPMethod
                           \(expectedRequest.key.httpMethod.toString()), expected \(expectedCount) but received \(receivedCount)
                           """,
                           file: file,
                           line: line)

            XCTAssertEqual(expectedCount,
                           receivedCount,
                           """
                           Expected \(expectedCount) network request(s) for URL \(expectedRequest.key.url.absoluteString) and HTTPMethod
                           \(expectedRequest.key.httpMethod.toString()), but received \(receivedCount)
                           """,
                           file: file,
                           line: line)
        }
        if ignoreUnexpectedRequests { return }
        assertUnexpectedRequests()
    }

    /// Asserts that there are no unexpected network requests, including both cases where the number of expected requests exceeds the set
    /// count and where completely unexpected requests are received.
    /// - Parameters:
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertUnexpectedRequests(timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        var unexpectedRequestsCount = 0
        var unexpectedRequestsAsString = ""
        for (sentRequest, requests) in networkRequests {
            let sentRequestURL = sentRequest.url.absoluteString
            let sentRequestHTTPMethod = sentRequest.httpMethod.toString()
            // Check if request is expected and it is over the expected count
            if let expectedRequest = expectedNetworkRequests[sentRequest] {
                _ = expectedRequest.await(timeout: timeout)
                let expectedCount: Int32 = expectedRequest.getInitialCount()
                let receivedCount: Int32 = expectedRequest.getInitialCount() - expectedRequest.getCurrentCount()
                XCTAssertEqual(expectedCount,
                               receivedCount,
                               """
                               Expected \(expectedCount) network request(s) for URL \(sentRequestURL) and HTTPMethod \(sentRequestHTTPMethod),
                               but received \(receivedCount)
                               """,
                               file: file,
                               line: line)
            }
            // Check for requests that don't have expectations set
            else {
                unexpectedRequestsCount += requests.count
                unexpectedRequestsAsString.append("(\(sentRequestURL), \(sentRequestHTTPMethod), \(requests.count)),")
                print("NetworkRequestHelper - Received unexpected network request with URL: \(sentRequestURL) and HTTPMethod: \(sentRequestHTTPMethod)")
            }
        }

        XCTAssertEqual(0,
                       unexpectedRequestsCount,
                       """
                       Received \(unexpectedRequestsCount) unexpected network request(s): \(unexpectedRequestsAsString)
                       """,
                       file: file,
                       line: line)
    }

    /// Returns the network request(s) sent through the Core NetworkService, or empty if none was found.
    ///
    /// Use this method after calling `setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)` to wait for expected requests.
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
    ///     - ``setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)``
    func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        guard let url = URL(string: url) else {
            return []
        }

        return getNetworkRequestsWith(url: url, httpMethod: httpMethod, timeout: timeout, file: file, line: line)
    }

    /// Returns the network request(s) sent through the Core NetworkService, or empty if none was found.
    ///
    /// Use this method after calling `setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)` to wait for expected requests.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the `NetworkRequest` to get.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` to get.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - Returns: An array of `NetworkRequest`s that match the provided `url` and `httpMethod`. Returns an empty array if no matching requests were dispatched.
    ///
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)``
    func getNetworkRequestsWith(url: URL, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        let networkRequest = NetworkRequest(url: url, httpMethod: httpMethod)

        awaitRequest(networkRequest, timeout: timeout)

        return getSentRequests(matching: networkRequest)
    }

    /// Waits for a specific network request expectation to be fulfilled within the provided timeout interval.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` to await.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    private func awaitRequest(_ networkRequest: NetworkRequest, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {

        if let waitResult = awaitFor(networkRequest: networkRequest, timeout: timeout) {
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut,
                           """
                           Timed out waiting for network request(s) with URL \(networkRequest.url)
                           and HTTPMethod \(networkRequest.httpMethod.toString())
                           """,
                           file: file,
                           line: line)
        } else {
            wait(UInt32(timeout))
        }
    }

    /// Waits for a specified amount of time.
    /// - Parameters:
    ///   - timeout: The duration to wait in seconds. Defaults to ``TestConstants/Defaults/WAIT_TIMEOUT``.
    func wait(_ timeout: UInt32? = TestConstants.Defaults.WAIT_TIMEOUT) {
        if let timeout = timeout {
            sleep(timeout)
        }
    }
}

public extension NetworkRequest {
    convenience init?(urlString: String, httpMethod: HttpMethod) {
        guard let url = URL(string: urlString) else {
            assertionFailure("Unable to convert the provided string \(urlString) to URL")
            return nil
        }
        self.init(url: url, httpMethod: httpMethod)
    }

    /// Converts the `connectPayload` into a flattened dictionary containing its data.
    /// This API fails the assertion if the request body cannot be parsed as JSON.
    /// - Returns: The JSON request body represented as a flattened dictionary
    func getFlattenedBody(file: StaticString = #file, line: UInt = #line) -> [String: Any] {
        if !self.connectPayload.isEmpty {
            if let payloadAsDictionary = try? JSONSerialization.jsonObject(with: self.connectPayload, options: []) as? [String: Any] {
                return flattenDictionary(dict: payloadAsDictionary)
            } else {
                XCTFail("Failed to parse networkRequest.connectionPayload to JSON", file: file, line: line)
            }
        }

        print("Connection payload is empty for network request with URL \(self.url.absoluteString), HTTPMethod \(self.httpMethod.toString())")
        return [:]
    }
}

extension ThreadSafeDictionary: Sequence {
    public func makeIterator() -> Dictionary<K, V>.Iterator {
        return queue.sync { return self.dictionary.makeIterator() }
    }

    public var isEmpty: Bool {
        return queue.sync { return self.dictionary.isEmpty }
    }

    public subscript(key: K, default defaultValue: @autoclosure () -> V) -> V {
        get {
            return queue.sync {
                return dictionary[key] ?? defaultValue()
            }
        }
        set {
            queue.async {
                self.dictionary[key] = newValue
            }
        }
    }
}
