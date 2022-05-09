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
    var defaultEvent: Event!

    override func setUp() {
        continueAfterFailure = false
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        defaultEvent = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                             data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        Log.logFilter = .trace
        rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: mockRuntime)
        rulesEngine.trace { _, _, _, failure in
            print(failure ?? "unknown failure")
        }
    }

    static var rulesUrl: URL? {
        return Bundle(for: self).url(forResource: "rules_functional_1", withExtension: ".zip")
    }

    func testLoadRulesFromRemoteURL() {
        /// Given:
        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)

        let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockResponse = (data: expectedData, response: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T", "installevent": "Installevent"]], status: .set))

        /// When:
        rulesEngine.replaceRules(from: "http://test.com/rules.url")
        let processedEvent = rulesEngine.process(event: defaultEvent)

        /// Then:
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual("value", processedEvent.data?["key"] as? String)
    }

    func testLoadRulesFromLocalCachedFile() {
        /// Given:
        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)

        let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockResponse = (data: expectedData, response: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        rulesEngine.replaceRules(from: "http://test.com/rules.url")
        rulesEngine.rulesEngine.clearRules()

        /// When:
        if rulesEngine.replaceRulesWithCache(from: "http://test.com/rules.url") == false {
            XCTFail("Failed to replace rules with cache")
        }
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T", "installevent": "Installevent"]], status: .set))

        // Multiple async functions are queued. Wait for them to complete before processing event. 
        waitForProcessing(interval: 0.2)
        let processedEvent = rulesEngine.process(event: defaultEvent)

        /// Then:
        XCTAssertEqual(3, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual("value", processedEvent.data?["key"] as? String)

    }

    func testLoadRulesFromManifest() {
        guard let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip") else {
            XCTFail("Incorrect url for zip resource")
            return
        }

        rulesEngine.replaceRulesWithManifest(from: filePath)
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T", "installevent": "Installevent"]], status: .set))

        let processedEvent = rulesEngine.process(event: defaultEvent)

        /// Then:
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual("value", processedEvent.data?["key"] as? String)
    }

    func testReprocessEvents() {
        /// Given:
        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)

        let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockResponse = (data: expectedData, response: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)

        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        rulesEngine.replaceRules(from: "http://test.com/rules.url")
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        /// When:
        rulesEngine.process(event: mockRuntime.dispatchedEvents[0])
        /// Then:
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let secondEvent = mockRuntime.dispatchedEvents[1]
        XCTAssertEqual("Rules Consequence Event", secondEvent.name)
        XCTAssertEqual(EventType.rulesEngine, secondEvent.type)
        XCTAssertEqual(EventSource.responseContent, secondEvent.source)
    }

    // Group: OR & AND
    func testGroupLogicalOperators() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testGroupLogicalOperators")

        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: eq
    func testMatcherEq() {
        // covered by `RulesEngineFunctionalTests.testGroupLogicalOperators()`
    }

    // Matcher: ne
    func testMatcherNe() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherNe")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "Verizon"]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: ex
    func testMatcherEx() {
        // covered by `RulesEngineFunctionalTests.testGroupLogicalOperators()`
    }

    // Matcher: nx (Not Exists)
    func testMatcherNx() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherNx")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: nil, status: .pending))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: gt (Greater Than)
    func testMatcherGt() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherGt")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 3]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: gt (Greater Than - Int vs Int64)
    func testMatcherGtForIntTypes() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherGt_2_types")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: ge (Greater Than or Equals)
    func testMatcherGe() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherGe")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 1]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: lt (Less Than)
    func testMatcherLt() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherLt")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 1]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: le (Less Than or Equals)
    func testMatcherLe() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherLe")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 3]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: co (Contains)
    func testMatcherCo() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherCo")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "Verizon"]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&"]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    // Matcher: nc (Not Contains)
    func testMatcherNc() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testMatcherNc")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&"]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "Verizon"]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("pb", dataWithType["type"] as! String)
    }

    func testMatcherWithDifferentTypesOfParameters() {
        /// Given:
        //        {
        //            "type": "matcher",
        //            "definition": {
        //                "key": "~state.com.adobe.module.lifecycle/lifecyclecontextdata.launches",
        //                "matcher": "gt",
        //                "values": [
        //                "2"
        //                ]
        //            }
        //        }
        resetRulesEngine(withNewRules: "rules_testMatcherWithDifferentTypesOfParameters")


        /// When:
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 3]], status: .set))
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testUrlenc() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testUrlenc")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "x y"]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any], let detail = dataWithType["detail"] as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("url", dataWithType["type"] as! String)
        XCTAssertEqual("http://www.adobe.com/a=x%20y", detail["url"] as! String)
    }

    func testUrlenc_invalidFnName() {
        /// Given:
        //    {
        //      "id": "RC48ef3f5e83c84405a3da6cc5128c090c",
        //      "type": "url",
        //      "detail": {
        //        "url": "http://www.adobe.com/a={%urlenc1(~state.com.adobe.module.lifecycle/lifecyclecontextdata.carriername)%}"
        //      }
        //    }
        resetRulesEngine(withNewRules: "rules_testUrlenc_invalidFnName")

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "x y"]], status: .set))
        /// When:
        rulesEngine.process(event: defaultEvent)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any], let detail = dataWithType["detail"] as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("url", dataWithType["type"] as! String)
        XCTAssertEqual("http://www.adobe.com/a=x y", detail["url"] as! String)
    }

    func testAttachData() {
        /// Given: a launch rule to attach data to event

        //    ---------- attach data rule ----------
        //        "eventdata": {
        //            "attached_data": {
        //                "key1": "value1",
        //                "launches": "{%~state.com.adobe.module.lifecycle/lifecyclecontextdata.launches%}"
        //            }
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testAttachData")

        /// When: evaluating a launch event

        //    ------------ launch event ------------
        //        "eventdata": {
        //            "lifecyclecontextdata": {
        //                "launchevent": "LaunchEvent"
        //            }
        //        }
        //    --------------------------------------


        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        let processedEvent = rulesEngine.process(event: defaultEvent)

        /// Then: no consequence event will be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        guard let attachedData = processedEvent.data?["attached_data"] as? [String: Any] else {
            XCTFail()
            return
        }

        /// Then: ["key1": "value1"] should be attached to above launch event
        XCTAssertEqual("value1", attachedData["key1"] as? String)

        /// Then: should not get "launches" value from (lifecycle) shared state
        XCTAssertEqual("", attachedData["launches"] as? String)
    }

    func testAttachData_invalidJson() {
        /// Given: a launch rule to attach data to event

        //    ---------- attach data rule ----------
        //        "eventdata_xyz": {
        //            "attached_data": {
        //                "key1": "value1",
        //                "launches": "{%~state.com.adobe.module.lifecycle/lifecyclecontextdata.launches%}"
        //            }
        //        }
        //    --------------------------------------
        resetRulesEngine(withNewRules: "rules_testAttachData_invalidJson")

        /// When: evaluating a launch event

        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T"]], status: .set))
        let processedEvent = rulesEngine.process(event: defaultEvent)

        /// Then: no consequence event will be dispatched
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        /// Then: no data should not be attached to original launch event
        XCTAssertTrue(processedEvent.data?["attached_data"] == nil)
    }

    func testModifyData() {
        /// Given: a launch rule to modify event data

        //    ---------- modify data rule ----------
        //        "eventdata": {
        //            "lifecyclecontextdata": {
        //                "launches": "{%~state.com.adobe.module.lifecycle/lifecyclecontextdata.launches%}",
        //                "launchevent": null
        //            }
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testModifyData")

        /// When: evaluating a launch event

        //    ------------ launch event ------------
        //        "eventdata": {
        //            "lifecyclecontextdata": {
        //                "launchevent": "LaunchEvent"
        //            }
        //        }
        //    --------------------------------------


        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T", "launches": 2]], status: .set))
        let processedEvent = rulesEngine.process(event: defaultEvent)

        /// Then: no consequence event will be dispatched

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        guard let lifecycleContextData = processedEvent.data?["lifecyclecontextdata"] as? [String: Any] else {
            XCTFail()
            return
        }

        /// Then: "launchevent" should be removed from event data

        XCTAssertTrue(lifecycleContextData["launchevent"] == nil)

        /// Then: should get "launches" value from (lifecycle) shared state

        XCTAssertEqual("2", lifecycleContextData["launches"] as? String)
    }

    func testModifyData_invalidJson() {
        /// Given: a launch rule to modify event data

        //    ---------- modify data rule ----------
        //        "eventdata_xyz": {
        //            "lifecyclecontextdata": {
        //                "launches": "{%~state.com.adobe.module.lifecycle/lifecyclecontextdata.launches%}",
        //                "launchevent": null
        //            }
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testModifyData_invalidJson")

        /// When: evaluating a launch event

        //    ------------ launch event ------------
        //        "eventdata": {
        //            "lifecyclecontextdata": {
        //                "launchevent": "LaunchEvent"
        //            }
        //        }
        //    --------------------------------------


        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["carriername": "AT&T", "launches": 2]], status: .set))
        let processedEvent = rulesEngine.process(event: defaultEvent)

        /// Then: no consequence event will be dispatched

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        guard let lifecycleContextData = processedEvent.data?["lifecyclecontextdata"] as? [String: Any] else {
            XCTFail()
            return
        }

        /// Then: "launchevent" should not be removed from event data

        XCTAssertTrue(lifecycleContextData["launchevent"] != nil)

        /// Then: should not get "launches" value from (lifecycle) shared state

        XCTAssertTrue(lifecycleContextData["launches"] == nil)
    }

    func testDispatchEvent_copy() {
        /// Given: a launch rule to dispatch an event which copies the triggering event data

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "type" : "com.adobe.eventType.edge",
        //          "source" : "com.adobe.eventSource.requestContent",
        //          "eventdataaction" : "copy"
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventCopy")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: ["xdm": "test data"])

        let processedEvent = rulesEngine.process(event: event)

        /// Then: One consequence event will be dispatched

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]

        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)
        XCTAssertEqual(event.data as? [String : String], dispatchedEvent.data as? [String : String])

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_copyNoEventData() {
        /// Given: a launch rule to dispatch an event which copies the triggering event data, but none is given

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "type" : "com.adobe.eventType.edge",
        //          "source" : "com.adobe.eventSource.requestContent",
        //          "eventdataaction" : "copy"
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventCopy")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: nil)

        let processedEvent = rulesEngine.process(event: event)

        /// Then: One consequence event will be dispatched

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]

        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)
        XCTAssertNil(dispatchedEvent.data)

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_newData() {
        /// Given: a launch rule to dispatch an event which adds new event data

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "type" : "com.adobe.eventType.edge",
        //          "source" : "com.adobe.eventSource.requestContent",
        //          "eventdataaction" : "new",
        //          "eventdata" : {
        //            "key" : "value",
        //            "key.subkey" : "subvalue",
        //            "launches": "{%~state.com.adobe.module.lifecycle/lifecyclecontextdata.launches%}",
        //          }
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventNewData")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: ["xdm": "test data"])
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata": ["launches": 2]], status: .set))
        let processedEvent = rulesEngine.process(event: event)

        /// Then: One consequence event will be dispatched

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]

        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)
        XCTAssertEqual(3, dispatchedEvent.data?.count)
        XCTAssertEqual("value", dispatchedEvent.data?["key"] as? String)
        XCTAssertEqual("subvalue", dispatchedEvent.data?["key.subkey"] as? String)
        XCTAssertEqual("2", dispatchedEvent.data?["launches"] as? String)

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_newNoData() {
        /// Given: a launch rule to dispatch an event which adds new event event data, but none is configured

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "type" : "com.adobe.eventType.edge",
        //          "source" : "com.adobe.eventSource.requestContent",
        //          "eventdataaction" : "new",
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventNewNoData")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: ["xdm": "test data"])
        let processedEvent = rulesEngine.process(event: event)

        /// Then: One consequence event will be dispatched

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]

        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)
        XCTAssertNil(dispatchedEvent.data)

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_invalidAction() {
        /// Given: a launch rule to dispatch an event with invalid action

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "type" : "com.adobe.eventType.edge",
        //          "source" : "com.adobe.eventSource.requestContent",
        //          "eventdataaction" : "invalid",
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventInvalidAction")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: ["xdm": "test data"])
        let processedEvent = rulesEngine.process(event: event)

        /// Then: No consequence event will be dispatched

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_noAction() {
        /// Given: a launch rule to dispatch an event with no action specified in details

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "type" : "com.adobe.eventType.edge",
        //          "source" : "com.adobe.eventSource.requestContent"
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventNoAction")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: ["xdm": "test data"])
        let processedEvent = rulesEngine.process(event: event)

        /// Then: No consequence event will be dispatched

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_noType() {
        /// Given: a launch rule to dispatch an event with no type specified in details

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "source" : "com.adobe.eventSource.requestContent",
        //          "eventdataaction" : "copy"
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventNoType")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: ["xdm": "test data"])
        let processedEvent = rulesEngine.process(event: event)

        /// Then: No consequence event will be dispatched

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_noSource() {
        /// Given: a launch rule to dispatch an event with no source specified in details

        //    ---------- dispatch event rule ----------
        //        "detail": {
        //          "type" : "com.adobe.eventType.edge",
        //          "eventdataaction" : "copy"
        //        }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventNoSource")

        let event = Event(name: "Application Launch",
                          type: EventType.lifecycle,
                          source: EventSource.applicationLaunch,
                          data: ["xdm": "test data"])
        let processedEvent = rulesEngine.process(event: event)

        /// Then: No consequence event will be dispatched

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // verify original event is unchanged
        XCTAssertEqual(event, processedEvent)
    }

    func testDispatchEvent_chainedDispatchEvents() {
        /// Given: a launch rule to dispatch an event with the same type and source which triggered the consequence

        //    ---------- dispatch event rule condition ----------
        //        "conditions": [
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~type",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventType.edge"
        //            ]
        //          }
        //        },
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~source",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventSource.requestContent"
        //            ]
        //          }
        //        }
        //      ]
        //    ---------- dispatch event rule consequence ----------
        //        "detail": {
        //           "type" : "com.adobe.eventType.edge",
        //           "source" : "com.adobe.eventSource.requestContent",
        //           "eventdataaction" : "copy"
        //         }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventChain")

        let event = Event(name: "Edge Request",
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: ["xdm": "test data"])

        // Process original event; dispatch chain count = 0
        _ = rulesEngine.process(event: event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        mockRuntime.dispatchedEvents.removeAll()

        // Process dispatched event; dispatch chain count = 1
        // Expect dispatch to fail as max allowed chained events is 1
        _ = rulesEngine.process(event: dispatchedEvent)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testDispatchEvent_multipleProcessingOfSameOriginalEvent() {
        /// Given: a launch rule to dispatch an event with the same type and source which triggered the consequence

        //    ---------- dispatch event rule condition ----------
        //        "conditions": [
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~type",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventType.edge"
        //            ]
        //          }
        //        },
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~source",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventSource.requestContent"
        //            ]
        //          }
        //        }
        //      ]
        //    ---------- dispatch event rule consequence ----------
        //        "detail": {
        //           "type" : "com.adobe.eventType.edge",
        //           "source" : "com.adobe.eventSource.requestContent",
        //           "eventdataaction" : "copy"
        //         }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventChain")

        let event = Event(name: "Edge Request",
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: ["xdm": "test data"])

        // Process original event; dispatch chain count = 0
        _ = rulesEngine.process(event: event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        var dispatchedEvent = mockRuntime.dispatchedEvents[0]
        mockRuntime.dispatchedEvents.removeAll()

        // Process dispatched event; dispatch chain count = 1
        // Expect dispatch to fail as max allowed chained events is 1
        _ = rulesEngine.process(event: dispatchedEvent)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // Process original event again due to re-dispatch (edge case)
        // Expect event to be processed as if first time
        _ = rulesEngine.process(event: event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        dispatchedEvent = mockRuntime.dispatchedEvents[0]
        mockRuntime.dispatchedEvents.removeAll()

        // Process dispatched event; dispatch chain count = 1
        // Expect dispatch to fail as max allowed chained events is 1
        _ = rulesEngine.process(event: dispatchedEvent)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testDispatchEvent_multipleProcessingOfSameDispatchedEvent() {
        /// Given: a launch rule to dispatch an event with the same type and source which triggered the consequence

        //    ---------- dispatch event rule condition ----------
        //        "conditions": [
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~type",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventType.edge"
        //            ]
        //          }
        //        },
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~source",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventSource.requestContent"
        //            ]
        //          }
        //        }
        //      ]
        //    ---------- dispatch event rule consequence ----------
        //        "detail": {
        //           "type" : "com.adobe.eventType.edge",
        //           "source" : "com.adobe.eventSource.requestContent",
        //           "eventdataaction" : "copy"
        //         }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventChain")

        let event = Event(name: "Edge Request",
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: ["xdm": "test data"])

        // Process original event; dispatch chain count = 0
        _ = rulesEngine.process(event: event)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        mockRuntime.dispatchedEvents.removeAll()

        // Process dispatched event; dispatch chain count = 1
        // Expect dispatch to fail as max allowed chained events is 1
        _ = rulesEngine.process(event: dispatchedEvent)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // Process same dispatch event again due to re-dispatch (edge case)
        // Expect event to be treated as original event with chain count = 0
        _ = rulesEngine.process(event: dispatchedEvent)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent2 = mockRuntime.dispatchedEvents[0]
        mockRuntime.dispatchedEvents.removeAll()

        // Process second dispatched event; dispatch chain count = 1
        // Expect dispatch to fail as max allowed chained events is 1
        _ = rulesEngine.process(event: dispatchedEvent2)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

    }

    func testDispatchEvent_interleavedChainedDispatchEvents() {
        /// Given: two launch rules with the same consequence but different event triggers

        //    ---------- dispatch event rule 1 condition ----------
        //        "conditions": [
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~type",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventType.edge"
        //            ]
        //          }
        //        },
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~source",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventSource.requestContent"
        //            ]
        //          }
        //        }
        //      ]
        //    ---------- dispatch event rule 1 consequence ----------
        //        "detail": {
        //           "type" : "com.adobe.eventType.edge",
        //           "source" : "com.adobe.eventSource.requestContent",
        //           "eventdataaction" : "copy"
        //         }
        //    --------------------------------------

        //    ---------- dispatch event rule 2 condition ----------
        //        "conditions": [
        //       {
        //         "type": "matcher",
        //         "definition": {
        //           "key": "~type",
        //           "matcher": "eq",
        //           "values": [
        //             "com.adobe.eventType.lifecycle"
        //           ]
        //         }
        //       },
        //       {
        //         "type": "matcher",
        //         "definition": {
        //           "key": "~source",
        //           "matcher": "eq",
        //           "values": [
        //             "com.adobe.eventSource.applicationLaunch"
        //           ]
        //         }
        //       }
        //     ]
        //    ---------- dispatch event rule 2 consequence ----------
        //        "detail": {
        //           "type" : "com.adobe.eventType.edge",
        //           "source" : "com.adobe.eventSource.requestContent",
        //           "eventdataaction" : "copy"
        //         }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventChain")

        /// Then: dispatch event to trigger rule 1
        let eventEdgeRequest = Event(name: "Edge Request",
                                     type: EventType.edge,
                                     source: EventSource.requestContent,
                                     data: ["xdm": "test data"])

        /// Then: dispatch event to trigger rule 2
        let eventLaunch = Event(name: "Application Launch",
                                type: EventType.lifecycle,
                                source: EventSource.applicationLaunch,
                                data: ["xdm": "test data"])

        // Process original event; dispatch chain count = 0
        _ = rulesEngine.process(event: eventEdgeRequest)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent1 = mockRuntime.dispatchedEvents[0]
        mockRuntime.dispatchedEvents.removeAll()

        // Process launch event
        _ = rulesEngine.process(event: eventLaunch)
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent2 = mockRuntime.dispatchedEvents[0]
        mockRuntime.dispatchedEvents.removeAll()

        // Process first dispatched event; dispatch chain count = 1
        // Expect dispatch to fail as max allowed chained events is 1
        _ = rulesEngine.process(event: dispatchedEvent1)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)

        // // Process second dispatched event; dispatch chain count = 1
        // Expect dispatch to fail as max allowed chained events is 1
        _ = rulesEngine.process(event: dispatchedEvent2)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testDispatchEvent_processedEventMatchesMultipleDispatchConsequences() {
        /// Given: two launch rules with the same consequence but different conditions

        //    ---------- dispatch event rule 1 condition ----------
        //        "conditions": [
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~type",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventType.edge"
        //            ]
        //          }
        //        },
        //        {
        //          "type": "matcher",
        //          "definition": {
        //            "key": "~source",
        //            "matcher": "eq",
        //            "values": [
        //              "com.adobe.eventSource.requestContent"
        //            ]
        //          }
        //        }
        //      ]
        //    ---------- dispatch event rule 1 consequence ----------
        //        "detail": {
        //           "type" : "com.adobe.eventType.edge",
        //           "source" : "com.adobe.eventSource.requestContent",
        //           "eventdataaction" : "copy"
        //         }
        //    --------------------------------------

        //    ---------- dispatch event rule 2 condition ----------
        //        "conditions": [
        //          {
        //            "type": "matcher",
        //            "definition": {
        //              "key": "dispatch",
        //              "matcher": "eq",
        //              "values": [
        //                "yes"
        //              ]
        //            }
        //          }
        //        ]
        //    ---------- dispatch event rule 2 consequence ----------
        //        "detail": {
        //           "type" : "com.adobe.eventType.edge",
        //           "source" : "com.adobe.eventSource.requestContent",
        //           "eventdataaction" : "copy"
        //         }
        //    --------------------------------------

        resetRulesEngine(withNewRules: "rules_testDispatchEventChain")

        /// Then:  dispatch event which will trigger two launch rules

        let event = Event(name: "Edge Request",
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: ["dispatch": "yes"])

        // Process original event, expect 2 dispatched events
        _ = rulesEngine.process(event: event)
        XCTAssertEqual(2, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent1 = mockRuntime.dispatchedEvents[0]
        let dispatchedEvent2 = mockRuntime.dispatchedEvents[1]
        mockRuntime.dispatchedEvents.removeAll()

        // Process dispatched event 1, expect 0 dispatch events
        // chain count = 1, which is max chained events
        _ = rulesEngine.process(event: dispatchedEvent1)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        mockRuntime.dispatchedEvents.removeAll()

        // Process dispatched event 2, expect 0 dispatch events
        // chain count = 1, which is max chained events
        _ = rulesEngine.process(event: dispatchedEvent2)
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        mockRuntime.dispatchedEvents.removeAll()
    }

    // MARK: - Transforming tests
    // test that the data can be transformed to the correct type
    func testTransform() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testTransform")
        let event = Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                          data: ["lifecyclecontextdata": ["numberString": "3", "booleanValue": true, "intValue": 5, "doubleValue": 10.3]])

        /// When:
        rulesEngine.process(event: event)
        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let consequenceEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.rulesEngine, consequenceEvent.type)
        XCTAssertEqual(EventSource.responseContent, consequenceEvent.source)
        guard let data = consequenceEvent.data?["triggeredconsequence"], let dataWithType = data as? [String: Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual("url", dataWithType["type"] as! String)
    }

    func testHistoricalConditionsNotPassing() {
        /// Given:
        resetRulesEngine(withNewRules: "rules_testHistory")

        /// When:
        rulesEngine.process(event: defaultEvent)

        /// Then:
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.receivedEventHistoryRequests.count)
        XCTAssertEqual(false, mockRuntime.receivedEnforceOrder)
    }

    func testHistoricalConditionsPassing() {
        /// Given:
        let mockResult = EventHistoryResult(count: 1, oldest: nil, newest: nil)
        mockRuntime.mockEventHistoryResults = [mockResult]
        resetRulesEngine(withNewRules: "rules_testHistory")

        /// When:
        rulesEngine.process(event: defaultEvent)

        /// Then:
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual(1, mockRuntime.receivedEventHistoryRequests.count)
        XCTAssertEqual(false, mockRuntime.receivedEnforceOrder)
    }

    private func resetRulesEngine(withNewRules rulesJsonFileName: String) {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: rulesJsonFileName, withExtension: "json"), let data = try? Data(contentsOf: url) else {
            XCTFail()
            return
        }
        guard let rules = JSONRulesParser.parse(data, runtime: mockRuntime) else {
            XCTFail()
            return
        }
        rulesEngine.rulesEngine.clearRules()
        rulesEngine.rulesEngine.addRules(rules: rules)
    }

    private func waitForProcessing(interval: TimeInterval = 0.5) {
        let expectation = XCTestExpectation()
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + interval - 0.05) {
            expectation.fulfill()
        }
        wait(for:[expectation], timeout: interval)
    }

}
