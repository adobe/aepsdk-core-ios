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

@available(iOS 12.0, tvOS 12.0, *)
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

    // MARK: - updateProfileAttributes(_:)

    func testDispatchesEventWithTimezone() {
        let expectation = XCTestExpectation(description: "genericProfileAttributes event dispatched")
        expectation.assertForOverFulfill = true

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { event in
            if let tz = event.data?[CoreConstants.ProfileAttributeKeys.TIMEZONE] as? String, !tz.isEmpty {
                expectation.fulfill()
            }
        }

        let attributes = ProfileAttributes.Builder()
            .setTimezone(TimeZone(identifier: "America/Los_Angeles"))
            .build()
        MobileCore.updateProfileAttributes(attributes)
        wait(for: [expectation], timeout: 1.0)
    }

    func testEventContainsCorrectIANAIdentifier() {
        let expectation = XCTestExpectation(description: "Event data contains correct timezone identifier")
        let zone = TimeZone(identifier: "Asia/Kolkata")!

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { event in
            guard let tz = event.data?[CoreConstants.ProfileAttributeKeys.TIMEZONE] as? String else { return }
            XCTAssertEqual(tz, zone.identifier)
            expectation.fulfill()
        }

        let attributes = ProfileAttributes.Builder()
            .setTimezone(zone)
            .build()
        MobileCore.updateProfileAttributes(attributes)
        wait(for: [expectation], timeout: 1.0)
    }

    func testEventHasCorrectName() {
        let expectation = XCTestExpectation(description: "Event has correct name")

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { event in
            XCTAssertEqual(event.name, CoreConstants.EventNames.UPDATE_PROFILE_ATTRIBUTES)
            expectation.fulfill()
        }

        let attributes = ProfileAttributes.Builder()
            .setTimezone(TimeZone(identifier: "America/Chicago"))
            .build()
        MobileCore.updateProfileAttributes(attributes)
        wait(for: [expectation], timeout: 1.0)
    }

    func testEventHasCorrectTypeAndSource() {
        let expectation = XCTestExpectation(description: "Event has the type/source EdgeIdentity listens for")

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { event in
            XCTAssertEqual(event.type, EventType.genericProfileAttributes)
            XCTAssertEqual(event.source, EventSource.requestContent)
            expectation.fulfill()
        }

        let attributes = ProfileAttributes.Builder()
            .setTimezone(TimeZone(identifier: "Europe/London"))
            .build()
        MobileCore.updateProfileAttributes(attributes)
        wait(for: [expectation], timeout: 1.0)
    }

    func testNoDispatchWhenNoAttributesSet() {
        var eventDispatched = false
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(
            type: EventType.genericProfileAttributes, source: EventSource.requestContent
        ) { _ in
            eventDispatched = true
        }

        let attributes = ProfileAttributes.Builder().build()
        MobileCore.updateProfileAttributes(attributes)

        // Allow time for any spurious dispatch
        let waiter = XCTestExpectation(description: "wait")
        waiter.isInverted = true
        wait(for: [waiter], timeout: 0.5)
        XCTAssertFalse(eventDispatched, "No event should be dispatched when no attributes are set")
    }

    func testBuilderSetterIsChainable() {
        let builder = ProfileAttributes.Builder()
        let returned = builder.setTimezone(TimeZone(identifier: "Asia/Tokyo"))
        XCTAssertTrue(returned === builder, "setTimezone must return self for chaining")
    }
}
