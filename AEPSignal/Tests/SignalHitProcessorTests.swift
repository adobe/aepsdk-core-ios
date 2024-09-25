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
import AEPServicesMocks

@testable import AEPCore
@testable import AEPServices
@testable import AEPSignal

class SignalHitProcessorTests: XCTestCase {
    
    var hitProcessor: SignalHitProcessor!
    var mockNetworkService: MockNetworkService!
    
    let testUrl = URL(string: "https://testsignals.com")!
    let testPostBody = "{\"key\":\"value\"}"
    let testContentType = "application/json"
    let testTimeout = TimeInterval(4)
    let testEvent = getTestEvent()
        
    override func setUp() {
        mockNetworkService = MockNetworkService()
        hitProcessor = SignalHitProcessor(logger: MockLogger(), networkService: mockNetworkService)
    }
        
    // MARK: - processHit(entity: DataEntity, completion: @escaping (Bool) -> Void)
    /// when the `DataEntity` has no data, it should be removed from the queue
    func testProcessHitNoDataInDataEntity() throws {
        // setup
        let entity = DataEntity(data: nil)
        
        // test
        hitProcessor.processHit(entity: entity) { (discardProcessedHit) in
            XCTAssertTrue(discardProcessedHit)
        }
        
        // verify
        XCTAssertFalse(mockNetworkService.connectAsyncCalled)
    }
    
    /// a `DataEntity` with a post body should be prossesed as a POST request
    func testProcessHitPostBodyInDataEntity() throws {
        // setup
        let entity = SignalHit(url: testUrl, postBody: testPostBody, contentType: testContentType,
                               timeout: testTimeout, event: testEvent)
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            throw SignalHitProcessingError.jsonEncodingFailure
        }
        
        // test
        hitProcessor.processHit(entity: DataEntity(data: jsonData)) { (discardProcessedHit) in
            XCTAssertTrue(discardProcessedHit)
        }
        
        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        guard let sentRequest = mockNetworkService.getNetworkRequests().first else {
            XCTFail("Request is unexpectedly nil")
            return
        }
        XCTAssertEqual(testUrl, sentRequest.url)
        XCTAssertEqual(testPostBody, String(decoding: sentRequest.connectPayload, as: UTF8.self))
        XCTAssertEqual(HttpMethod.post, sentRequest.httpMethod)
        XCTAssertEqual(testContentType, sentRequest.httpHeaders[NetworkServiceConstants.Headers.CONTENT_TYPE])
        XCTAssertEqual(testTimeout, sentRequest.connectTimeout)
        XCTAssertEqual(testTimeout, sentRequest.readTimeout)
    }
    
    /// a `DataEntity` without a post body should be prossesed as a GET request
    func testProcessHitNoPostBodyInDataEntity() throws {
        // setup
        let entity = SignalHit(url: testUrl,
                               postBody: nil,
                               contentType: nil,
                               timeout: testTimeout,
                               event: testEvent)
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            throw SignalHitProcessingError.jsonEncodingFailure
        }
        
        // test
        hitProcessor.processHit(entity: DataEntity(data: jsonData)) { (discardProcessedHit) in
            XCTAssertTrue(discardProcessedHit)
        }
        
        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        guard let sentRequest = mockNetworkService.getNetworkRequests().first else {
            XCTFail("Request is unexpectedly nil")
            return
        }
        XCTAssertEqual(testUrl, sentRequest.url)
        XCTAssertEqual("", String(decoding: sentRequest.connectPayload, as: UTF8.self))
        XCTAssertEqual(HttpMethod.get, sentRequest.httpMethod)
        XCTAssertNil(sentRequest.httpHeaders[NetworkServiceConstants.Headers.CONTENT_TYPE])
        XCTAssertEqual(testTimeout, sentRequest.connectTimeout)
        XCTAssertEqual(testTimeout, sentRequest.readTimeout)
    }
    
    /// a 2xx response code should result in removing the hit from the queue
    func testProcessHit2xxResponse() throws {
        // setup
        let entity = SignalHit(url: testUrl, postBody: testPostBody, contentType: testContentType,
                               timeout: testTimeout, event: testEvent)
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            throw SignalHitProcessingError.jsonEncodingFailure
        }
        let testConnection = HttpConnection(data: nil,
                                            response: HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: nil),
                                            error: nil)
        mockNetworkService.setMockResponse(url: testUrl, responseConnection: testConnection)
        
        // test
        hitProcessor.processHit(entity: DataEntity(data: jsonData)) { (discardProcessedHit) in
            XCTAssertTrue(discardProcessedHit)
        }
        
        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }
    
    /// a response code in the list of `NetworkServiceConstants.RECOVERABLE_ERROR_CODES` should not result in
    /// the `DataEntity` being removed from the queue
    func testProcessHitRecoverableHTTPError() throws {
        // setup
        let entity = SignalHit(url: testUrl, postBody: testPostBody, contentType: testContentType,
                               timeout: testTimeout, event: testEvent)
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            throw SignalHitProcessingError.jsonEncodingFailure
        }
        
        NetworkServiceConstants.RECOVERABLE_ERROR_CODES.forEach { error in
            mockNetworkService.reset()
            
            let testConnection = HttpConnection(data: nil,
                                                response: HTTPURLResponse(url: testUrl, statusCode: error, httpVersion: nil, headerFields: nil),
                                                error: nil)
            mockNetworkService.setMockResponse(url: testUrl, responseConnection: testConnection)
            
            // test
            hitProcessor.processHit(entity: DataEntity(data: jsonData)) { (discardProcessedHit) in
                XCTAssertFalse(discardProcessedHit)
            }
            
            // verify
            XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        }
    }
    
    /// a response code that is not 2xx or in the recoverable list should result in removing the hit from the queue
    func testProcessHitUnrecoverableHTTPError() throws {
        // setup
        let entity = SignalHit(url: testUrl, postBody: testPostBody, contentType: testContentType,
                               timeout: testTimeout, event: testEvent)
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            throw SignalHitProcessingError.jsonEncodingFailure
        }
        
        let testConnection = HttpConnection(data: nil,
                                            response: HTTPURLResponse(url: testUrl, statusCode: 1337, httpVersion: nil, headerFields: nil),
                                            error: nil)
        mockNetworkService.setMockResponse(url: testUrl, responseConnection: testConnection)
        
        // test
        hitProcessor.processHit(entity: DataEntity(data: jsonData)) { (discardProcessedHit) in
            XCTAssertTrue(discardProcessedHit)
        }
        
        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }
    
    // an error in the list of `NetworkServiceConstants.RECOVERABLE_URL_ERROR_CODES` should not result in
    /// the `DataEntity` being removed from the queue
    func testProcessHitRecoverableURLError() throws {
        // setup
        let entity = SignalHit(url: testUrl, postBody: testPostBody, contentType: testContentType,
                               timeout: testTimeout, event: testEvent)
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            throw SignalHitProcessingError.jsonEncodingFailure
        }
        
        NetworkServiceConstants.RECOVERABLE_URL_ERROR_CODES.forEach { err in
            mockNetworkService.reset()

            let testConnection = HttpConnection(data: nil,
                                                response: nil,
                                                error: URLError(err))
            mockNetworkService.setMockResponse(url: testUrl, responseConnection: testConnection)
            
            // test
            hitProcessor.processHit(entity: DataEntity(data: jsonData)) { (discardProcessedHit) in
                XCTAssertFalse(discardProcessedHit)
            }
            
            // verify
            XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        }
    }
    
    // an error not in the list of `NetworkServiceConstants.RECOVERABLE_URL_ERROR_CODES` should result in
    /// the `DataEntity` being removed from the queue
    func testProcessHitUnrecoverableError() throws {
        // setup
        let entity = SignalHit(url: testUrl, postBody: testPostBody, contentType: testContentType,
                               timeout: testTimeout, event: testEvent)
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            throw SignalHitProcessingError.jsonEncodingFailure
        }
        
        // Errors not in recoverable error list
        let unrecoverableErrors:[Error] = [AEPError.networkError, URLError(URLError.badURL)]
        unrecoverableErrors.forEach { error in
            mockNetworkService.reset()
            
            let testConnection = HttpConnection(data: nil,
                                                response: nil,
                                                error: error)
            mockNetworkService.setMockResponse(url: testUrl, responseConnection: testConnection)
            
            // test
            hitProcessor.processHit(entity: DataEntity(data: jsonData)) { (discardProcessedHit) in
                XCTAssertTrue(discardProcessedHit)
            }
            
            // verify
            XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        }
    }
    
    // MARK: - Helpers
    
        
    /// Gets an event to use for simulating Configuration shared state
    ///
    /// - Parameter privacy: value to set for privacy status in the returned event
    /// - Returns: an Event with no data
    class func getTestEvent() -> Event {
        let rulesEvent = Event(name: "TestEvent",
                               type: EventType.rulesEngine,
                               source: EventSource.responseContent,
                               data: nil)
        return rulesEvent
    }
        
    enum SignalHitProcessingError: Error {
        case jsonEncodingFailure
        case invalidNetworkRequest
    }
}
