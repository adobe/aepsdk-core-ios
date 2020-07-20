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
@testable import AEPCore
import AEPServices
import AEPEventHub
import AEPServicesMock

class IdentityStateTests: XCTestCase {

    var state: IdentityState!
    var mockHitQueue: MockHitQueue {
        return state.hitQueue as! MockHitQueue
    }
    
    override func setUp() {
        AEPServiceProvider.shared.namedKeyValueService = MockDataStore()
        state = IdentityState(identityProperties: IdentityProperties(), hitQueue: MockHitQueue(processor: MockHitProcessor()))

    }
    
    // MARK: syncIdentifiers(...) tests
    
    /// Tests that syncIdentifiers appends the MID and the two custom IDs to the visitor ID list
    func testSyncIdentifiersHappyIDs() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org",
                                 IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "test-server",
                                 IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        state.lastValidConfig = configSharedState
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeSyncIDEvent())
        
        // verify
        XCTAssertEqual(2, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        let idList = eventData![IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity]
        XCTAssertEqual(2, idList?.count)
        XCTAssertFalse(mockHitQueue.queuedHits.isEmpty) // hit should be queued in the hit queue
    }
    
    // TODO enable after AMSDK-10262
    func testSyncIdentifiersHappyPushID() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org",
                         IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "test-server",
                         IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        state.lastValidConfig = configSharedState
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakePushIDEvent())
        
        // verify
        XCTAssertEqual(2, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        XCTAssertEqual("test-push-id", eventData![IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] as? String)
        XCTAssertFalse(mockHitQueue.queuedHits.isEmpty) // hit should be queued in the hit queue
    }
    
    /// Tests that the mid is appended and the ad id is appended to the visitor id list
    func testSyncIdentifiersHappyAdID() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org",
                                 IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "test-server",
                                 IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        state.lastValidConfig = configSharedState
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeAdIDEvent())
        
        // verify
        XCTAssertEqual(3, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        XCTAssertEqual("test-ad-id", eventData![IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] as? String)
        let idList = eventData![IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity]
        XCTAssertEqual(1, idList?.count)
        let customId = idList?.first!
        XCTAssertEqual("test-ad-id", customId?.identifier)
        XCTAssertEqual("d_cid_ic", customId?.origin)
        XCTAssertEqual("DSID_20915", customId?.type)
        XCTAssertFalse(mockHitQueue.queuedHits.isEmpty) // hit should be queued in the hit queue
    }
    
    /// Tests that the ad is is correctly preserved when the same ad id is sync'd
    func testSyncIdentifiersAdIDIsSame() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org",
                                 IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "test-server",
                                 IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        var props = IdentityProperties()
        props.advertisingIdentifier = "test-ad-id"
        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))
        state.lastValidConfig = configSharedState
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeAdIDEvent())
        
        // verify
        XCTAssertEqual(3, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        XCTAssertEqual(props.advertisingIdentifier, eventData![IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] as? String)
        let idList = eventData![IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity]
        XCTAssertTrue(idList?.isEmpty ?? false)
        XCTAssertFalse(mockHitQueue.queuedHits.isEmpty) // hit should be queued in the hit queue
    }
    
    /// Tests that the location hint and blob are present int he event data
    func testSyncIdentifiersAppendsBlobAndLocationHint() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org",
                         IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "test-server",
                         IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        var props = IdentityProperties()
        props.locationHint = "locHinty"
        props.blob = "blobby"
        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))
        state.lastValidConfig = configSharedState
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakePushIDEvent())
        
        // verify
        XCTAssertEqual(4, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        XCTAssertEqual(props.locationHint, eventData![IdentityConstants.EventDataKeys.VISITOR_ID_LOCATION_HINT] as? String)
        XCTAssertEqual(props.blob, eventData![IdentityConstants.EventDataKeys.VISITOR_ID_BLOB] as? String)
        // TODO AMSDK-10262: Assert push identifier
        XCTAssertFalse(mockHitQueue.queuedHits.isEmpty) // hit should be queued in the hit queue
    }
    
    // Disabled, TODO: AMSDK-10261
    func testSyncIdentifiersDoesNotQueue() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "test-org",
                                 IdentityConstants.Configuration.EXPERIENCE_CLOUD_SERVER: "test-server",
                                 IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID() // visitor ID is null initially and set for the first time in
        // shouldSync(). Mimic a second call to shouldSync by setting the mid
        props.lastSync = Date() // set last sync to now
        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))
        state.lastValidConfig = configSharedState
        
        // test
        let data = [IdentityConstants.EventDataKeys.IS_SYNC_EVENT: true] as [String : Any]
        let _ = state.syncIdentifiers(event: Event(name: "ID Sync Test Event", type: .identity, source: .requestIdentity, data: data))
        
        // verify
        XCTAssertTrue(mockHitQueue.queuedHits.isEmpty) // hit should NOT be queued in the hit queue
    }
    
    func testSyncIdentifiersWhenPrivacyIsOptIn() {
        // setup
        state.lastValidConfig = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "latestOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeSyncIDEvent())
        
        // verify
        XCTAssertNotNil(eventData)
    }
    
    /// We are ready to process the event when the config shared state has an opt-in privacy status but our previous config has an opt-out
    func testSyncIdentifiersReturnTrueWhenLatestPrivacyIsOptOut() {
        // setup
        state.lastValidConfig = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "latestOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut] as [String : Any]
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeSyncIDEvent())
        
        // verify
        XCTAssertNil(eventData)
    }
    
    // MARK: readyForSyncIdentifiers(...)
    
    /// When no valid configuration is available we should return false to wait for a valid configuration
    func testReadyForSyncIdentifiersNoValidConfig() {
        // test
        let readyForSync = state.readyForSyncIdentifiers(event: Event.fakeSyncIDEvent(), configurationSharedState: [:])
        
        // verify
        XCTAssertFalse(readyForSync)
    }
    
    func testReadyForSyncIdentifiersShouldSyncWithEmptyCurrentConfigButValidLatestConfig() {
        // setup
        state.lastValidConfig = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "latestOrg", IdentityConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        
        // test
        let readyForSync = state.readyForSyncIdentifiers(event: Event.fakeSyncIDEvent(), configurationSharedState: [:])
        
        // verify
        XCTAssertTrue(readyForSync)
    }
    
    func testReadyForSyncIdentifiersShouldNotSyncWithEmptyCurrentConfigAndNilLatestConfig() {
        // setup
        let configSharedState = [IdentityConstants.Configuration.EXPERIENCE_CLOUD_ORGID: ""] as [String : Any]
        
        // test
        let readyForSync = state.readyForSyncIdentifiers(event: Event.fakeSyncIDEvent(), configurationSharedState: configSharedState)
        
        // verify
        XCTAssertFalse(readyForSync)
    }
    
    // MARK: handleHitResponse(...) tests
    
    /// Tests that when a non-opt out response is handled that we update the last sync and other identity properties, along with dispatching two identity events
    func testHandleHitResponseHappy() {
        // setup
        let dispatchedEventExpectation = XCTestExpectation(description: "Two events should be dispatched")
        dispatchedEventExpectation.expectedFulfillmentCount = 2 // 2 identity events
        dispatchedEventExpectation.assertForOverFulfill = true

        var props = IdentityProperties()
        props.lastSync = Date()
        props.privacyStatus = .optedIn
        let entity = DataEntity.fakeDataEntity()
        let hitResponse = IdentityHitResponse.fakeHitResponse(error: nil, optOutList: nil)

        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))

        // test
        state.handleHitResponse(hit: entity, response: try! JSONEncoder().encode(hitResponse)) { (event) in
            XCTAssertEqual(state.identityProperties.toEventData().count, event.data?.count) // event should contain the identity properties in the event data
            dispatchedEventExpectation.fulfill()
        }

        // verify
        wait(for: [dispatchedEventExpectation], timeout: 0.5)
        XCTAssertNotEqual(props.lastSync, state.identityProperties.lastSync) // sync should be updated regardless of response
        XCTAssertEqual(hitResponse.blob, state.identityProperties.blob) // blob should have been updated
        XCTAssertEqual(hitResponse.hint, state.identityProperties.locationHint) // locationHint should have been updated
        XCTAssertEqual(hitResponse.ttl, state.identityProperties.ttl) // ttl should have been updated
    }

    /// When the opt-out list in the response is not empty that we dispatch a configuration event setting the privacy to opt out
    func testHandleHitResponseOptOutList() {
        // setup
        let dispatchedEventExpectation = XCTestExpectation(description: "Three events should be dispatched")
        dispatchedEventExpectation.expectedFulfillmentCount = 3 // 2 identity events, 1 configuration
        dispatchedEventExpectation.assertForOverFulfill = true

        var props = IdentityProperties()
        props.lastSync = Date()
        props.privacyStatus = .optedIn
        let entity = DataEntity.fakeDataEntity()
        let hitResponse = IdentityHitResponse.fakeHitResponse(error: nil, optOutList: ["optOut"])

        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))

        // test
        state.handleHitResponse(hit: entity, response: try! JSONEncoder().encode(hitResponse)) { (event) in
            dispatchedEventExpectation.fulfill()
        }

        // verify
        wait(for: [dispatchedEventExpectation], timeout: 0.5)
        XCTAssertNotEqual(props.lastSync, state.identityProperties.lastSync) // sync should be updated regardless of response
        XCTAssertEqual(hitResponse.blob, state.identityProperties.blob) // blob should have been updated
        XCTAssertEqual(hitResponse.hint, state.identityProperties.locationHint) // locationHint should have been updated
        XCTAssertEqual(hitResponse.ttl, state.identityProperties.ttl) // ttl should have been updated
    }

    /// Tests that when the hit response indicates an error that we do not update the identity properties
    func testHandleHitResponseError() {
        // setup
        let dispatchedEventExpectation = XCTestExpectation(description: "Two events should be dispatched")
        dispatchedEventExpectation.expectedFulfillmentCount = 2 // 2 identity events
        dispatchedEventExpectation.assertForOverFulfill = true

        var props = IdentityProperties()
        props.lastSync = Date()
        props.privacyStatus = .optedIn
        let entity = DataEntity.fakeDataEntity()
        let hitResponse = IdentityHitResponse.fakeHitResponse(error: "err message", optOutList: nil)

        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))

        // test
        state.handleHitResponse(hit: entity, response: try! JSONEncoder().encode(hitResponse)) { (event) in
            dispatchedEventExpectation.fulfill()
        }

        // verify
        wait(for: [dispatchedEventExpectation], timeout: 0.5)
        XCTAssertNotEqual(props.lastSync, state.identityProperties.lastSync) // sync should be updated regardless of response
        XCTAssertNotEqual(hitResponse.blob, state.identityProperties.blob) // blob should not have been updated
        XCTAssertNotEqual(hitResponse.hint, state.identityProperties.locationHint) // locationHint should not have been updated
        XCTAssertNotEqual(hitResponse.ttl, state.identityProperties.ttl) // ttl should not have been updated
    }

    /// Tests that when we are opted out that we do not update the identity properties
    func testHandleHitResponseOptOut() {
        // setup
        let dispatchedEventExpectation = XCTestExpectation(description: "Two events should be dispatched")
        dispatchedEventExpectation.expectedFulfillmentCount = 2 // 2 identity events
        dispatchedEventExpectation.assertForOverFulfill = true

        var props = IdentityProperties()
        props.lastSync = Date()
        props.privacyStatus = .optedOut
        let entity = DataEntity.fakeDataEntity()
        let hitResponse = IdentityHitResponse.fakeHitResponse(error: nil, optOutList: ["optOut"])

        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))

        // test
        state.handleHitResponse(hit: entity, response: try! JSONEncoder().encode(hitResponse)) { (event) in
            dispatchedEventExpectation.fulfill()
        }

        // verify
        wait(for: [dispatchedEventExpectation], timeout: 0.5)
        XCTAssertNotEqual(props.lastSync, state.identityProperties.lastSync) // sync should be updated regardless of response
        XCTAssertNotEqual(hitResponse.blob, state.identityProperties.blob) // blob should not have been updated
        XCTAssertNotEqual(hitResponse.hint, state.identityProperties.locationHint) // locationHint should not have been updated
        XCTAssertNotEqual(hitResponse.ttl, state.identityProperties.ttl) // ttl should not have been updated
    }

    /// Tests that when we get nil data back that we only dispatch one event and do not update the properties
    func testHandleHitResponseNilData() {
        // setup
        let dispatchedEventExpectation = XCTestExpectation(description: "One event should be dispatched")
        dispatchedEventExpectation.assertForOverFulfill = true

        var props = IdentityProperties()
        props.lastSync = Date()
        props.privacyStatus = .optedOut

        state = IdentityState(identityProperties: props, hitQueue: MockHitQueue(processor: MockHitProcessor()))

        // test
        state.handleHitResponse(hit: DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: nil), response: nil) { (event) in
            dispatchedEventExpectation.fulfill()
        }

        // verify
        wait(for: [dispatchedEventExpectation], timeout: 0.5)
        XCTAssertNotEqual(props.lastSync, state.identityProperties.lastSync) // sync should be updated regardless of response
    }

}

private extension Event {
    static func fakeSyncIDEvent() -> Event {
        let ids = ["k1": "v1", "k2": "v2"]
        let data = [IdentityConstants.EventDataKeys.IDENTIFIERS: ids, IdentityConstants.EventDataKeys.IS_SYNC_EVENT: true] as [String : Any]
        return Event(name: "Fake Sync Event", type: .identity, source: .requestReset, data: data)
    }
    
    static func fakePushIDEvent() -> Event {
        let data = [IdentityConstants.EventDataKeys.PUSH_IDENTIFIER: "test-push-id"]
        return Event(name: "Fake Sync Event", type: .genericIdentity, source: .requestReset, data: data)
    }
    
    static func fakeAdIDEvent() -> Event {
        let data = [IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER: "test-ad-id"]
        return Event(name: "Fake Sync Event", type: .genericIdentity, source: .requestReset, data: data)
    }
}

private extension DataEntity {
    static func fakeDataEntity() -> DataEntity {
        let event = Event(name: "Hit Event", type: .identity, source: .requestIdentity, data: nil)
        let hit = IdentityHit(url: URL(string: "adobe.com")!, event: event)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try! JSONEncoder().encode(hit))

        return entity
    }
}

private extension IdentityHitResponse {
    static func fakeHitResponse(error: String?, optOutList: [String]?) -> IdentityHitResponse {
        return IdentityHitResponse(blob: "response-test-blob", mid: "response-test-mid", hint: "response-test-hint", error: error, ttl: 3000, optOutList: optOutList)
    }
}
