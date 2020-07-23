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
@testable import AEPIdentity
import AEPServices
import AEPServicesMock

class PushIDManagerTests: XCTestCase {

    var pushIdManager: PushIDManager!

    private var pushEnabled: Bool {
        get {
            return AEPServiceProvider.shared.namedKeyValueService.get(collectionName: "TestCollection", key: IdentityConstants.DataStoreKeys.PUSH_ENABLED) as? Bool ?? false
        }

        set {
            AEPServiceProvider.shared.namedKeyValueService.set(collectionName: "TestCollection", key: IdentityConstants.DataStoreKeys.PUSH_ENABLED, value: newValue)
        }
    }

    override func setUp() {
        AEPServiceProvider.shared.namedKeyValueService = MockDataStore()
    }

    /// Tests that when we set the first push id to nil and the existing push id is nil that we dispatch a analytics event
    func testUpdatePushIdNilExistingIdUpdatesToNil() {
        // setup
        let expectation = XCTestExpectation(description: "Analytics events should be dispatched with the push status")

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            let contextData = event.data?[IdentityConstants.Analytics.CONTEXT_DATA] as? [String: String]
            XCTAssertEqual(contextData?[IdentityConstants.Analytics.EVENT_PUSH_STATUS], "False") // push status should be set to true
            XCTAssertEqual(event.data?[IdentityConstants.Analytics.TRACK_ACTION] as? String, IdentityConstants.Analytics.PUSH_ID_ENABLED_ACTION_NAME)
            expectation.fulfill()
        })

        // test
        pushIdManager.updatePushId(pushId: nil)

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertNil(props.pushIdentifier) // push identifier should be nil
    }

    /// Ensures that we do not dispatch an analytics event when analytics sync flag is true
    func testUpdatePushIdNilExistingIdUpdatesToNilAnalyticsSyncTrue() {
        // setup
        let expectation = XCTestExpectation(description: "Analytics events should not be dispatched with the push status")
        expectation.isInverted = true
        AEPServiceProvider.shared.namedKeyValueService.set(collectionName: "TestCollection", key: IdentityConstants.DataStoreKeys.ANALYTICS_PUSH_SYNC, value: true)

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            expectation.fulfill()
        })

        // test
        pushIdManager.updatePushId(pushId: nil)

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertNil(props.pushIdentifier) // push identifier should be nil
    }

    /// Tests that when we update the push id with the same push id that we do not dispatch an analytics event
    func testUpdatePushIdUpdatesToSameId() {
        // setup
        let existingPushId = "existingPushID"
        var existingProps = IdentityProperties()
        existingProps.pushIdentifier = existingPushId.sha256()
        existingProps.saveToPersistence()
        pushEnabled = true

        let expectation = XCTestExpectation(description: "Analytics events should be NOT dispatched with the push status")
        expectation.isInverted = true

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            expectation.fulfill()
        })

        // test
        pushIdManager.updatePushId(pushId: existingPushId)

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertEqual(props.pushIdentifier, existingProps.pushIdentifier) // push ID should have remained the same
        XCTAssertTrue(pushEnabled) // push should still be enabled
    }

    /// Tests that when we do not have a push id saved that we update to a new ID and dispatch analytics events
    func testUpdatePushIdNilExistingIdUpdatesToValidAndPushDisabled() {
        // setup
        let expectation = XCTestExpectation(description: "Analytics events should be dispatched with the push status")
        let testPushId = "newPushId"

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            let contextData = event.data?[IdentityConstants.Analytics.CONTEXT_DATA] as? [String: String]
            XCTAssertEqual(contextData?[IdentityConstants.Analytics.EVENT_PUSH_STATUS], "True") // push status should be set to true
            XCTAssertEqual(event.data?[IdentityConstants.Analytics.TRACK_ACTION] as? String, IdentityConstants.Analytics.PUSH_ID_ENABLED_ACTION_NAME)
            expectation.fulfill()
        })

        // test
        pushIdManager.updatePushId(pushId: testPushId)

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertEqual(props.pushIdentifier, testPushId.sha256()) // push id in datastore should have been updated
        XCTAssertTrue(pushEnabled) // push should have been enabled
    }

    /// Tests that when we do not have a push id saved and we have push enabled that we do not send an analytics hit when updating to a valid push id
    func testUpdatePushIdNilExistingIdUpdatesToValidAndPushEnabled() {
        // setup
        let expectation = XCTestExpectation(description: "Analytics events should be dispatched with the push status")
        expectation.isInverted = true

        let testPushId = "newPushId"
        pushEnabled = true

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            expectation.fulfill() // should not dispatch an analytics request as we already have push enabled set to true
        })

        // test
        pushIdManager.updatePushId(pushId: testPushId)

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertEqual(props.pushIdentifier, testPushId.sha256())
        XCTAssertTrue(pushEnabled) // push should have remained enabled
    }

    /// Tests that when we have a push id saved that we update to a new ID and dispatch analytics events
    func testUpdatePushIdNotNilExistingIdUpdatesToValidPushDisabled() {
        // setup
        var existingProps = IdentityProperties()
        existingProps.pushIdentifier = "existingPushID"
        existingProps.saveToPersistence()

        let expectation = XCTestExpectation(description: "Analytics events should be dispatched with the push status")
        let testPushId = "newPushId"

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            let contextData = event.data?[IdentityConstants.Analytics.CONTEXT_DATA] as? [String: String]
            XCTAssertEqual(contextData?[IdentityConstants.Analytics.EVENT_PUSH_STATUS], "True") // push status should be set to true
            XCTAssertEqual(event.data?[IdentityConstants.Analytics.TRACK_ACTION] as? String, IdentityConstants.Analytics.PUSH_ID_ENABLED_ACTION_NAME)
            expectation.fulfill()
        })

        // test
        pushIdManager.updatePushId(pushId: testPushId)

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertEqual(props.pushIdentifier, testPushId.sha256())
        XCTAssertTrue(pushEnabled) // push should have been enabled
    }

    /// Tests that when we have a push id saved that we update to a new nil id that we set push to disabled
    func testUpdatePushIdNotNilExistingIdUpdatesToNil() {
        // setup
        AEPServiceProvider.shared.namedKeyValueService.set(collectionName: "TestCollection", key: IdentityConstants.DataStoreKeys.PUSH_ENABLED, value: true)
        var existingProps = IdentityProperties()
        existingProps.pushIdentifier = "existingPushID"
        existingProps.saveToPersistence()
        pushEnabled = true

        let expectation = XCTestExpectation(description: "Analytics events should be dispatched with the push status")

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            let contextData = event.data?[IdentityConstants.Analytics.CONTEXT_DATA] as? [String: String]
            XCTAssertEqual(contextData?[IdentityConstants.Analytics.EVENT_PUSH_STATUS], "False") // push status should be set to true
            XCTAssertEqual(event.data?[IdentityConstants.Analytics.TRACK_ACTION] as? String, IdentityConstants.Analytics.PUSH_ID_ENABLED_ACTION_NAME)
            expectation.fulfill()
        })

        // test
        pushIdManager.updatePushId(pushId: nil)

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertNil(props.pushIdentifier)
        XCTAssertFalse(pushEnabled)
    }

    /// Tests that when we have a push id saved that we update to a new empty id that we set push to disabled
    func testUpdatePushIdNotNilExistingIdUpdatesToEmpty() {
        // setup
        AEPServiceProvider.shared.namedKeyValueService.set(collectionName: "TestCollection", key: IdentityConstants.DataStoreKeys.PUSH_ENABLED, value: true)
        var existingProps = IdentityProperties()
        existingProps.pushIdentifier = "existingPushID"
        existingProps.saveToPersistence()
        pushEnabled = true

        let expectation = XCTestExpectation(description: "Analytics events should be dispatched with the push status")

        pushIdManager = PushIDManager(dataStore: NamedKeyValueStore(name: "PushIDManagerTests"), eventDispatcher: { (event) in
            let contextData = event.data?[IdentityConstants.Analytics.CONTEXT_DATA] as? [String: String]
            XCTAssertEqual(contextData?[IdentityConstants.Analytics.EVENT_PUSH_STATUS], "False") // push status should be set to true
            XCTAssertEqual(event.data?[IdentityConstants.Analytics.TRACK_ACTION] as? String, IdentityConstants.Analytics.PUSH_ID_ENABLED_ACTION_NAME)
            expectation.fulfill()
        })

        // test
        pushIdManager.updatePushId(pushId: "")

        // verify
        wait(for: [expectation], timeout: 0.5)
        var props = IdentityProperties()
        props.loadFromPersistence()
        XCTAssertNotEqual(existingProps.pushIdentifier, props.pushIdentifier)
        XCTAssertFalse(pushEnabled)
    }

}
