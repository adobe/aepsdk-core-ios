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

import XCTest
@testable import AEPCore
import AEPServices
import AEPServicesMock
import AEPCoreMocks

/// Functional tests for the rules engine feature
class RulesEngineFunctionalTests: XCTestCase {
    var mockSystemInfoService: MockSystemInfoService!
    var mockRuntime: TestableExtensionRuntime!
    var rulesEngine: LaunchRulesEngine!

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        rulesEngine = LaunchRulesEngine(extensionRuntime: mockRuntime)
        rulesEngine.trace { (result, rule, conext, failure) in
            print(failure)
        }
    }
    
    static var rulesUrl: URL? {
        return Bundle(for: self).url(forResource: "rules_functional_1", withExtension: ".zip")
    }
    
    func testUpdateConfigurationWithDictTwice() {
        // setup
        let event =  Event(name: "Configure with file path", type: EventType.lifecycle, source: EventSource.responseContent,
                           data: ["lifecyclecontextdata": ["launchevent":"LaunchEvent"]])
        
        let filePath = Bundle(for: RulesEngineFunctionalTests.self).url(forResource: "rules_functional_1", withExtension: ".zip")
        let expectedData = try? Data(contentsOf: filePath!)
        
       let httpResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockNetworkService = TestableNetworkService()
        mockNetworkService.mockRespsonse = (data: expectedData, respsonse: httpResponse, error: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        mockRuntime.simulateSharedState(for: "com.adobe.module.lifecycle", data: (value: ["lifecyclecontextdata":["carriername":"AT&T"]], status: .set))
        
        // test
        rulesEngine.loadRemoteRules(from: URL(string: "http://test.com/rules.url")!)
        let processedEvent = rulesEngine.process(event: event)
        
        // verify
        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        XCTAssertEqual("value", processedEvent.data?["key"] as? String)
        
    }
}
