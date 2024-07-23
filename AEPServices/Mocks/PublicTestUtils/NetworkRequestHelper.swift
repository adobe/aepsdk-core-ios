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
    /// A dispatch queue for synchronizing access to the internal state.
    private let queue = DispatchQueue(label: "com.adobe.networkrequesthelper.syncqueue")

    /// An array of network requests in the order they were recorded.
    private var _orderedNetworkRequests: [NetworkRequest] = []
    /// A dictionary mapping sent `TestableNetworkRequest` objects to their corresponding `HttpConnection` responses.
    private var _networkResponses: [TestableNetworkRequest: [HttpConnection]] = [:]
    /// A dictionary mapping `TestableNetworkRequest` objects to the network requests that have been sent.
    private var sentNetworkRequests: [TestableNetworkRequest: [NetworkRequest]] = [:]
    /// A dictionary mapping `TestableNetworkRequest` objects to the `CountDownLatch` used to track expected requests.
    private var expectedNetworkRequests: [TestableNetworkRequest: CountDownLatch] = [:]

    /// An array of recorded network requests in the order they were received.
    ///
    /// This property provides a deep copy of the internal `_orderedNetworkRequests` array to ensure thread safety.
    /// - Returns: An array of ``NetworkRequest`` objects.
    var orderedNetworkRequests: [NetworkRequest] {
        return queue.sync {
            _orderedNetworkRequests.map { $0.deepCopy() }
        }
    }

    /// A dictionary mapping ``TestableNetworkRequest`` objects to their ``HttpConnection`` responses.
    ///
    /// This property provides a deep copy of the internal `_networkResponses` dictionary to ensure thread safety.
    /// - Returns: A dictionary where keys are ``TestableNetworkRequest`` objects and values are arrays of ``HttpConnection`` objects.
    var networkResponses: [TestableNetworkRequest: [HttpConnection]] {
        return queue.sync {
            _networkResponses.mapValues { $0.map { $0.deepCopy() } }
        }
    }

    /// Records a network request that has been sent. The operation is performed asynchronously on a dedicated dispatch queue
    /// to ensure thread safety.
    ///
    /// - Parameter networkRequest: The ``NetworkRequest`` object representing the network request that was sent.
    func recordSentNetworkRequest(_ networkRequest: NetworkRequest) {
        print("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")

        queue.async { [weak self] in
            guard let self = self else { return }
            self._orderedNetworkRequests.append(networkRequest)

            let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
            self.sentNetworkRequests[testableNetworkRequest, default: []].append(networkRequest)
        }
    }

    /// Decrements the expectation count for a given network request.
    ///
    /// This method reduces the count of expected occurrences for the specified ``NetworkRequest``.
    /// The decrement operation is performed asynchronously on a dedicated dispatch queue to ensure thread safety.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` object for which the expectation count should be decremented.
    func countDownExpected(networkRequest: NetworkRequest) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.expectedNetworkRequests[testableNetworkRequest]?.countDown()
        }
    }

    /// Resets the internal state of the ``NetworkRequestHelper`` instance.
    ///
    /// This method clears all recorded network requests, network responses, sent network requests,
    /// and expected network requests. The reset operation is thread-safe, performing the reset asynchronously on a
    /// dedicated dispatch queue.
    func reset() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self._orderedNetworkRequests.removeAll()
            self._networkResponses.removeAll()
            self.sentNetworkRequests.removeAll()
            self.expectedNetworkRequests.removeAll()
        }
    }

    // MARK: - Network request APIs

    /// Returns all  network requests that match the provided network request using ``TestableNetworkRequest/isEqual(_:)``.
    ///
    /// This method synchronously retrieves all network requests that match the provided ``NetworkRequest``
    /// using the equality check defined in ``TestableNetworkRequest``.
    ///
    /// - Parameter networkRequest: The ``NetworkRequest`` for which to get matching requests.
    /// - Returns: An array of ``NetworkRequest``s that match the specified ``networkRequest``. If no matches are found, an empty array is returned.
    func getRequests(matching networkRequest: NetworkRequest) -> [NetworkRequest] {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        return queue.sync {
            return self.sentNetworkRequests[testableNetworkRequest] ?? []
        }
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
    ///     - ``setExpectation(for:expectedCount:file:line:)``
    func getNetworkRequestsWith(url: URL, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        let networkRequest = NetworkRequest(url: url, httpMethod: httpMethod)

        awaitRequest(networkRequest, timeout: timeout)

        return getRequests(matching: networkRequest)
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
    ///     - ``setExpectation(for:expectedCount:file:line:)``
    func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        guard let url = URL(string: url) else {
            return []
        }

        return getNetworkRequestsWith(url: url, httpMethod: httpMethod, timeout: timeout, file: file, line: line)
    }

    // MARK: - Network response APIs
    /// Adds a network response for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The ``NetworkRequest``for which the response is being set.
    ///   - responseConnection: The ``HttpConnection`` to set as a response.
    func addResponse(for networkRequest: NetworkRequest, responseConnection: HttpConnection) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        queue.async { [weak self] in
            guard let self = self else { return }
            self._networkResponses[testableNetworkRequest, default: []].append(responseConnection)
        }
    }

    /// Returns the network responses associated with the given network request.
    ///
    /// - Parameter networkRequest: The ``NetworkRequest`` for which the response should be retrieved.
    /// - Returns: The array of ``HttpConnection`` responses associated with the provided ``NetworkRequest``, or `nil` if no response was found.
    func getResponses(for networkRequest: NetworkRequest) -> [HttpConnection]? {
        return queue.sync {
            return self._networkResponses[TestableNetworkRequest(from: networkRequest)]?.map { $0.deepCopy() }
        }
    }

    /// Removes all network responses for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The ``NetworkRequest`` for which to remove all responses.
    func removeAllResponses(for networkRequest: NetworkRequest) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        queue.async { [weak self] in
            guard let self = self else { return }
            self._networkResponses.removeValue(forKey: testableNetworkRequest)
        }
    }

    // MARK: Assertion helpers

    /// Sets the expected number of times a network request should be sent.
    ///
    /// - Parameters:
    ///   - networkRequest: The ``NetworkRequest`` for which the expectation is set.
    ///   - expectedCount: The number of times the request is expected to be sent. The default value is 1.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func setExpectation(for networkRequest: NetworkRequest, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard expectedCount > 0 else {
            assertionFailure("Expected event count should be greater than 0", file: file, line: line)
            return
        }
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.expectedNetworkRequests[testableNetworkRequest] = CountDownLatch(expectedCount)
        }
    }

    /// Asserts that the correct number of network requests were seen for all previously set network request expectations.
    ///
    /// - Parameters:
    ///   - ignoreUnexpectedRequests: A Boolean value indicating whether unexpected requests should be ignored. Defaults to `true`.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - SeeAlso: ``setExpectation(for:expectedCount:file:line:)``
    func assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: Bool = true, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        var localExpectedNetworkRequests: [TestableNetworkRequest: CountDownLatch] = [:]

        // Copy the dictionary in a synchronized block
        queue.sync {
            localExpectedNetworkRequests = self.expectedNetworkRequests
        }

        // Perform operations outside the synchronized block
        if localExpectedNetworkRequests.isEmpty {
            if !ignoreUnexpectedRequests {
                assertUnexpectedRequests(file: file, line: line)
            }
            return
        }

        for (key, value) in localExpectedNetworkRequests {
            let waitResult = value.await(timeout: timeout)
            let expectedCount: Int32 = value.getInitialCount()
            let receivedCount: Int32 = value.getInitialCount() - value.getCurrentCount()

            XCTAssertFalse(waitResult == .timedOut,
                           """
                           Timed out waiting for network request(s) with URL \(key.url.absoluteString) and HTTPMethod
                           \(key.httpMethod.toString()), expected \(expectedCount) but received \(receivedCount)
                           """,
                           file: file,
                           line: line)

            XCTAssertEqual(expectedCount,
                           receivedCount,
                           """
                           Expected \(expectedCount) network request(s) for URL \(key.url.absoluteString) and HTTPMethod
                           \(key.httpMethod.toString()), but received \(receivedCount)
                           """,
                           file: file,
                           line: line)
        }

        if ignoreUnexpectedRequests { return }
        assertUnexpectedRequests()
    }

    /// Asserts that there are no unexpected network requests, including both cases where the number of expected requests exceeds the set
    /// count and where completely unexpected requests are received.
    ///
    /// - Parameters:
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertUnexpectedRequests(timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        var localExpectedNetworkRequests: [TestableNetworkRequest: CountDownLatch] = [:]
        var localSentNetworkRequests: [TestableNetworkRequest: [NetworkRequest]] = [:]

        // Copy the dictionaries in a synchronized block
        queue.sync {
            localSentNetworkRequests = self.sentNetworkRequests
            localExpectedNetworkRequests = self.expectedNetworkRequests
        }

        // Perform operations outside the synchronized block
        var unexpectedRequestsCount = 0
        var unexpectedRequestsAsString = ""

        for (sentRequest, requests) in localSentNetworkRequests {
            let sentRequestURL = sentRequest.url.absoluteString
            let sentRequestHTTPMethod = sentRequest.httpMethod.toString()
            // Check if request is expected and it is over the expected count
            if let expectedRequest = localExpectedNetworkRequests[sentRequest] {
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
            } else {
                // Check for requests that don't have expectations set
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

    /// Waits for a specified amount of time.
    /// - Parameters:
    ///   - timeout: The duration to wait in seconds. Defaults to ``TestConstants/Defaults/WAIT_TIMEOUT``.
    func wait(_ timeout: UInt32? = TestConstants.Defaults.WAIT_TIMEOUT) {
        if let timeout = timeout {
            sleep(timeout)
        }
    }

    /// Waits for a specific network request expectation to be fulfilled within the provided timeout interval.
    ///
    /// This method starts the expectation timer for the given network request, validating that all expected responses are received within
    /// the provided ``timeout`` duration. If the expectation is not met within the timeout, an assertion failure is triggered.
    /// If no expectation exists for the provided request, a regular wait without early exit will be used.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` to await.
    ///   - timeout: The time interval to wait for network requests before timing out. Defaults to ``TestConstants/Defaults/WAIT_NETWORK_REQUEST_TIMEOUT``.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    private func awaitRequest(_ networkRequest: NetworkRequest, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)

        let waitResult = queue.sync {
            return self.expectedNetworkRequests[testableNetworkRequest]?.await(timeout: timeout)
        }

        if let result = waitResult {
            XCTAssertFalse(result == DispatchTimeoutResult.timedOut,
                           """
                           Timed out waiting for network request(s) with URL \(networkRequest.url)
                           and HTTPMethod \(networkRequest.httpMethod.toString())
                           """,
                           file: file,
                           line: line)
        } else {
            // No expectation set for provided request, use generic wait.
            wait(UInt32(timeout))
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
    @available(*, deprecated, message: "Deprecated: Use JSON comparison APIs instead of dictionary flattening for better performance and reliability.")
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
