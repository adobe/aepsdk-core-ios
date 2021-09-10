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

class SignalTests: XCTestCase {
    var signal: Signal!
    var mockHitQueue: MockHitQueue!
    var mockNetworkService: MockNetworkServiceOverrider!
    var mockOpenURLService: MockURLService!
    var mockRuntime: TestableExtensionRuntime!
    
    // before all
    override class func setUp() {}
    
    // before each
    override func setUp() {
        mockHitQueue = MockHitQueue(processor: SignalHitProcessor())
        mockOpenURLService = MockURLService()
        mockRuntime = TestableExtensionRuntime()
        mockNetworkService = MockNetworkServiceOverrider()
                    
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        ServiceProvider.shared.networkService = mockNetworkService
        ServiceProvider.shared.urlService = mockOpenURLService
                
        signal = Signal(runtime: mockRuntime, hitQueue: mockHitQueue)
        signal.onRegistered()
    }
    
    // after each
    override func tearDown() {}
    
    // after all
    override class func tearDown() {}
        
    // MARK: - handleConfigurationResponse(event: Event)
    /// on privacy opt-out, the hit queue should be cleared
    func testConfigResponseOptOut() throws {
        // setup
        signal.hitQueue.queue(entity: DataEntity(data: nil))
        XCTAssertEqual(1, signal.hitQueue.count())
        
        let configEvent = getConfigSharedStateEvent(privacy: .optedOut)
                
        // test
        mockRuntime.simulateComingEvents(configEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
    }

    /// on any privacy status other than opt-out, the hit queue should remain unaffected
    func testConfigResponseOptIn() throws {
        // setup
        signal.hitQueue.queue(entity: DataEntity(data: nil))
        XCTAssertEqual(1, signal.hitQueue.count())
        
        let configEvent = getConfigSharedStateEvent(privacy: .optedIn)
                
        // test
        mockRuntime.simulateComingEvents(configEvent)
        
        // verify
        XCTAssertEqual(1, signal.hitQueue.count())
    }

    // MARK: - handleRulesEngineResponse(event: Event)
    /// an event with valid config and postback type should result in a new entry in the hitqueue
    func testRuleEngineResponsePostbackTypeEvent() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        
        let rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.POSTBACK)
                
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
                
        // verify
        XCTAssertEqual(1, signal.hitQueue.count())
        XCTAssertEqual(0, mockOpenURLService.dispatchedUrls.count)
    }
    
    /// an event with valid config and pii type should result in a new entry in the hitqueue
    func testRuleEngineResponsePiiTypeEvent() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        let rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.PII)
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(1, signal.hitQueue.count())
        XCTAssertEqual(0, mockOpenURLService.dispatchedUrls.count)
    }
    
    /// an event with valid config and open url type should not result in a new entry in the hitqueue
    func testRulesEngineResponseOpenURLType() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        let rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.OPEN_URL)
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
        XCTAssertEqual(1, mockOpenURLService.dispatchedUrls.count)
    }
    
    /// an event without a valid configuration shared state or an opted-out privacy status should be ignored
    func testRulesEngineResponseEventShouldBeIgnoredWhenPrivacyOptedOut() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedOut)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        let rulesEvent = getRulesResponseEvent(type: "url")
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
        XCTAssertEqual(0, mockOpenURLService.dispatchedUrls.count)
    }
    
    /// an event without a valid configuration shared state should be ignored
    func testRulesEngineResponseEventShouldBeIgnoredWhenNoConfigSharedState() throws {
        // setup
        let rulesEvent = getRulesResponseEvent(type: "url")
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
        XCTAssertEqual(0, mockOpenURLService.dispatchedUrls.count)
    }
    
    // MARK: - handlePostback(event: Event)
    /// an event with no templateurl should be ignored
    func testHandlePostbackNoUrl() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        var rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.POSTBACK)
        let updatedEventData = updateDetailDict(dict: rulesEvent.data!, withValue: nil, forKey: SignalConstants.EventDataKeys.TEMPLATE_URL)
        rulesEvent = rulesEvent.copyWithNewData(data: updatedEventData)
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
                
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
    }
    
    /// a pii event without https should be ignored
    func testHandlePostbackNonSecurePii() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))

        var rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.PII)
        let updatedEventData = updateDetailDict(dict: rulesEvent.data!, withValue: "http://nope.com", forKey: SignalConstants.EventDataKeys.TEMPLATE_URL)
        rulesEvent = rulesEvent.copyWithNewData(data: updatedEventData)
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
    }
    
    /// an event with an invalid url should be ignored
    func testHandlePostbackInvalidUrl() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        var rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.POSTBACK)
        let updatedEventData = updateDetailDict(dict: rulesEvent.data!, withValue: "http://nope.com/invalid#@%@%things()#~@!", forKey: SignalConstants.EventDataKeys.TEMPLATE_URL)
        rulesEvent = rulesEvent.copyWithNewData(data: updatedEventData)

        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
    }
    
    /// an event with data that can't be json encoded should be ingored
    // TODO: How do we trigger this case?
//    func testHandlePostbackNotEncodable() throws {
//        // setup
//        let configData = getConfigSharedStateEventData(privacy: .optedIn)
//        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
//                                        data: (configData, .set))
//        let rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.POSTBACK)
//        rulesEvent.data = updateDetailDict(dict: rulesEvent.data!, withValue: "{\"invalidjson:    }", forKey: SignalConstants.EventDataKeys.TEMPLATE_BODY)
//
//        // test
//        mockRuntime.simulateComingEvents(rulesEvent)
//
//        // verify
//        XCTAssertEqual(0, signal.hitQueue.count())
//    }
    
    /// a valid event should be queued
    func testHandlePostbackHappy() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        let rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.POSTBACK)
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(1, signal.hitQueue.count())
    }
    
    // MARK: - handleOpenURL(event: Event)
    /// an event with no url should be ignored
    func testHandleOpenURLNoUrl() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        var rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.OPEN_URL)
        let updatedEventData = updateDetailDict(dict: rulesEvent.data!, withValue: nil, forKey: SignalConstants.EventDataKeys.URL)
        rulesEvent = rulesEvent.copyWithNewData(data: updatedEventData)
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
    }
    
    /// an event with an invalid url should be ignored
    func testHandleOpenURLInvalidUrl() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        var rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.OPEN_URL)
        let updatedEventData = updateDetailDict(dict: rulesEvent.data!, withValue: "http://nope.com/invalid#@%@%things()#~@!", forKey: SignalConstants.EventDataKeys.URL)
        rulesEvent = rulesEvent.copyWithNewData(data: updatedEventData)

        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue.count())
    }
    
    /// a valid event should be opened by the urlService
    func testHandleOpenURLHappy() throws {
        // setup
        let configData = getConfigSharedStateEventData(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: SignalConstants.Configuration.NAME,
                                        data: (configData, .set))
        let rulesEvent = getRulesResponseEvent(type: SignalConstants.ConsequenceTypes.OPEN_URL)
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        XCTAssertEqual(1, mockOpenURLService.dispatchedUrls.count)
    }
    
    // MARK: - Helpers
    /// Gets an event to use for simulating Configuration shared state
    ///
    /// - Parameter privacy: value to set for privacy status in the returned event
    /// - Returns: an Event suitable for use with `TestableExtensionRuntime.simulateSharedState`
    func getConfigSharedStateEvent(privacy: PrivacyStatus) -> Event {
        let data = getConfigSharedStateEventData(privacy: privacy)
        let configEvent = Event(name: "Test Configuration response",
                                type: EventType.configuration,
                                source: EventSource.responseContent,
                                data: data)
        return configEvent
    }
    
    func getConfigSharedStateEventData(privacy: PrivacyStatus) -> [String : Any] {
        return [SignalConstants.Configuration.GLOBAL_PRIVACY : privacy.rawValue] as [String : Any]
    }
    
    /// Gets an event to use for simulating Configuration shared state
    ///
    /// - Parameter privacy: value to set for privacy status in the returned event
    /// - Returns: an Event suitable for use with `TestableExtensionRuntime.simulateSharedState`
    func getRulesResponseEvent(type: String) -> Event {
        // details are the same for postback and pii, different for open url
        let details = type == SignalConstants.ConsequenceTypes.OPEN_URL ?
            [
                SignalConstants.EventDataKeys.URL : "https://www.testingopenurl.com"
            ] :
            [
                SignalConstants.EventDataKeys.CONTENT_TYPE : "application/json",
                SignalConstants.EventDataKeys.TEMPLATE_URL : "https://www.postback.com",
                SignalConstants.EventDataKeys.TEMPLATE_BODY : "{\"key\":\"value\"}",
                SignalConstants.EventDataKeys.TIMEOUT : 4
            ]
        
        let triggeredConsequence = [SignalConstants.EventDataKeys.TRIGGERED_CONSEQUENCE : [
            SignalConstants.EventDataKeys.ID : UUID().uuidString,
            SignalConstants.EventDataKeys.TYPE : type,
            SignalConstants.EventDataKeys.DETAIL : details
        ]]
        let rulesEvent = Event(name: "Test Rules Engine response",
                               type: EventType.rulesEngine,
                               source: EventSource.responseContent,
                               data: triggeredConsequence)
        return rulesEvent
    }
    
    /// Helper to update the nested detail dictionary in a consequence event's event data
    func updateDetailDict(dict: [String : Any], withValue: Any?, forKey: String) -> [String : Any] {
        var returnDict = dict
        guard var consequence = dict[SignalConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] as? [String : Any] else {
            return returnDict
        }
        guard var detail = consequence[SignalConstants.EventDataKeys.DETAIL] as? [String : Any] else {
            return returnDict
        }
        
        detail[forKey] = withValue
        consequence[SignalConstants.EventDataKeys.DETAIL] = detail
        returnDict[SignalConstants.EventDataKeys.TRIGGERED_CONSEQUENCE] = consequence
        
        return returnDict
    }
}
