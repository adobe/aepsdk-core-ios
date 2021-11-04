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

import AEPServices
import Foundation

/// A type for managing Lifecycle sessions for standard, non-XDM scenarios.
struct LifecycleSession {
    let dataStore: NamedCollectionDataStore

    private var lifecycleHasRun = false

    /// Creates a new `LifecycleSession` with the given `NamedCollectionDataStore`
    /// - Parameter dataStore: The `NamedCollectionDataStore` in which Lifecycle session data will be cached
    init(dataStore: NamedCollectionDataStore) {
        self.dataStore = dataStore
    }

    /// Starts a new `LifecycleSession`
    /// Returns a `LifecycleSessionInfo` struct containing the previous session's data if it is a new session
    /// Returns nil if the previous session is resumed, or if lifecycle has already run
    /// - Parameters:
    ///   - date: Date at which the start event occurred
    ///   - sessionTimeout: session timeout in seconds
    ///   - coreMetrics: core metrics generated from the `LifecycleMetricsBuilder`
    ///   - Returns: `LifecycleSessionInfo` struct containing previous session's data, nil if the previous session is resumed, or if lifecycle has already run
    @discardableResult
    mutating func start(date: Date, sessionTimeout: TimeInterval, coreMetrics: LifecycleMetrics) -> LifecycleSessionInfo? {
        guard !lifecycleHasRun else { return nil }
        lifecycleHasRun = true

        var sessionContainer: LifecyclePersistedContext = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT) ?? LifecyclePersistedContext()
        let previousSessionStartDate = sessionContainer.startDate
        let previousSessionPauseDate = sessionContainer.pauseDate
        let previousSessionCrashed = !sessionContainer.successfulClose

        // if we have a pause date, check to see if pausedTime is less than the session timeout threshold
        if let unwrappedPreviousSessionDate = previousSessionPauseDate {
            let pausedTimeInSeconds = date.timeIntervalSince1970 - unwrappedPreviousSessionDate.timeIntervalSince1970

            if pausedTimeInSeconds < sessionTimeout, previousSessionStartDate != nil {
                // handle sessions that did not time out by removing paused time from session
                // do this by adding the paused time the session start time
                sessionContainer.startDate = previousSessionStartDate?.addingTimeInterval(pausedTimeInSeconds)

                // clear lifecycle flags
                sessionContainer.successfulClose = false
                sessionContainer.pauseDate = nil
                dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: sessionContainer)

                Log.trace(label: LifecycleConstants.LOG_TAG, "Lifecycle start was called but only \(pausedTimeInSeconds) seconds have passed since the previous launch. Lifecycle timeout threshold is \(sessionTimeout) seconds. A lifecycle event will not be dispatched.")
                return nil
            }
        }

        sessionContainer.startDate = date
        sessionContainer.pauseDate = nil
        sessionContainer.successfulClose = false
        sessionContainer.launches += 1
        sessionContainer.osVersion = coreMetrics.operatingSystem
        sessionContainer.appId = coreMetrics.appId

        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: sessionContainer)
        return LifecycleSessionInfo(startDate: previousSessionStartDate, pauseDate: previousSessionPauseDate, isCrash: previousSessionCrashed)
    }

    /// Pauses this `LifecycleSession`
    /// - Parameter pauseDate: Date at which the pause event occurred
    mutating func pause(pauseDate: Date) {
        var sessionContainer: LifecyclePersistedContext? = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT) ?? LifecyclePersistedContext()
        sessionContainer?.successfulClose = true
        sessionContainer?.pauseDate = pauseDate
        lifecycleHasRun = false

        dataStore.setObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT, value: sessionContainer)
    }

    /// Gets session length data (used for Analytics reporting)
    /// - Parameters:
    ///   - startDate: session start date
    ///   - sessionTimeout: session timeout in seconds
    ///   - previousSessionInfo: `LifecycleSessionInfo` struct containing previous session's data
    ///   - Returns: session length context data
    func getSessionData(startDate: Date, sessionTimeout: TimeInterval, previousSessionInfo: LifecycleSessionInfo) -> [String: String] {
        var sessionContextData = [String: String]()

        let timeSincePauseInSeconds = startDate.timeIntervalSince1970 - (previousSessionInfo.pauseDate?.timeIntervalSince1970 ?? 0.0)
        let lastSessionTimeSeconds = (previousSessionInfo.pauseDate?.timeIntervalSince1970 ?? 0.0) - (previousSessionInfo.startDate?.timeIntervalSince1970 ?? 0.0)

        // if we have not exceeded our timeout, bail
        if timeSincePauseInSeconds < sessionTimeout {
            return sessionContextData
        }

        // verify our session time is valid
        if lastSessionTimeSeconds > 0, lastSessionTimeSeconds < LifecycleConstants.MAX_SESSION_LENGTH_SECONDS {
            sessionContextData[LifecycleConstants.EventDataKeys.PREVIOUS_SESSION_LENGTH] = String(Int(lastSessionTimeSeconds))
        } else {
            // data is out of bounds, still record it in context data but put it in a different key
            sessionContextData[LifecycleConstants.EventDataKeys.IGNORED_SESSION_LENGTH] = String(Int(lastSessionTimeSeconds))
        }

        return sessionContextData
    }

    /// Gets the session start date from data store, if not present will return nil
    func getPersistedStartDate() -> Date? {
        let sessionContainer: LifecyclePersistedContext = dataStore.getObject(key: LifecycleConstants.DataStoreKeys.PERSISTED_CONTEXT) ?? LifecyclePersistedContext()
        return sessionContainer.startDate
    }
}

/// A container struct to easily serialize lifecycle session context information
struct LifecyclePersistedContext: Codable {
    /// Session's start timestamp
    var startDate: Date?

    /// Session's pause timestamp
    var pauseDate: Date?

    /// Set to true when LifecyclePause is called and set to false when LifecycleStart is called. Used to determine if an application crash occurred.
    var successfulClose: Bool = true

    /// Number of sessions started.
    var launches: Int = 0

    /// Last known OS version
    var osVersion: String?

    /// Last known application identifier
    var appId: String?

    init() {}
}

/// Container for Lifecycle session information
struct LifecycleSessionInfo {
    /// Timestamp of when the session started
    let startDate: Date?

    /// Timestamp of when the session was paused
    let pauseDate: Date?

    /// Flag indicating whether this session crashed or not
    let isCrash: Bool
}
