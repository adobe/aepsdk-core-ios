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
    var mockRuntime: TestableExtensionRuntime!
    var mockNetworkService: MockNetworkServiceOverrider!
    
    override func setUpWithError() throws {
        ServiceProvider.shared.networkService = MockNetworkServiceOverrider()
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        
        mockRuntime = TestableExtensionRuntime()
        mockNetworkService = ServiceProvider.shared.networkService as? MockNetworkServiceOverrider
        
        signal = Signal(runtime: mockRuntime)
        signal.onRegistered()
    }
        
    // MARK: - handleConfigurationResponse(event: Event)
    /// on privacy opt-out, the hit queue should be cleared
    func testConfigResponseOptOut() throws {
        // setup
        signal.hitQueue.queue(entity: DataEntity(data: nil))
        XCTAssertEqual(1, signal.hitQueue.count())
        
        let configEvent = getConfigSharedStateEvent(privacy: .optedOut)
        mockRuntime.simulateSharedState(for: (SignalConstants.Configuration.NAME, configEvent),
                                        data: (configEvent.data!, .set))
                
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
        mockRuntime.simulateSharedState(for: (SignalConstants.Configuration.NAME, configEvent),
                                        data: (configEvent.data!, .set))
                
        // test
        mockRuntime.simulateComingEvents(configEvent)
        
        // verify
        XCTAssertEqual(1, signal.hitQueue.count())
    }

    // MARK: - handleRulesEngineResponse(event: Event)
    /// an event with valid config and postback type should result in a new entry in the hitqueue
    func testRuleEngineResponsePostbackTypeEvent() throws {
        // setup
        let configEvent = getConfigSharedStateEvent(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: (SignalConstants.Configuration.NAME, configEvent),
                                        data: (configEvent.data!, .set))
        let rulesEvent = getRulesResponseEvent(type: "pb")
                
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
                
        // verify
        XCTAssertEqual(1, signal.hitQueue.count())
    }
    
    /// an event with valid config and pii type should result in a new entry in the hitqueue
    func testRuleEngineResponsePiiTypeEvent() throws {
        // setup
        let configEvent = getConfigSharedStateEvent(privacy: .optedIn)
        mockRuntime.simulateSharedState(for: (SignalConstants.Configuration.NAME, configEvent),
                                        data: (configEvent.data!, .set))
        let rulesEvent = getRulesResponseEvent(type: "pii")
        
        // test
        mockRuntime.simulateComingEvents(rulesEvent)
        
        // verify
        
        XCTAssertEqual(1, signal.hitQueue.count())
    }
    
    /// an event with valid config and open url type should not result in a new entry in the hitqueue
    
    /// an event without a valid configuration shared state or an opted-out privacy status should be ignored
    func testRulesEngineResponseEventShouldBeIgnored() throws {
        // setup
        
        
        // test
        
        
        // verify
    }
    
    // MARK: - Helpers
    
    /// Gets an event to use for simulating Configuration shared state
    ///
    /// - Parameter privacy: value to set for privacy status in the returned event
    /// - Returns: an Event suitable for use with `TestableExtensionRuntime.simulateSharedState`
    func getConfigSharedStateEvent(privacy: PrivacyStatus) -> Event {
        let data = [SignalConstants.Configuration.GLOBAL_PRIVACY : privacy.rawValue] as [String : Any]
        let configEvent = Event(name: "Test Configuration response",
                                type: EventType.configuration,
                                source: EventSource.responseContent,
                                data: data)
        return configEvent
    }
    
    /// Gets an event to use for simulating Configuration shared state
    ///
    /// - Parameter privacy: value to set for privacy status in the returned event
    /// - Returns: an Event suitable for use with `TestableExtensionRuntime.simulateSharedState`
    func getRulesResponseEvent(type: String) -> Event {
        // details are the same for postback and pii, different for open url
        let details = SignalConstants.EventDataKeys.TYPE == SignalConstants.ConsequenceTypes.OPEN_URL ?
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
}
