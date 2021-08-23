/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import AEPServices

/// LifecycleV2StateManager manages app session state updates for the XDM scenario based on the start/pause Lifecycle events.
class LifecycleV2StateManager {

    private static var SELF_LOG_TAG = "LifecycleV2StateManager"

    enum State: String {
        case START = "start"
        case PAUSE = "pause"
    }

    private let dispatchQueue = DispatchQueue(label: "\(LifecycleConstants.EXTENSION_NAME).stateManager")
    private var scheduledPauseTask: DispatchWorkItem?
    private var cancellablePauseCallback: ((Bool) -> Void)?
    private var currentState: State?

    init() {
        self.scheduledPauseTask = nil
        self.cancellablePauseCallback = nil
        self.currentState = nil
    }

    /// Updates current state if needed and returns the status of the update operation through provided callback.
    /// Expected scenarios:
    /// If this is a `start` update then
    ///     a) If pause task is currently scheduled, it cancels the pause task and updates current state to `start`
    ///     b) If pause task is currently not scheduled, it updates the current state to `start` if previous state was different
    /// If this is a `pause` update then
    ///     a) If pause task is currently scheduled, it cancels and reschedules the pause task after `LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC` sec, so the last pause update takes into effect
    ///     b) If pause task is currently not scheduled, it updates the current state to `pause` if previous state was different
    ///     
    /// - Parameters:
    ///     - state the new state that needs to be updated
    ///     - callback completion callback to be invoked with the status of the update once the operation is complete
    func update(state: State, callback: @escaping (Bool) -> Void) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            if self.scheduledPauseTask != nil {
                switch state {
                case .START:
                    Log.trace(label: LifecycleConstants.LOG_TAG, "\(Self.SELF_LOG_TAG) - Received pause->start state update within \(LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC) sec, ignoring.")
                    self.cancelPauseTask()
                    callback(false)
                case .PAUSE:
                    Log.trace(label: LifecycleConstants.LOG_TAG, "\(Self.SELF_LOG_TAG) - Received pause->pause state update within \(LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC) sec, rescheduling.")
                    self.cancelPauseTask()
                    self.schedulePauseTask(callback: callback)
                }

                return
            }

            if self.currentState == state {
                Log.trace(label: LifecycleConstants.LOG_TAG, "\(Self.SELF_LOG_TAG) - Received consecutive \(state) state update, ignoring.")
                callback(false)
                return
            }

            switch state {
            case .START:
                Log.trace(label: LifecycleConstants.LOG_TAG, "\(Self.SELF_LOG_TAG) - Received new start state, updating.")
                self.currentState = state
                callback(true)
            case .PAUSE:
                Log.trace(label: LifecycleConstants.LOG_TAG, "\(Self.SELF_LOG_TAG) - Received new pause state, waiting for \(LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC) sec before updating.")
                self.schedulePauseTask(callback: callback)
            }
        }
    }

    /// Schedules a task which updates current state to pause after `LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC` sec
    ///
    /// - Parameters:
    ///     - callback completion callback to be invoked with the status of the update once the operation is complete
    private func schedulePauseTask(callback: @escaping (Bool) -> Void) {
        let task = DispatchWorkItem { [weak self] in
            self?.currentState = State.PAUSE
            self?.scheduledPauseTask = nil
            self?.cancellablePauseCallback = nil
            callback(true)
        }

        cancellablePauseCallback = callback
        scheduledPauseTask = task
        dispatchQueue.asyncAfter(deadline: .now() + LifecycleV2Constants.STATE_UPDATE_TIMEOUT_SEC, execute: task)
    }

    /// Cancels any scheduled pause task
    private func cancelPauseTask() {
        scheduledPauseTask?.cancel()
        scheduledPauseTask = nil

        cancellablePauseCallback?(false)
    }

}
