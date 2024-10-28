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

import XCTest

import AEPCoreMocks

@testable import AEPCore
@testable import AEPIdentity
@testable import AEPServices

class IdentityHitProcessorTests: XCTestCase {
    var hitProcessor: IdentityHitProcessor!
    var responseCallbackArgs = [(IdentityHit, Data?)]()
    var mockNetworkService: MockNetworkService? {
        return ServiceProvider.shared.networkService as? MockNetworkService
    }

    override func setUp() {
        ServiceProvider.shared.networkService = MockNetworkService()
        hitProcessor = IdentityHitProcessor(responseHandler: { [weak self] hit, data in
            self?.responseCallbackArgs.append((hit, data))
        })
    }

    /// Tests that when a `DataEntity` with bad data is passed, that it is not retried and is removed from the queue
    func testProcessHitBadHit() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: nil) // entity data does not contain an `IdentityHit`

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(responseCallbackArgs.isEmpty) // response handler should not have been invoked
        XCTAssertFalse(mockNetworkService?.connectAsyncCalled ?? true) // no network request should have been made
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHitHappy() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let expectedUrl = URL(string: "adobe.com")!
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let hit = IdentityHit(url: expectedUrl, event: expectedEvent)
        let testConnection = HttpConnection(data: nil, response: HTTPURLResponse(url: expectedUrl, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        mockNetworkService?.setMockResponse(url: expectedUrl, responseConnection: testConnection)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try! JSONEncoder().encode(hit))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(responseCallbackArgs.isEmpty) // response handler should have been invoked
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
        XCTAssertEqual(mockNetworkService?.getNetworkRequests().first?.url, expectedUrl) // network request should be made with the url in the hit
    }

    /// a response code in the list of `NetworkServiceConstants.RECOVERABLE_ERROR_CODES` should not result in
    /// the `DataEntity` being removed from the queue
    func testProcessHitRecoverableHTTPError() {
        // setup
        let expectedUrl = URL(string: "adobe.com")!
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let hit = IdentityHit(url: expectedUrl, event: expectedEvent)

        NetworkServiceConstants.RECOVERABLE_ERROR_CODES.forEach { error in
            let expectation = XCTestExpectation(description: "Callback should be invoked with false signaling this hit should be retried")
            mockNetworkService?.reset()

            let testConnection = HttpConnection(data: nil, response: HTTPURLResponse(url: expectedUrl, statusCode: error , httpVersion: nil, headerFields: nil), error: nil)

            mockNetworkService?.setMockResponse(url: expectedUrl, httpMethod: .get, responseConnection: testConnection)

            let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try! JSONEncoder().encode(hit))

            // test
            hitProcessor.processHit(entity: entity) { success in
                XCTAssertFalse(success)
                expectation.fulfill()
            }

            // verify
            wait(for: [expectation], timeout: 1)
            XCTAssertTrue(responseCallbackArgs.isEmpty) // response handler should have not been invoked
            XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
            XCTAssertEqual(mockNetworkService?.getNetworkRequests().first?.url, expectedUrl) // network request should be made with the url in the hit
        }
    }

    /// a response code that is not 2xx or in the recoverable list should result in removing the hit from the queue
    func testProcessHitUnrecoverableHTTPError() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let expectedUrl = URL(string: "adobe.com")!
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let hit = IdentityHit(url: expectedUrl, event: expectedEvent)
        let testConnection = HttpConnection(data: nil, response: HTTPURLResponse(url: expectedUrl, statusCode: -1, httpVersion: nil, headerFields: nil), error: nil)

        mockNetworkService?.setMockResponse(url: expectedUrl, responseConnection: testConnection)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try! JSONEncoder().encode(hit))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(responseCallbackArgs.isEmpty) // response handler should have been invoked
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
        XCTAssertEqual(mockNetworkService?.getNetworkRequests().first?.url, expectedUrl) // network request should be made with the url in the hit
    }

    // an error in the list of `NetworkServiceConstants.RECOVERABLE_URL_ERROR_CODES` should not result in
    /// the `DataEntity` being removed from the queue
    func testProcessHitRecoverableURLError() throws {
        // setup
        let expectedUrl = URL(string: "adobe.com")!
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let hit = IdentityHit(url: expectedUrl, event: expectedEvent)

        NetworkServiceConstants.RECOVERABLE_URL_ERROR_CODES.forEach { error in
            let expectation = XCTestExpectation(description: "Callback should be invoked with false signaling this hit should be retried")
            mockNetworkService?.reset()

            let testConnection = HttpConnection(data: nil, response: nil, error: URLError(error))

            mockNetworkService?.setMockResponse(url: expectedUrl, httpMethod: .get, responseConnection: testConnection)

            let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try! JSONEncoder().encode(hit))

            // test
            hitProcessor.processHit(entity: entity) { success in
                XCTAssertFalse(success)
                expectation.fulfill()
            }

            // verify
            wait(for: [expectation], timeout: 1)
            XCTAssertTrue(responseCallbackArgs.isEmpty) // response handler should have not been invoked
            XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
            XCTAssertEqual(mockNetworkService?.getNetworkRequests().first?.url, expectedUrl) // network request should be made with the url in the hit
        }
    }

    // an error not in the list of `NetworkServiceConstants.RECOVERABLE_URL_ERROR_CODES` should result in
    /// the `DataEntity` being removed from the queue
    func testProcessHitUnrecoverableError() throws {
        // setup
        let expectedUrl = URL(string: "adobe.com")!
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let hit = IdentityHit(url: expectedUrl, event: expectedEvent)

        // Errors not in recoverable error list
        let unrecoverableErrors:[Error] = [AEPError.networkError, URLError(URLError.badURL)]
        unrecoverableErrors.forEach { error in
            let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
            mockNetworkService?.reset()

            let testConnection = HttpConnection(data: nil, response: nil, error: error)

            mockNetworkService?.setMockResponse(url: expectedUrl, httpMethod: .get, responseConnection: testConnection)

            let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try! JSONEncoder().encode(hit))

            // test
            hitProcessor.processHit(entity: entity) { success in
                XCTAssertTrue(success)
                expectation.fulfill()
            }

            // verify
            wait(for: [expectation], timeout: 1)
            XCTAssertFalse(responseCallbackArgs.isEmpty) // response handler should have been invoked
            XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
            XCTAssertEqual(mockNetworkService?.getNetworkRequests().first?.url, expectedUrl) // network request should be made with the url in the hit
        }
    }
}
