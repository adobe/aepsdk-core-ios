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

    var state = IdentityState()
    
    override func setUp() {
        state = IdentityState()
    }

    func testSyncIdentifiersHappyIDs() {
        // setup
        let configSharedState = [ConfigurationConstants.Keys.EXPERIENCE_CLOUD_ORGID: "test-org", ConfigurationConstants.Keys.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn] as [String : Any]
        let event = Event.fakeSyncIDEvent()
        
        // test
        let eventData = state.syncIdentifiers(event: event, configurationSharedState: configSharedState)
        
        // verify
        XCTAssertEqual(2, eventData.count)
        XCTAssertNotNil(eventData[IdentityConstants.EventDataKeys.VISITOR_ID_MID])
        let idList = eventData[IdentityConstants.EventDataKeys.VISITOR_IDS_LIST] as? [CustomIdentity]
        XCTAssertEqual(2, idList?.count)
        // TODO: Verify hit was inserted into DB
    }

}

private extension Event {
    static func fakeSyncIDEvent() -> Event {
        let ids = ["k1": "v1", "k2": "v2"]
        let data = [IdentityConstants.EventDataKeys.IDENTIFIERS: ids, IdentityConstants.EventDataKeys.IS_SYNC_EVENT: true] as [String : Any]
        return Event(name: "Fake Sync Event", type: .identity, source: .requestReset, data: data)
    }
}
