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

    private static let DEFAULT_RETRY_INTERVAL = TimeInterval(30)
    private var suspended = true // indicates if the queue has been suspended
    private var isWaiting = false // indicates if the queue is currently waiting for network respsonse or next retry
    private var hitsToRemove = 0 // number of hits need to be removed
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
            if self.hitsToRemove > 0 {
                self.dataQueue.remove(n: self.hitsToRemove)
                self.hitsToRemove = 0
            }

            guard !self.suspended else { return }
            guard !self.isWaiting else { return }
            guard let hit = self.dataQueue.peek() else { return } // nothing left in the queue, stop processing

            self.isWaiting = true

            self.processor.processHit(entity: hit, completion: { [weak self] success in
                if success {
                    // successful processing of hit, unblock the current queue, increment hitsToRemove
                    self?.queue.async {
                        self?.hitsToRemove += 1
                        self?.isWaiting = false
                    }
                    self?.processNextHit()
                } else {
                    // processing hit failed, leave it in the queue, retry after the retry interval
                    self?.queue.asyncAfter(deadline: .now() + (self?.processor.retryInterval ?? PersistentHitQueue.DEFAULT_RETRY_INTERVAL)) {                        
                        self?.isWaiting = false
                        self?.processNextHit()
                    }
                }
            })
        }
    }
}
