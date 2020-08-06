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

    func testConfigResponseOptOut() throws {
        // setup
        let data = [SignalConstants.Configuration.GLOBAL_PRIVACY : PrivacyStatus.optedOut.rawValue] as [String : Any]
        let configEvent = Event(name: "Test Configuration response",
                                type: EventType.configuration,
                                source: EventSource.responseContent,
                                data: data)
        mockRuntime.simulateSharedState(for: (SignalConstants.Configuration.NAME, configEvent), data: (data, .set))
        
        
        // test
        mockRuntime.simulateComingEvents(configEvent)
        
        // verify
        XCTAssertEqual(0, signal.hitQueue)()
        
    }


}
