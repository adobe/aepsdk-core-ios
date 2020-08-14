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

import Foundation

@testable import AEPCore
import AEPCoreMocks
import AEPServices
import AEPServicesMocks
import XCTest

/// Functional tests for the rules engine feature
class RulesEngineFunctionalTests: XCTestCase {
    var mockSystemInfoService: MockSystemInfoService!
    var mockRuntime: TestableExtensionRuntime!
    var rulesEngine: LaunchRulesEngine!

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: mockRuntime)
        rulesEngine.trace { _, _, _, failure in
            print(failure)
        }
    }

    static var rulesUrl: URL? {
        return Bundle(for: self).url(forResource: "rules_functional_1", withExtension: ".zip")
    }

    func testUpdateConfigurationWithDictTwice() {
        // setup
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])

        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)

        let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockRespsonse = (data: expectedData, respsonse: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))

        // test
        rulesEngine.loadRemoteRules(from: "http://test.com/rules.url")
        let processedEvent = rulesEngine.process(event: event)

        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual("value", processedEvent.data?["key"] as? String)
    }

    func testReprocessEvents() {
        // setup
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])

        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)

        let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockRespsonse = (data: expectedData, respsonse: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        // test
        _ = rulesEngine.process(event: event)

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // test
        rulesEngine.loadRemoteRules(from: "http://test.com/rules.url")
        _ = rulesEngine.process(event: Event(name: "test_rules_engine", type: EventType.rulesEngine, source: EventSource.requestReset, data: nil))
        // verify
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let secondEvent = mockRuntime.dispatchedEvents[1]
        XCTAssertEqual("Rules Consequence Event", secondEvent.name)
        XCTAssertEqual(EventType.rulesEngine, secondEvent.type)
        XCTAssertEqual(EventSource.responseContent, secondEvent.source)
    }
}
