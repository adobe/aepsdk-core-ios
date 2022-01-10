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

@testable import AEPCore
import XCTest
import AEPCoreMocks
import AEPServices
import AEPServicesMocks
import XCTest

class ConfigurationLifecycleResponseTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var configuration: Configuration!

    override func setUp() {
        UserDefaults.clear()
        mockRuntime = TestableExtensionRuntime()
        configuration = Configuration(runtime: mockRuntime)
        configuration.onRegistered()
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    /// Tests that no configuration event is dispatched when a lifecycle response content event and no appId is stored in persistence
    func testHandleLifecycleResponseEmptyAppId() {
        // setup
        let lifecycleEvent = Event(name: "Lifecycle response content", type: EventType.lifecycle, source: EventSource.responseContent, data: nil)

        // test
        mockRuntime.simulateComingEvents(lifecycleEvent)

        // verify
        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

}
