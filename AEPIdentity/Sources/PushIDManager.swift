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

import AEPCore
import AEPServices
import Foundation

/// A type which manages dispatching events based on Push ID changes
struct PushIDManager: PushIDManageable {
    private let LOG_TAG = "PushIDManager"

    private var pushEnabled: Bool {
        get {
            return dataStore.getBool(key: IdentityConstants.DataStoreKeys.PUSH_ENABLED) ?? false
        }

        set {
            dataStore.set(key: IdentityConstants.DataStoreKeys.PUSH_ENABLED, value: newValue)
        }
    }

    private var analyticsSynced: Bool {
        get {
            return dataStore.getBool(key: IdentityConstants.DataStoreKeys.ANALYTICS_PUSH_SYNC) ?? false
        }

        set {
            dataStore.set(key: IdentityConstants.DataStoreKeys.ANALYTICS_PUSH_SYNC, value: newValue)
        }
    }

    private var dataStore: NamedCollectionDataStore
    private var eventDispatcher: (Event) -> Void

    // MARK: PushIDManageable

    init(dataStore: NamedCollectionDataStore, eventDispatcher: @escaping (Event) -> Void) {
        self.dataStore = dataStore
        self.eventDispatcher = eventDispatcher
    }

    mutating func updatePushId(pushId: String?) {
        if !pushIdHasChanged(newPushId: pushId ?? "") {
            // Provided push token matches existing push token. Push settings will not be re-sent to Analytics
            Log.debug(label: "\(LOG_TAG):\(#function)", "Ignored push token \(pushId ?? "") as it matches the existing token, the push notification status will not be re-sent to Analytics.")
            return
        }

        // push ID has changed, update it in local storage
        var properties = IdentityProperties()
        properties.loadFromPersistence()
        properties.pushIdentifier = pushId
        properties.saveToPersistence()

        let isPushEnabled = pushEnabled
        if pushId?.isEmpty ?? true, !isPushEnabled {
            updatePushStatusAndSendAnalyticsEvent(enabled: false)
            Log.trace(label: "\(LOG_TAG):\(#function)", "First time sending a.push.optin False")
        } else if pushId?.isEmpty ?? true, isPushEnabled {
            updatePushStatusAndSendAnalyticsEvent(enabled: false)
        } else if let pushId = pushId, !pushId.isEmpty, !isPushEnabled {
            updatePushStatusAndSendAnalyticsEvent(enabled: true)
        }
    }

    mutating func resetPersistedFlags() {
        pushEnabled = false
        analyticsSynced = false
    }

    // MARK: Private APIs

    /// Compares the provided newPushId against the one in data store (if exists)
    /// - Parameter newPushId: the new push identifier as a string
    /// - Returns: true if the provided push id does not match the existing one
    private mutating func pushIdHasChanged(newPushId: String) -> Bool {
        var properties = IdentityProperties()
        properties.loadFromPersistence()

        let existingPushId = properties.pushIdentifier ?? ""
        let pushIdsMatch = existingPushId == newPushId

        // process the update only if the value changed or if this is not the first time setting the push token to null
        if (pushIdsMatch && !newPushId.isEmpty) || (pushIdsMatch && analyticsSynced) {
            return false
        }

        analyticsSynced = true // set analytics sync flag to true
        return true
    }

    // TODO: Investigate if this can be moved to the analytics code base
    /// Updates the push enabled flag in the data store and dispatches an analytics request content event with the push enabled flag
    /// - Parameter enabled: a boolean flag indicating if push is enabled or disabled
    private mutating func updatePushStatusAndSendAnalyticsEvent(enabled: Bool) {
        pushEnabled = enabled
        let pushStatusStr = enabled ? "True" : "False"
        let contextData = [IdentityConstants.Analytics.EVENT_PUSH_STATUS: pushStatusStr]
        let eventData = [IdentityConstants.Analytics.TRACK_ACTION: IdentityConstants.Analytics.PUSH_ID_ENABLED_ACTION_NAME,
                         IdentityConstants.Analytics.CONTEXT_DATA: contextData,
                         IdentityConstants.Analytics.TRACK_INTERNAL: true] as [String: Any]

        let event = Event(name: IdentityConstants.EventNames.ANALYTICS_FOR_IDENTITY_REQUEST,
                          type: EventType.analytics,
                          source: EventSource.requestContent,
                          data: eventData)
        eventDispatcher(event)
    }
}
