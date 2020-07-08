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

class IdentityStateTests: XCTestCase {

    var state = IdentityState(identityProperties: IdentityProperties())
    
    override func setUp() {
        AEPServiceProvider.shared.namedKeyValueService = MockDataStore()
        state = IdentityState(identityProperties: IdentityProperties())
    }
    
    // MARK: syncIdentifiers(...) tests
    
    /// Tests that syncIdentifiers appends the MID and the two custom IDs to the visitor ID list
    func testSyncIdentifiersHappyIDs() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        state.lastValidConfig = configSharedState
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeSyncIDEvent())
        
        // verify
        XCTAssertEqual(2, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        let idList = eventData![IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity]
        XCTAssertEqual(2, idList?.count)
        
        // TODO AMSDK-10261: Verify hit was inserted into DB
    }
    
    // TODO enable after AMSDK-10262
    func testSyncIdentifiersHappyPushID() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        state.lastValidConfig = configSharedState
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakePushIDEvent())
        
        // verify
        XCTAssertEqual(2, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        XCTAssertEqual("test-push-id", eventData![IdentityConstants.EventDataKeys.PUSH_IDENTIFIER] as? String)
        
        // TODO AMSDK-10261: Verify hit was inserted into DB
    }
    
    /// Tests that the mid is appended and the ad id is appended to the visitor id list
    func testSyncIdentifiersHappyAdID() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
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
        
        // TODO AMSDK-10261: Verify hit was inserted into DB
    }
    
    /// Tests that the ad is is correctly preserved when the same ad id is sync'd
    func testSyncIdentifiersAdIDIsSame() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        var props = IdentityProperties()
        props.advertisingIdentifier = "test-ad-id"
        state = IdentityState(identityProperties: props)
        state.lastValidConfig = configSharedState
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeAdIDEvent())
        
        // verify
        XCTAssertEqual(3, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        XCTAssertEqual(props.advertisingIdentifier, eventData![IdentityConstants.EventDataKeys.ADVERTISING_IDENTIFIER] as? String)
        let idList = eventData![IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity]
        XCTAssertTrue(idList?.isEmpty ?? false)
        
        // TODO AMSDK-10261: Verify hit was inserted into DB
    }
    
    /// Tests that the location hint and blob are present int he event data
    func testSyncIdentifiersAppendsBlobAndLocationHint() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        var props = IdentityProperties()
        props.locationHint = "locHinty"
        props.blob = "blobby"
        state = IdentityState(identityProperties: props)
        state.lastValidConfig = configSharedState
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakePushIDEvent())
        
        // verify
        XCTAssertEqual(4, eventData!.count)
        XCTAssertNotNil(eventData![IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        XCTAssertEqual(props.locationHint, eventData![IdentityConstants.EventDataKeys.VISITOR_ID_LOCATION_HINT] as? String)
        XCTAssertEqual(props.blob, eventData![IdentityConstants.EventDataKeys.VISITOR_ID_BLOB] as? String)
        // TODO AMSDK-10262: Assert push identifier
        // TODO AMSDK-10261: Verify hit was inserted into DB
    }
    
    // Disabled, TODO: AMSDK-10261
    func testSyncIdentifiersDoesNotQueue() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        var props = IdentityProperties()
        props.mid = MID() // visitor ID is null initially and set for the first time in
        // shouldSync(). Mimic a second call to shouldSync by setting the mid
        props.lastSync = Date() // set last sync to now
        state = IdentityState(identityProperties: props)
        state.lastValidConfig = configSharedState
        
        // test
        let _ = state.syncIdentifiers(event: Event.fakeSyncIDEvent())
        
        // verify
        // TODO AMSDK-10261: Assert hit was not queued in DB
    }
    
    func testSyncIdentifiersWhenPrivacyIsOptIn() {
        // setup
        state.lastValidConfig = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "latestOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeSyncIDEvent())
        
        // verify
        XCTAssertNotNil(eventData)
    }
    
    /// When the privacy status is currently opt-out we
    func testSyncIdentifiersTrueWhenConfigPrivacyIsOptOut() {
        // setup
        var props = IdentityProperties()
        props.privacyStatus = .optedOut
        state = IdentityState(identityProperties: props)
        state.lastValidConfig = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "latestOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        
        // test
        let eventData = state.syncIdentifiers(event: Event.fakeSyncIDEvent())
        
        // verify
        XCTAssertNil(eventData)
    }
    
    /// We are ready to process the event when the config shared state has an opt-in privacy status but our previous config has an opt-out
    func testSyncIdentifiersReturnTrueWhenLatestPrivacyIsOptOut() {
        // setup
        state.lastValidConfig = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "latestOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut] as [String : Any]
        
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
        state.lastValidConfig = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "latestOrg", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        
        // test
        let readyForSync = state.readyForSyncIdentifiers(event: Event.fakeSyncIDEvent(), configurationSharedState: [:])
        
        // verify
        XCTAssertTrue(readyForSync)
    }
    
    func testReadyForSyncIdentifiersShouldNotSyncWithEmptyCurrentConfigAndNilLatestConfig() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: ""] as [String : Any]
        
        // test
        let readyForSync = state.readyForSyncIdentifiers(event: Event.fakeSyncIDEvent(), configurationSharedState: configSharedState)
        
        // verify
        XCTAssertFalse(readyForSync)
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
