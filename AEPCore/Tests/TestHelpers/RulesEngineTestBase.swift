/*
 Copyright 2025 Adobe. All rights reserved.
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
import AEPServices

@testable import AEPCore

/// Base class providing setup and utility methods for rules engine tests
class RulesEngineTestBase: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var rulesEngine: LaunchRulesEngine!
    var defaultEvent: Event!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        mockRuntime = TestableExtensionRuntime()
        defaultEvent = Event(name: "Configure with file path",
                             type: EventType.lifecycle,
                             source: EventSource.responseContent,
                             data: ["lifecyclecontextdata": ["launchevent": "LaunchEvent"]])
        Log.logFilter = .trace
        rulesEngine = LaunchRulesEngine(name: "test_rules_engine", extensionRuntime: mockRuntime)
        rulesEngine.trace { _, _, _, failure in
            print(failure ?? "unknown failure")
        }
    }

    /// Provides a URL to a bundled rules ZIP for use in tests.
    static var rulesUrl: URL? {
        return Bundle(for: self).url(forResource: "rules_functional_1", withExtension: "zip")
    }

    /// Helper to reset the rules engine with new rules from a JSON file
    func resetRulesEngine(withNewRules rulesJsonFileName: String) {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: rulesJsonFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rules = JSONRulesParser.parse(data, runtime: mockRuntime) else {
            XCTFail("Failed to load or parse rules: \(rulesJsonFileName)")
            return
        }

        rulesEngine.rulesEngine.clearRules()
        rulesEngine.rulesEngine.addRules(rules: rules)
    }

    /// Waits for the rules engine to process async events
    func waitForProcessing(interval: TimeInterval = 0.5) {
        let expectation = XCTestExpectation(description: "Wait for processing")
        DispatchQueue.global().asyncAfter(deadline: .now() + interval - 0.05) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: interval)
    }
}
