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
@testable import AEPCoreMocks
import XCTest

class MobileCore_IdentityTests: XCTestCase {
    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
    }

    private func registerMockExtension<T: Extension>(_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { error in
            XCTAssertNil(error)
            semaphore.signal()
        }

        semaphore.wait()
    }

    // MARK: setAdvertisingIdentifier(...) tests

    /// Tests that when setAdvertisingIdentifier is called that we dispatch an event with the advertising identifier in the event data
    func testSetAdvertisingIdentifierHappy() {
        // setup
        let expectation = XCTestExpectation(description: "Should dispatch a generic identity event with the ad id")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)

        EventHub.shared.start()

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericIdentity, source: EventSource.requestContent, listener: { event in
            XCTAssertEqual("test-ad-id", event.data?[CoreConstants.Keys.ADVERTISING_IDENTIFIER] as? String)
            expectation.fulfill()
        })

        // test
        MobileCore.setAdvertisingIdentifier("test-ad-id")

        // verify
        wait(for: [expectation], timeout: 1.0)
    }

    /// Tests that when nil is passed to setAdvertisingId that we convert it to an empty string since swift cannot hold nil in a dict
    func testSetAdvertisingIdentifierNil() {
        // setup
        let expectation = XCTestExpectation(description: "Should dispatch a generic identity event with the ad id")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)

        EventHub.shared.start()

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericIdentity, source: EventSource.requestContent, listener: { event in
            XCTAssertEqual("", event.data?[CoreConstants.Keys.ADVERTISING_IDENTIFIER] as? String)
            expectation.fulfill()
        })

        // test
        MobileCore.setAdvertisingIdentifier(nil)

        // verify
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: setPushIdentifier(...) tests

    /// Tests that when setPushIdentifier is called that we dispatch an event with the push identifier in the event data
    func testSetPushIdentifierHappy() {
        // setup
        let expectation = XCTestExpectation(description: "Should dispatch a generic identity event with the push id")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.start()
        let pushIdData = "test-push-id".data(using: .utf8)!
        let encodedPushId = "746573742D707573682D6964"

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericIdentity, source: EventSource.requestContent, listener: { event in
            XCTAssertEqual(encodedPushId, event.data?[CoreConstants.Keys.PUSH_IDENTIFIER] as? String)
            expectation.fulfill()
        })

        // test
        MobileCore.setPushIdentifier(pushIdData)

        // verify
        wait(for: [expectation], timeout: 1.0)
    }

    /// Tests that when setPushIdentifier is called that we dispatch an event with the push identifier in the event data and that an empty push id is handled properly
    func testSetPushIdentifierEmptyPushId() {
        // setup
        let expectation = XCTestExpectation(description: "Should dispatch a generic identity event with the push id")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.start()
        let pushIdData = "".data(using: .utf8)!
        let encodedPushId = ""

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericIdentity, source: EventSource.requestContent, listener: { event in
            XCTAssertEqual(encodedPushId, event.data?[CoreConstants.Keys.PUSH_IDENTIFIER] as? String)
            expectation.fulfill()
        })

        // test
        MobileCore.setPushIdentifier(pushIdData)

        // verify
        wait(for: [expectation], timeout: 1.0)
    }

    /// Tests that when setPushIdentifier is called that we dispatch an event with the push identifier in the event data and that an nil push id is handled properly
    func testSetPushIdentifierNilPushId() {
        // setup
        let expectation = XCTestExpectation(description: "Should dispatch a generic identity event with the push id")
        expectation.assertForOverFulfill = true

        registerMockExtension(MockExtension.self)
        EventHub.shared.start()
        let encodedPushId = ""

        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.genericIdentity, source: EventSource.requestContent, listener: { event in
            XCTAssertEqual(encodedPushId, event.data?[CoreConstants.Keys.PUSH_IDENTIFIER] as? String)
            expectation.fulfill()
        })

        // test
        MobileCore.setPushIdentifier(nil)

        // verify
        wait(for: [expectation], timeout: 1.0)
    }
}
