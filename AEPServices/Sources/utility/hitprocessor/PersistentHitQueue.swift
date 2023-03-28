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

import Foundation

/// Provides functionality for asynchronous processing of hits in a synchronous manner while providing the ability to retry hits
public class PersistentHitQueue: HitQueuing {
    public let processor: HitProcessing
    let dataQueue: DataQueue

    private var suspended = true
    private var isTaskScheduled = false
    private let queue = DispatchQueue(label: "com.adobe.mobile.persistenthitqueue")

    /// Creates a new `HitQueue` with the underlying `DataQueue` which is used to persist hits
    /// - Parameter dataQueue: a `DataQueue` used to persist hits
    /// - Parameter processor: a `HitProcessing` used to process hits
    public init(dataQueue: DataQueue, processor: HitProcessing) {
        self.dataQueue = dataQueue
        self.processor = processor
    }

    @discardableResult
    public func queue(entity: DataEntity) -> Bool {
        let result = dataQueue.add(dataEntity: entity)
        processNextHit()
        return result
    }

    public func beginProcessing() {
        queue.async { self.suspended = false }
        processNextHit()
    }

    public func suspend() {
        queue.async { self.suspended = true }
    }

    public func clear() {
        _ = dataQueue.clear()
    }

    public func count() -> Int {
        return dataQueue.count()
    }

    public func close() {
        suspend()
        dataQueue.close()
    }

    /// A recursive function for processing hits, it will continue processing all the hits until none are left in the data queue
    private func processNextHit() {
        queue.async {
            guard !self.suspended, !self.isTaskScheduled else { return }

            self.isTaskScheduled = true

            guard let hit = self.dataQueue.peek() else {
                self.isTaskScheduled = false
                return
            } // nothing left in the queue, stop processing

            let semaphore = DispatchSemaphore(value: 0)
            self.processor.processHit(entity: hit, completion: { [weak self] success in

                guard let self = self else {
                    semaphore.signal()
                    return
                }

                if success {
                    // successful processing of hit
                    // attempt to remove it from the queue and process next hit if successful
                    if self.dataQueue.remove() {
                        self.isTaskScheduled = false
                        self.processNextHit()
                    } else {
                        // deleting the hit from the database failed
                        // need to delete the database to try and recover
                        Log.warning(label: "PersistentHitQueue", "An unexpected error occurred while attempting to delete a record from the database. Data processing will be paused.")
                    }
                } else {
                    // processing hit failed, leave it in the queue, retry after the retry interval
                    self.queue.asyncAfter(deadline: .now() + self.processor.retryInterval(for: hit)) { [weak self] in
                        guard let self = self else { return }
                        self.isTaskScheduled = false
                        self.processNextHit()
                    }
                }

                semaphore.signal()
            })
            semaphore.wait()
        }
    }
}
