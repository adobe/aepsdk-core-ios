/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest

@testable import AEPCore
@testable import AEPCoreMocks
@testable import AEPServices

class MobileCore_ProfileAttributesTests: XCTestCase {

    override func setUp() {
        NamedCollectionDataStore.clear()
        MobileCore.resetSDK()
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    override func tearDown() {
        MobileCore.resetSDK()
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in semaphore.signal() }
        semaphore.wait()
    }

    // MARK: - updateProfileAttributes().setTimezone()

    func testSetTimezoneDispatchesEvent() {
        let expectation = XCTestExpectation(description: "genericProfileAttributes event dispatched")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { event in
            if let tz = event.data?[CoreConstants.ProfileAttributeKeys.TIMEZONE] as? String, !tz.isEmpty {
                expectation.fulfill()
            }
        }

        MobileCore.updateProfileAttributes().setTimezone(TimeZone(identifier: "America/Los_Angeles")!)
        wait(for: [expectation], timeout: 1.0)
    }

    func testSetTimezoneEventContainsIdentifier() {
        let expectation = XCTestExpectation(description: "Event data contains correct timezone identifier")
        let zone = TimeZone(identifier: "Asia/Kolkata")!

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { event in
            guard let tz = event.data?[CoreConstants.ProfileAttributeKeys.TIMEZONE] as? String else { return }
            XCTAssertEqual(tz, zone.identifier)
            expectation.fulfill()
        }

        MobileCore.updateProfileAttributes().setTimezone(zone)
        wait(for: [expectation], timeout: 1.0)
    }

    func testSetTimezoneEventName() {
        let expectation = XCTestExpectation(description: "Event has correct name")

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { event in
            XCTAssertEqual(event.name, CoreConstants.EventNames.UPDATE_PROFILE_ATTRIBUTES)
            expectation.fulfill()
        }

        MobileCore.updateProfileAttributes().setTimezone(TimeZone(identifier: "America/Chicago")!)
        wait(for: [expectation], timeout: 1.0)
    }

    func testBuilderIsChainable() {
        let builder = MobileCore.updateProfileAttributes()
        let zone = TimeZone(identifier: "Asia/Tokyo")!
        let returned = builder.setTimezone(zone)
        XCTAssertTrue(returned === builder, "setTimezone must return self for chaining")
    }

}
